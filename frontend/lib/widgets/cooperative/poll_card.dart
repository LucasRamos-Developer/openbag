import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/cooperative/community.dart';
import '../../utils/formatters.dart';

/// Enquete com as opções: para votar ([onVote]) ou com o resultado em barras (depois do voto ou no encerramento).
/// O voto é secreto: só as contagens aparecem.
class PollCard extends StatefulWidget {
  final Poll poll;

  /// Voto do cooperado; nulo = só leitura (painel do gestor)
  final Future<void> Function(int optionId)? onVote;

  /// Ações do gestor (abrir, encerrar, editar), abaixo do resultado
  final List<Widget> actions;

  const PollCard({super.key, required this.poll, this.onVote, this.actions = const []});

  @override
  State<PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  int? _selected;
  bool _voting = false;

  Future<void> _vote() async {
    if (_selected == null || widget.onVote == null) return;
    setState(() => _voting = true);
    try {
      await widget.onVote!(_selected!);
    } finally {
      if (mounted) setState(() => _voting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final poll = widget.poll;
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final voting = widget.onVote != null && poll.canVote;

    return AppCard(
      padding: const EdgeInsets.all(16),
      borderColor: colors.border,
      borderWidth: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppStatusChip(
                label: poll.status.label,
                color: switch (poll.status) {
                  PollStatus.OPEN => AppColors.successDark,
                  PollStatus.CLOSED => AppColors.grey600,
                  PollStatus.DRAFT => AppColors.warningDarker,
                },
              ),
              if (_deadline(poll) != null)
                Text(_deadline(poll)!, style: TextStyle(color: colors.textMuted, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 10),
          Text(poll.question, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          if (poll.description != null) ...[
            const SizedBox(height: 4),
            Text(poll.description!, style: TextStyle(color: colors.textMuted)),
          ],
          const SizedBox(height: 12),
          if (voting) ...[
            for (final option in poll.options) ...[
              AppChoiceTile(
                title: option.label,
                selected: _selected == option.id,
                enabled: !_voting,
                onTap: () => setState(() => _selected = option.id),
              ),
              const SizedBox(height: 8),
            ],
            AppButton(
              text: 'Votar',
              icon: Icons.how_to_vote_outlined,
              fullWidth: true,
              isLoading: _voting,
              onPressed: _selected == null ? null : _vote,
            ),
            const SizedBox(height: 6),
            Text('O voto é secreto e não pode ser trocado depois.',
                textAlign: TextAlign.center, style: TextStyle(color: colors.textMuted, fontSize: 12)),
          ] else if (poll.showResults) ...[
            for (final option in poll.options)
              _ResultBar(option: option, total: poll.totalVotes, mine: option.id == poll.myOptionId),
            const SizedBox(height: 4),
            Text(
              '${poll.totalVotes} de ${poll.eligibleVoters} ${poll.eligibleVoters == 1 ? 'cooperado votou' : 'cooperados votaram'}',
              style: TextStyle(color: colors.textMuted, fontSize: 13),
            ),
          ] else
            Text('O resultado aparece quando a enquete encerrar.', style: TextStyle(color: colors.textMuted)),
          if (widget.actions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: widget.actions),
          ],
        ],
      ),
    );
  }

  static String? _deadline(Poll poll) => switch (poll.status) {
        PollStatus.OPEN when poll.closesAt != null => 'Encerra em ${formatDateTime(poll.closesAt)}',
        PollStatus.CLOSED when poll.closedAt != null => 'Encerrada em ${formatDate(poll.closedAt)}',
        PollStatus.CLOSED when poll.closesAt != null => 'Encerrada em ${formatDate(poll.closesAt)}',
        _ => null,
      };
}

/// Uma opção no resultado: barra de uma cor só (não é comparação de categorias), número e percentual por escrito
class _ResultBar extends StatelessWidget {
  final PollOption option;
  final int total;
  final bool mine;

  const _ResultBar({required this.option, required this.total, required this.mine});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final votes = option.votes ?? 0;
    final share = total == 0 ? 0.0 : votes / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (mine) ...[
                Icon(Icons.check_circle, size: 16, color: colors.primaryText),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(mine ? '${option.label} (seu voto)' : option.label,
                    style: TextStyle(fontWeight: mine ? FontWeight.w700 : FontWeight.w500)),
              ),
              Text('$votes · ${formatPercent((share * 100).roundToDouble())}',
                  style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()])),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 8,
              backgroundColor: colors.surfaceAlt,
              color: colors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
