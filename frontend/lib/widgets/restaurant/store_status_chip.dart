import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/store/store.dart';

/// Situação da loja agora: aberta, pausada (até que horas) ou fechada
class StoreStatusChip extends StatelessWidget {
  final Store store;

  const StoreStatusChip({super.key, required this.store});

  static String labelOf(Store store) {
    if (store.paused) {
      final until = store.pausedUntil!;
      String two(int v) => v.toString().padLeft(2, '0');
      return 'Pausada até ${two(until.hour)}:${two(until.minute)}';
    }
    if (store.openNow) return 'Aberta';
    return store.open ? 'Fora do horário' : 'Fechada';
  }

  static Color colorOf(Store store) {
    if (store.paused) return AppColors.warningDarker;
    return store.openNow ? AppColors.successDark : AppColors.errorDark;
  }

  @override
  Widget build(BuildContext context) => AppStatusChip(label: labelOf(store), color: colorOf(store));
}
