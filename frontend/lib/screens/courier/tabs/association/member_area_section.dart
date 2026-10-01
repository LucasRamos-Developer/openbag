import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/ui/ui.dart';
import '../../../../models/association/member.dart';
import '../../../../services/courier_service.dart';
import '../../../../widgets/courier/membership_card.dart';
import '../../../../widgets/navigation/panel_sub_tabs.dart';
import '../../courier_section.dart';
import 'member_announcements_view.dart';
import 'member_benefits_view.dart';
import 'member_documents_view.dart';
import 'member_home_view.dart';
import 'member_invoices_view.dart';
import 'member_polls_view.dart';

/// Área do cooperado: tudo o que a associação deixa disponível (fatura, adicionais, caixinha, convênios,
/// enquetes e atas). Sem vínculo aprovado, mostra só o cartão para entrar numa associação.
class MemberAreaSection extends StatelessWidget {
  final MemberAreaTab tab;

  const MemberAreaSection({super.key, this.tab = MemberAreaTab.home});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<CourierService>().profile;
    if (profile == null) return const Center(child: CircularProgressIndicator());

    final association = profile.association;
    final member = association != null &&
        (association.status == MembershipStatus.ACTIVE || association.status == MembershipStatus.SUSPENDED);
    if (!member) {
      return AppPageListView(
        maxWidth: 720,
        children: [CourierMembershipCard(profile: profile)],
      );
    }

    return PanelSubTabs<MemberAreaTab>(
      title: association.name,
      titleOnCompact: true,
      subtitle: 'Sua fatura, a caixinha, os comunicados, os convênios, as enquetes e as atas da associação',
      tabs: [for (final t in MemberAreaTab.values) SelectItem(value: t, label: t.label, icon: t.icon)],
      value: tab,
      onSelected: (t) => context.go(t.path),
      child: switch (tab) {
        MemberAreaTab.home => MemberHomeView(profile: profile),
        MemberAreaTab.announcements => const MemberAnnouncementsView(),
        MemberAreaTab.invoices => const MemberInvoicesView(),
        MemberAreaTab.benefits => const MemberBenefitsView(),
        MemberAreaTab.polls => const MemberPollsView(),
        MemberAreaTab.documents => const MemberDocumentsView(),
      },
    );
  }
}
