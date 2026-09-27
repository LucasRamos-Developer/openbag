import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../models/courier/vehicle.dart';
import '../../../services/courier_service.dart';
import '../../../utils/feedback.dart';
import '../../../widgets/courier/vehicle_tile.dart';
import '../vehicle_form_dialog.dart';

/// Veículos do entregador: cadastrar, editar, trocar foto, escolher o que está em uso e remover
class VehiclesTab extends StatelessWidget {
  const VehiclesTab({super.key});

  Future<void> _changePhoto(BuildContext context, Vehicle vehicle) async {
    final service = context.read<CourierService>();
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1280, imageQuality: 85);
    if (file == null || !context.mounted) return;
    await runWithFeedback(context, () => service.updateVehiclePhoto(vehicle.id, file), success: 'Foto atualizada');
  }

  Future<void> _remove(BuildContext context, Vehicle vehicle) async {
    final service = context.read<CourierService>();
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Remover veículo?',
      message: '${vehicle.title} sai da sua lista. As entregas feitas com ele continuam no histórico.',
      confirmLabel: 'Remover',
    );
    if (!confirmed || !context.mounted) return;
    await runWithFeedback(context, () => service.removeVehicle(vehicle.id), success: 'Veículo removido');
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<CourierService>();
    final vehicles = service.vehicles;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSectionHeader(
                  title: 'Meus veículos',
                  subtitle: 'O veículo em uso aparece na placa de verificação e para o restaurante e o cliente.',
                  action: AppButton(
                    text: 'Adicionar',
                    icon: Icons.add,
                    onPressed: () => showVehicleFormDialog(context),
                  ),
                ),
                if (vehicles.isEmpty)
                  AppEmptyState(
                    icon: Icons.two_wheeler,
                    message: 'Cadastre a moto, bicicleta ou carro que você usa nas entregas.',
                    actionLabel: 'Cadastrar veículo',
                    onAction: () => showVehicleFormDialog(context),
                  )
                else
                  for (final vehicle in vehicles) ...[
                    VehicleTile(
                      vehicle: vehicle,
                      onActivate: () => runWithFeedback(context, () => service.activateVehicle(vehicle.id),
                          success: '${vehicle.title} em uso'),
                      onEdit: () => showVehicleFormDialog(context, vehicle: vehicle),
                      onChangePhoto: () => _changePhoto(context, vehicle),
                      onRemove: () => _remove(context, vehicle),
                    ),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
