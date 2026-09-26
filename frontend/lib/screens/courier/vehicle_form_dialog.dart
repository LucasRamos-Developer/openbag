import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/courier/vehicle.dart';
import '../../models/courier/vehicle_type.dart';
import '../../services/courier_service.dart';
import '../../utils/feedback.dart';
import '../../widgets/courier/vehicle_fields.dart';

/// Cadastro/edição de veículo. Retorna true se salvou.
Future<bool> showVehicleFormDialog(BuildContext context, {Vehicle? vehicle}) async {
  final saved = await showDialog<bool>(
    context: context,
    builder: (context) => _VehicleFormDialog(vehicle: vehicle),
  );
  return saved ?? false;
}

class _VehicleFormDialog extends StatefulWidget {
  final Vehicle? vehicle;

  const _VehicleFormDialog({this.vehicle});

  @override
  State<_VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends State<_VehicleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late VehicleType _type = widget.vehicle?.type ?? VehicleType.MOTORCYCLE;
  late final _controllers = VehicleFieldControllers(
    plate: widget.vehicle?.plate,
    model: widget.vehicle?.model,
    color: widget.vehicle?.color,
  );
  bool _isSaving = false;

  @override
  void dispose() {
    _controllers.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final ok = await runWithFeedback(
      context,
      () => context.read<CourierService>().saveVehicle(_controllers.toJson(_type), id: widget.vehicle?.id),
      success: widget.vehicle == null ? 'Veículo cadastrado' : 'Veículo atualizado',
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.vehicle == null ? 'Novo veículo' : 'Editar veículo'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: VehicleFields(
              type: _type,
              onTypeChanged: (type) => setState(() => _type = type),
              controllers: _controllers,
            ),
          ),
        ),
      ),
      actions: [
        AppButton(
          text: 'Cancelar',
          variant: ButtonVariant.text,
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
        ),
        AppButton(text: 'Salvar', icon: Icons.check, isLoading: _isSaving, onPressed: _isSaving ? null : _save),
      ],
    );
  }
}
