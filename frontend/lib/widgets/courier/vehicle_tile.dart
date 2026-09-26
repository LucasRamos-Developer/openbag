import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../core/ui/ui.dart';
import '../../models/courier/vehicle.dart';

/// Veículo do entregador com a marcação "Em uso" e ações opcionais
class VehicleTile extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback? onActivate;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  final VoidCallback? onChangePhoto;

  const VehicleTile({super.key, required this.vehicle, this.onActivate, this.onEdit, this.onRemove, this.onChangePhoto});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final photo = vehicle.photoUrl;

    return AppCard(
      padding: const EdgeInsets.all(16),
      borderColor: vehicle.active ? colorScheme.primary : null,
      borderWidth: vehicle.active ? 1.5 : null,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 64,
              height: 64,
              color: colorScheme.primary.withValues(alpha: 0.1),
              child: photo != null
                  ? Image.network(AppConstants.fileUrl(photo), fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(vehicle.type.icon, color: colorScheme.primary, size: 32))
                  : Icon(vehicle.type.icon, color: colorScheme.primary, size: 32),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(vehicle.title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    if (vehicle.active) const AppStatusChip(label: 'Em uso', color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [vehicle.type.label, if (vehicle.plate != null) vehicle.plate!, if (vehicle.color != null) vehicle.color!]
                      .join(' · '),
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.textBody),
                ),
              ],
            ),
          ),
          if (onActivate != null || onEdit != null || onRemove != null || onChangePhoto != null)
            PopupMenuButton<VoidCallback>(
              tooltip: 'Ações',
              onSelected: (action) => action(),
              itemBuilder: (context) => [
                if (onActivate != null && !vehicle.active)
                  PopupMenuItem(value: onActivate, child: const Text('Usar este veículo')),
                if (onEdit != null) PopupMenuItem(value: onEdit, child: const Text('Editar')),
                if (onChangePhoto != null) PopupMenuItem(value: onChangePhoto, child: const Text('Trocar foto')),
                if (onRemove != null) PopupMenuItem(value: onRemove, child: const Text('Remover')),
              ],
            ),
        ],
      ),
    );
  }
}
