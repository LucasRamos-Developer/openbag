import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/courier/vehicle_type.dart';
import '../../utils/validators.dart';

/// Controladores dos campos de veículo
class VehicleFieldControllers {
  final plate = TextEditingController();
  final model = TextEditingController();
  final color = TextEditingController();

  VehicleFieldControllers({String? plate, String? model, String? color}) {
    this.plate.text = plate ?? '';
    this.model.text = model ?? '';
    this.color.text = color ?? '';
  }

  static String? _nullIfEmpty(String value) => value.trim().isEmpty ? null : value.trim();

  /// Corpo do veículo no formato da API; [prefix] gera "vehiclePlate" etc. no cadastro do entregador
  Map<String, dynamic> toJson(VehicleType type, {String? prefix}) {
    String key(String name) => prefix == null ? name : '$prefix${name[0].toUpperCase()}${name.substring(1)}';
    return {
      key('type'): type.name,
      key('plate'): _nullIfEmpty(plate.text),
      key('model'): _nullIfEmpty(model.text),
      key('color'): _nullIfEmpty(color.text),
    };
  }

  void dispose() {
    plate.dispose();
    model.dispose();
    color.dispose();
  }
}

/// Tipo, placa, modelo e cor do veículo (a placa é obrigatória para moto e carro)
class VehicleFields extends StatelessWidget {
  final VehicleType type;
  final ValueChanged<VehicleType> onTypeChanged;
  final VehicleFieldControllers controllers;

  const VehicleFields({super.key, required this.type, required this.onTypeChanged, required this.controllers});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSelect<VehicleType>(
          labelText: 'Tipo de veículo',
          variant: TextFieldVariant.filled,
          value: type,
          items: [for (final t in VehicleType.values) SelectItem(value: t, label: t.label)],
          onChanged: (value) => onTypeChanged(value ?? type),
        ),
        const SizedBox(height: 16),
        AppResponsiveRow(
          breakpoint: 520,
          children: [
            AppTextField(
              controller: controllers.plate,
              labelText: type.requiresPlate ? 'Placa' : 'Placa (opcional)',
              hintText: 'ABC1D23',
              variant: TextFieldVariant.filled,
              textCapitalization: TextCapitalization.characters,
              validator: (v) => type.requiresPlate ? validateRequired(v, 'Placa') : null,
            ),
            AppTextField(
              controller: controllers.model,
              labelText: 'Modelo (opcional)',
              hintText: 'Ex: Honda CG 160',
              variant: TextFieldVariant.filled,
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: controllers.color,
          labelText: 'Cor (opcional)',
          variant: TextFieldVariant.filled,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }
}
