import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/ui/ui.dart';
import '../../../../models/cooperative/community.dart';
import '../../../../services/member_area_service.dart';
import '../../../../widgets/cooperative/benefit_card.dart';

/// Convênios disponíveis para o cooperado, com filtro por categoria
class MemberBenefitsView extends StatefulWidget {
  const MemberBenefitsView({super.key});

  @override
  State<MemberBenefitsView> createState() => _MemberBenefitsViewState();
}

class _MemberBenefitsViewState extends State<MemberBenefitsView> {
  BenefitCategory? _category;

  @override
  Widget build(BuildContext context) {
    return AppLoadView<List<Benefit>>(
      load: () => context.read<MemberAreaService>().fetchBenefits(),
      builder: (context, benefits, reload) {
        final categories = {for (final b in benefits) b.category}.toList()..sort((a, b) => a.index - b.index);
        final shown = benefits.where((b) => _category == null || b.category == _category).toList();
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            if (categories.length > 1)
              LayoutBuilder(
                builder: (context, constraints) {
                  final padding = AppLayout.contentPadding(constraints.maxWidth, top: 0, bottom: 0);
                  return AppFilterChips<BenefitCategory?>(
                    items: [
                      const SelectItem(value: null, label: 'Todos'),
                      for (final c in categories) SelectItem(value: c, label: c.label, icon: c.icon),
                    ],
                    value: _category,
                    onSelected: (c) => setState(() => _category = c),
                    padding: EdgeInsets.fromLTRB(padding.left, 0, padding.right, 8),
                  );
                },
              ),
            LayoutBuilder(
              builder: (context, constraints) => Padding(
                padding: AppLayout.contentPadding(constraints.maxWidth, top: 8),
                child: shown.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.handshake_outlined,
                        message: 'A associação ainda não tem convênios. Sugira parceiros ao gestor!',
                      )
                    : AppResponsiveGrid(
                        minItemWidth: 320,
                        maxColumns: 3,
                        children: [for (final b in shown) BenefitCard(benefit: b)],
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
