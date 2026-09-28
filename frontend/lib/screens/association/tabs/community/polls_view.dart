import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/ui/ui.dart';
import '../../../../models/cooperative/community.dart';
import '../../../../services/association_service.dart';
import '../../../../services/cooperative_service.dart';
import '../../../../utils/feedback.dart';
import '../../../../widgets/cooperative/poll_card.dart';

/// Enquetes: rascunho → abrir votação → encerrar. O gestor sempre vê o resultado; o voto é secreto.
class PollsView extends StatefulWidget {
  const PollsView({super.key});

  @override
  State<PollsView> createState() => _PollsViewState();
}

class _PollsViewState extends State<PollsView> {
  int _version = 0;

  int get _orgId => context.read<AssociationService>().association!.id;
  CooperativeService get _service => context.read<CooperativeService>();

  void _reload() => setState(() => _version++);

  Future<void> _edit([Poll? poll]) async {
    final saved = await showAppAdaptive<bool>(context, builder: (_) => _PollForm(poll: poll));
    if (saved == true) _reload();
  }

  Future<void> _action(Poll poll, String action) async {
    final (title, message, label) = switch (action) {
      'open' => ('Abrir a votação?', 'Os cooperados ativos passam a ver e votar. Depois de aberta, a enquete não muda mais.', 'Abrir votação'),
      'close' => ('Encerrar a votação?', 'Ninguém mais vota e o resultado fica visível para todos.', 'Encerrar'),
      _ => ('Apagar o rascunho?', poll.question, 'Apagar'),
    };
    final confirmed = await AppDialog.confirm(context, title: title, message: message, confirmLabel: label);
    if (!confirmed || !mounted) return;
    final ok = await runWithFeedback(
      context,
      () => action == 'delete' ? _service.deletePoll(_orgId, poll.id) : _service.pollAction(_orgId, poll.id, action),
      success: switch (action) { 'open' => 'Votação aberta', 'close' => 'Enquete encerrada', _ => 'Rascunho apagado' },
    );
    if (ok) _reload();
  }

  List<Widget> _actions(Poll poll) => switch (poll.status) {
        PollStatus.DRAFT => [
            AppButton(text: 'Apagar', variant: ButtonVariant.text, onPressed: () => _action(poll, 'delete')),
            AppButton(text: 'Editar', variant: ButtonVariant.outlined, onPressed: () => _edit(poll)),
            AppButton(text: 'Abrir votação', icon: Icons.play_arrow, onPressed: () => _action(poll, 'open')),
          ],
        PollStatus.OPEN => [
            AppButton(text: 'Encerrar', icon: Icons.stop_circle_outlined, variant: ButtonVariant.outlined,
                onPressed: () => _action(poll, 'close')),
          ],
        PollStatus.CLOSED => const [],
      };

  @override
  Widget build(BuildContext context) {
    final compact = AppLayout.isCompact(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: compact
          ? FloatingActionButton.extended(onPressed: _edit, icon: const Icon(Icons.add), label: const Text('Nova enquete'))
          : null,
      body: AppLoadView<List<Poll>>(
        key: ValueKey(_version),
        load: () => _service.fetchPolls(_orgId),
        builder: (context, polls, reload) => AppPageListView(
          top: 8,
          bottom: compact ? 96 : 32,
          maxWidth: 820,
          children: [
            if (!compact)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AppButton(text: 'Nova enquete', icon: Icons.add, onPressed: _edit),
                ),
              ),
            if (polls.isEmpty)
              AppEmptyState(
                icon: Icons.poll_outlined,
                message: 'Nenhuma enquete ainda. Pergunte aos cooperados sobre datas, compras e decisões da associação.',
                actionLabel: 'Criar enquete',
                onAction: _edit,
              ),
            for (final poll in polls) ...[
              PollCard(poll: poll, actions: _actions(poll)),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

/// Rascunho de enquete: pergunta, explicação, de 2 a 10 opções e o encerramento automático (opcional)
class _PollForm extends StatefulWidget {
  final Poll? poll;

  const _PollForm({this.poll});

  @override
  State<_PollForm> createState() => _PollFormState();
}

class _PollFormState extends State<_PollForm> {
  final _formKey = GlobalKey<FormState>();
  late final _question = TextEditingController(text: widget.poll?.question);
  late final _description = TextEditingController(text: widget.poll?.description);
  late final List<TextEditingController> _options = [
    for (final o in widget.poll?.options ?? const <PollOption>[]) TextEditingController(text: o.label),
  ];
  late DateTime? _closesOn = widget.poll?.closesAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    while (_options.length < 2) {
      _options.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _question.dispose();
    _description.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final closesOn = _closesOn;
    final ok = await runWithFeedback(
      context,
      () => context.read<CooperativeService>().savePoll(
            context.read<AssociationService>().association!.id,
            question: _question.text.trim(),
            description: _description.text.trim().isEmpty ? null : _description.text.trim(),
            options: [for (final c in _options) c.text.trim()].where((o) => o.isNotEmpty).toList(),
            // Encerra no fim do dia escolhido
            closesAt: closesOn != null ? DateTime(closesOn.year, closesOn.month, closesOn.day, 23, 59) : null,
            pollId: widget.poll?.id,
          ),
      success: 'Rascunho salvo. Abra a votação quando estiver pronto.',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveSheet(
      title: widget.poll == null ? 'Nova enquete' : 'Editar enquete',
      maxWidth: 620,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _question,
              labelText: 'Pergunta',
              hintText: 'Ex: Qual o melhor dia para a assembleia?',
              variant: TextFieldVariant.filled,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => (v ?? '').trim().isEmpty ? 'Escreva a pergunta' : null,
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _description,
              labelText: 'Explicação (opcional)',
              variant: TextFieldVariant.filled,
              maxLines: 3,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 8),
            const Text('Opções', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (var i = 0; i < _options.length; i++) ...[
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _options[i],
                      labelText: 'Opção ${i + 1}',
                      variant: TextFieldVariant.filled,
                      maxLength: 150,
                      validator: (v) => i < 2 && (v ?? '').trim().isEmpty ? 'Preencha pelo menos 2 opções' : null,
                    ),
                  ),
                  if (_options.length > 2)
                    IconButton(
                      tooltip: 'Tirar opção',
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => setState(() => _options.removeAt(i).dispose()),
                    ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            if (_options.length < 10)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() => _options.add(TextEditingController())),
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar opção'),
                ),
              ),
            const SizedBox(height: 12),
            AppDateField(
              label: 'Encerrar em (opcional)',
              value: _closesOn,
              hint: 'Até eu encerrar',
              clearable: true,
              firstDate: DateTime.now(),
              onChanged: (d) => setState(() => _closesOn = d),
            ),
          ],
        ),
      ),
      actions: [
        AppButton(text: 'Cancelar', variant: ButtonVariant.outlined, onPressed: () => Navigator.of(context).pop(false)),
        AppButton(text: 'Salvar rascunho', icon: Icons.check, isLoading: _saving, onPressed: _saving ? null : _save),
      ],
    );
  }
}
