import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../services/restaurant_panel_service.dart';
import '../restaurant_section.dart';
import 'store/address_tab.dart';
import 'store/appearance_tab.dart';
import 'store/delivery_tab.dart';
import 'store/general_tab.dart';
import 'store/hours_tab.dart';

/// Seção Loja: dados gerais, aparência, endereço, horários e regras de pedido, cada um numa aba
/// com endereço próprio (`/restaurante/loja/<aba>`). A situação (aberta/pausada) fica no menu lateral.
class StoreTab extends StatelessWidget {
  final StoreSection section;

  const StoreTab({super.key, this.section = StoreSection.general});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RestaurantPanelService>().store!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final padding = AppLayout.contentPadding(constraints.maxWidth, bottom: 0);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: padding,
                child: const AppSectionHeader(
                  title: 'Loja',
                  subtitle: 'Dados, aparência, endereço, horários e regras de pedido da sua loja',
                  padding: EdgeInsets.only(bottom: 8),
                ),
              ),
              AppFilterChips<StoreSection>(
                items: [for (final s in StoreSection.values) SelectItem(value: s, label: s.label, icon: s.icon)],
                value: section,
                onSelected: (s) => context.go(s.path),
                padding: EdgeInsets.fromLTRB(padding.left, 8, padding.right, 8),
              ),
            ],
          );
        }),
        Expanded(
          // As chaves recriam os formulários ao trocar de restaurante
          child: IndexedStack(
            index: section.index,
            children: [
              GeneralTab(key: ValueKey('general-${store.id}'), store: store),
              AppearanceTab(key: ValueKey('appearance-${store.id}'), store: store),
              AddressTab(key: ValueKey('address-${store.id}'), store: store),
              HoursTab(key: ValueKey('hours-${store.id}'), store: store),
              DeliveryTab(key: ValueKey('delivery-${store.id}'), store: store),
            ],
          ),
        ),
      ],
    );
  }
}
