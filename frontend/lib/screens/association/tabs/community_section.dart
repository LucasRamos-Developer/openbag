import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ui/ui.dart';
import '../../../widgets/navigation/panel_sub_tabs.dart';
import '../association_section.dart';
import 'community/documents_view.dart';
import 'community/polls_view.dart';

/// Assembleia: enquetes e atas/documentos, tudo disponível para os cooperados no painel deles
class CommunitySectionView extends StatelessWidget {
  final CommunityTab tab;

  const CommunitySectionView({super.key, this.tab = CommunityTab.polls});

  @override
  Widget build(BuildContext context) {
    return PanelSubTabs<CommunityTab>(
      title: 'Assembleia',
      subtitle: 'Enquetes, atas das reuniões e documentos, disponíveis para os cooperados',
      tabs: [for (final t in CommunityTab.values) SelectItem(value: t, label: t.label, icon: t.icon)],
      value: tab,
      onSelected: (t) => context.go(t.path),
      child: switch (tab) {
        CommunityTab.polls => const PollsView(),
        CommunityTab.documents => const DocumentsView(),
      },
    );
  }
}
