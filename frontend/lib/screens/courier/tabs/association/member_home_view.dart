import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/ui/ui.dart';
import '../../../../models/cooperative/announcement.dart';
import '../../../../models/cooperative/billing.dart';
import '../../../../models/cooperative/community.dart';
import '../../../../models/cooperative/ledger.dart';
import '../../../../models/courier/courier_profile.dart';
import '../../../../services/member_area_service.dart';
import '../../../../utils/feedback.dart';
import '../../../../utils/formatters.dart';
import '../../../../widgets/common/money_field.dart';
import '../../../../widgets/cooperative/fund_card.dart';
import '../../../../widgets/courier/membership_card.dart';
import '../../courier_section.dart';

typedef _HomeData = ({
  MyInvoices invoices,
  List<MemberAddon> addons,
  SolidarityFund fund,
  List<Poll> polls,
  List<Announcement> announcements,
});

/// Resumo do cooperado, pensado para o celular: o que pede ação primeiro (comunicado não lido, adicional proposto,
/// fatura em aberto, enquete para votar), depois a fatura do mês e a caixinha
class MemberHomeView extends StatefulWidget {
  final CourierProfile profile;

  const MemberHomeView({super.key, required this.profile});

  @override
  State<MemberHomeView> createState() => _MemberHomeViewState();
}

class _MemberHomeViewState extends State<MemberHomeView> {
  int _version = 0;

  MemberAreaService get _service => context.read<MemberAreaService>();

  Future<_HomeData> _load() async {
    final results = await Future.wait([
      _service.fetchInvoices(),
      _service.fetchAddons(),
      _service.fetchFund(),
      _service.fetchPolls(),
      _service.fetchAnnouncements(),
    ]);
    return (
      invoices: results[0] as MyInvoices,
      addons: results[1] as List<MemberAddon>,
      fund: results[2] as SolidarityFund,
      polls: results[3] as List<Poll>,
      announcements: results[4] as List<Announcement>,
    );
  }

  Future<void> _answer(MemberAddon addon, bool accept) async {
    if (!accept) {
      final confirmed = await AppDialog.confirm(context,
          title: 'Recusar ${addon.name}?', message: 'Você pode pedir de novo à associação depois.', confirmLabel: 'Recusar');
      if (!confirmed || !mounted) return;
    }
    final ok = await runWithFeedback(context, () => _service.answerAddon(addon.id, accept ? 'accept' : 'decline'),
        success: accept ? '${addon.name} ativado: entra na próxima fatura' : 'Proposta recusada');
    if (ok) setState(() => _version++);
  }

  Future<void> _editContribution(double current) async {
    final saved = await showAppAdaptive<bool>(context, builder: (_) => _ContributionForm(current: current));
    if (saved == true) setState(() => _version++);
  }

