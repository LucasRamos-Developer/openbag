import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/association/member.dart';
import '../../services/api_client.dart';
import '../../services/association_service.dart';
import '../../widgets/account/account_fields.dart';
import '../../widgets/courier/courier_document_fields.dart';
import '../../widgets/courier/vehicle_fields.dart';

/// Cadastro de associado feito pelo gestor: cria a conta do entregador, que já entra ativo.
/// Retorna o [Member] criado ao fechar.
class MemberFormScreen extends StatefulWidget {
  const MemberFormScreen({super.key});

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _account = AccountFieldControllers();
  final _cpf = TextEditingController();
  final _cnh = TextEditingController();
  final _vehicle = VehicleFieldControllers();

  VehicleType _vehicleType = VehicleType.MOTORCYCLE;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _cpf.dispose();
    _cnh.dispose();
    _account.dispose();
    _vehicle.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final member = await context.read<AssociationService>().createMember({
        'account': _account.toJson(),
        'deliveryPerson': {
          'documentNumber': _cpf.text.trim(),
          'driverLicense': _cnh.text.trim(),
          ..._vehicle.toJson(_vehicleType, prefix: 'vehicle'),
        },
      });
      if (mounted) Navigator.of(context).pop(member);
    } on ApiException catch (e) {
      if (mounted) {
        AppToast.show(context, message: e.message, type: ToastType.error, duration: const Duration(seconds: 6));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar associado')),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const AppSectionHeader(
                  title: 'Conta de acesso',
                  subtitle: 'Repasse ao entregador o email e a senha inicial para ele entrar no app.',
                ),
                AccountFields(controllers: _account, passwordLabel: 'Senha inicial'),
                const SizedBox(height: 32),
                const AppSectionHeader(title: 'Documentos e veículo'),
                CourierDocumentFields(cpf: _cpf, driverLicense: _cnh),
                const SizedBox(height: 16),
                VehicleFields(
                  type: _vehicleType,
                  onTypeChanged: (type) => setState(() => _vehicleType = type),
                  controllers: _vehicle,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      text: 'Cancelar',
                      variant: ButtonVariant.text,
                      onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    AppButton(
                      text: 'Cadastrar associado',
                      icon: Icons.check,
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : _submit,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