  @override
  Widget build(BuildContext context) {
    return AppLoadView<_HomeData>(
      key: ValueKey(_version),
      load: _load,
      builder: (context, data, reload) {
        final proposed = data.addons.where((a) => a.status == MemberAddonStatus.PROPOSED).toList();
        final open = data.invoices.open;
        final toVote = data.polls.where((p) => p.canVote).toList();
        final current = data.invoices.current;
        final unread = data.announcements.where((a) => !a.read).toList();

        return AppPageListView(
          top: 8,
          maxWidth: 820,
          children: [
            for (final a in unread.take(2)) ...[
              _ActionCard(
                icon: a.type.icon,
                title: a.eventAt != null
                    ? '${a.type.label} · ${formatDate(a.eventAt)} às ${formatTime(a.eventAt)}'
                    : a.type.label,
                text: a.title,
                action: 'Ler',
                onTap: () => context.go(MemberAreaTab.announcements.path),
              ),
              const SizedBox(height: 12),
            ],
            if (unread.length > 2) ...[
              _ActionCard(
                icon: Icons.campaign_outlined,
                title: 'Mais ${unread.length - 2} ${unread.length - 2 == 1 ? 'comunicado' : 'comunicados'} sem ler',
                text: 'Veja todos no mural da associação.',
                action: 'Ver comunicados',
                onTap: () => context.go(MemberAreaTab.announcements.path),
              ),
              const SizedBox(height: 12),
            ],
            for (final addon in proposed) ...[
              _AddonProposal(addon: addon, onAnswer: (accept) => _answer(addon, accept)),
              const SizedBox(height: 12),
            ],
            if (open.isNotEmpty) ...[
              _ActionCard(
                icon: Icons.error_outline,
                title: open.length == 1
                    ? 'Fatura de ${formatMonth(open.first.month)} em aberto'
                    : '${open.length} faturas em aberto',
                text: 'Total ${formatMoney(open.fold<double>(0, (s, i) => s + i.total))}. '
                    'Pague à associação por Pix ou em dinheiro; o gestor dá a baixa.',
                action: 'Ver faturas',
                onTap: () => context.go(MemberAreaTab.invoices.path),
              ),
              const SizedBox(height: 12),
            ],
            for (final poll in toVote.take(2)) ...[
              _ActionCard(
                icon: Icons.how_to_vote_outlined,
                title: 'Enquete aberta',
                text: poll.question,
                action: 'Votar',
                onTap: () => context.go(MemberAreaTab.polls.path),
              ),
              const SizedBox(height: 12),
            ],
            if (current != null) ...[
              AppPanelCard(
                // Só o nome do mês: o ano já está claro e o título cabe numa linha no celular
                title: 'Mensalidade de ${formatMonth(current.month).split(' de ').first}',
                subtitle: data.invoices.policy.summary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(formatMoney(current.total),
                        style: TextStyle(
                            color: context.appColors.text,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()])),
                    const SizedBox(height: 4),
                    Text(
                      'Até agora, com ${formatMoney(current.earnings)} de ganhos. '
                      'O valor fecha no fim do mês.',
                      style: TextStyle(color: context.appColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            FundHeroCard(
              balance: data.fund.balance,
              totalIn: data.fund.totalIn,
              totalOut: data.fund.totalOut,
              caption: data.fund.aids > 0
                  ? '${data.fund.aids} ${data.fund.aids == 1 ? 'cooperado já foi ajudado' : 'cooperados já foram ajudados'}. '
                      'Você contribuiu com ${formatMoney(data.fund.myContribution)}.'
                  : 'Você contribuiu com ${formatMoney(data.fund.myContribution)}.',
            ),
            const SizedBox(height: 12),
            AppListTileCard(
              onTap: () => _editContribution(data.invoices.solidarityContribution),
              leading: const CircleAvatar(child: Icon(Icons.volunteer_activism_outlined)),
              title: 'Minha contribuição mensal',
              subtitle: data.invoices.solidarityContribution > 0
                  ? '${formatMoney(data.invoices.solidarityContribution)} por mês, na fatura'
                  : 'Você ainda não contribui. Toque para escolher um valor.',
            ),
            const SizedBox(height: 24),
            CourierMembershipCard(profile: widget.profile),
          ],
        );
      },
    );
  }
}

/// Adicional proposto pela associação (ex: seguro de vida): aceitar ou recusar, com botões grandes
class _AddonProposal extends StatelessWidget {
  final MemberAddon addon;
  final ValueChanged<bool> onAnswer;

  const _AddonProposal({required this.addon, required this.onAnswer});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppCard(
      padding: const EdgeInsets.all(16),
      borderColor: colors.primary.withValues(alpha: 0.4),
      borderWidth: 1.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: colors.primaryText),
              const SizedBox(width: 8),
              Expanded(
                child: Text('A associação propôs: ${addon.name}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(addon.priceLabel, style: TextStyle(color: colors.primaryText, fontWeight: FontWeight.w700)),
          if (addon.description != null) ...[
            const SizedBox(height: 4),
            Text(addon.description!, style: TextStyle(color: colors.textMuted)),
          ],
          const SizedBox(height: 12),
          AppResponsiveRow(
            breakpoint: 360,
            spacing: 12,
            children: [
              AppButton(text: 'Recusar', variant: ButtonVariant.outlined, fullWidth: true, onPressed: () => onAnswer(false)),
              AppButton(text: 'Aceitar', icon: Icons.check, fullWidth: true, onPressed: () => onAnswer(true)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Algo que pede ação do cooperado, com um botão
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final String action;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.title, required this.text, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      backgroundColor: colors.surfaceAlt,
      child: Row(
        children: [
          Icon(icon, color: colors.text),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(text, style: TextStyle(color: colors.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(action, style: TextStyle(color: colors.primaryText, fontWeight: FontWeight.w700)),
          Icon(Icons.chevron_right, color: colors.primaryText),
        ],
      ),
    );
  }
}

/// Quanto dar por mês à caixinha (entra na fatura; zero = nada)
class _ContributionForm extends StatefulWidget {
  final double current;

  const _ContributionForm({required this.current});

  @override
  State<_ContributionForm> createState() => _ContributionFormState();
}

class _ContributionFormState extends State<_ContributionForm> {
  late final _amount = TextEditingController(text: widget.current > 0 ? moneyInput(widget.current) : '');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Os atalhos acendem conforme o valor digitado
    _amount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save(double amount) async {
    setState(() => _saving = true);
    final ok = await runWithFeedback(context, () => context.read<MemberAreaService>().setContribution(amount),
        success: amount > 0 ? 'Contribuição de ${formatMoney(amount)} por mês' : 'Contribuição cancelada');
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AppAdaptiveSheet(
      title: 'Contribuição para a caixinha',
      maxWidth: 480,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('O valor entra na sua fatura todo mês e fica na caixinha para ajudar um colega que passar por '
              'um problema (acidente, moto quebrada, doença).'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in [5.0, 10.0, 20.0, 50.0])
                ChoiceChip(
                  label: Text(formatMoney(value)),
                  selected: parseMoney(_amount.text) == value,
                  onSelected: (_) => setState(() => _amount.text = moneyInput(value)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          MoneyField(controller: _amount, label: 'Outro valor'),
          if (widget.current > 0) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: _saving ? null : () => _save(0), child: const Text('Parar de contribuir')),
            ),
          ],
        ],
      ),
      actions: [
        AppButton(text: 'Cancelar', variant: ButtonVariant.outlined, onPressed: () => Navigator.of(context).pop(false)),
        AppButton(
          text: 'Salvar',
          icon: Icons.check,
          isLoading: _saving,
          onPressed: _saving ? null : () => _save(parseMoney(_amount.text) ?? 0),
        ),
      ],
    );
  }
}
