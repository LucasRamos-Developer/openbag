import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/ui/ui.dart';
import '../../models/courier/vehicle_type.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/courier_service.dart';
import '../../widgets/account/account_fields.dart';
import '../../widgets/courier/association_picker.dart';
import '../../widgets/courier/courier_document_fields.dart';
import '../../widgets/courier/vehicle_fields.dart';

/// Auto-cadastro do entregador: conta, documentos, veículo e associação.
/// Com código de convite entra ativo; escolhendo a associação fica aguardando aprovação do gestor.
/// Aceita `?convite=CODIGO` para já vir com o código preenchido.
class CourierOnboardingScreen extends StatefulWidget {
  final String? inviteCode;

  const CourierOnboardingScreen({super.key, this.inviteCode});

  @override
  State<CourierOnboardingScreen> createState() => _CourierOnboardingScreenState();
}

class _CourierOnboardingScreenState extends State<CourierOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _account = AccountFieldControllers();
  final _cpf = TextEditingController();
  final _cnh = TextEditingController();
  final _vehicle = VehicleFieldControllers();

  VehicleType _vehicleType = VehicleType.MOTORCYCLE;
  AssociationChoice? _association;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _account.dispose();
    _cpf.dispose();
    _cnh.dispose();
    _vehicle.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final association = _association;
    if (association == null) {
      AppToast.show(context, message: 'Valide um código de convite ou escolha uma associação', type: ToastType.warning);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final account = _account.toJson();
      await context.read<CourierService>().register({
        'account': account,
        'deliveryPerson': {
          'documentNumber': _cpf.text.trim(),
          'driverLicense': _cnh.text.trim(),
          ..._vehicle.toJson(_vehicleType, prefix: 'vehicle'),
        },
        ...association.toJson(),
      });
      if (!mounted) return;

      final auth = context.read<AuthService>();
      final loggedIn = await auth.login(account['email'], account['password']);
      if (!mounted) return;
      AppToast.show(
        context,
        message: association.isInvite
            ? 'Cadastro concluído! Você já faz parte de ${association.association.tradingName}.'
            : 'Cadastro concluído! Aguarde a aprovação de ${association.association.tradingName}.',
        type: ToastType.success,
        duration: const Duration(seconds: 6),
      );
      context.go(loggedIn ? '/entregador' : '/login');
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
      appBar: AppBar(
        title: const Text('Cadastro de entregador'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/login')),
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const AppSectionHeader(
                  title: 'Sua conta',
                  subtitle: 'Você vai usar o email e a senha para entrar no painel do entregador.',
                ),
                AccountFields(controllers: _account),
                const SizedBox(height: 32),
                const AppSectionHeader(title: 'Documentos'),
                CourierDocumentFields(cpf: _cpf, driverLicense: _cnh),
                const SizedBox(height: 32),
                const AppSectionHeader(
                  title: 'Veículo',
                  subtitle: 'Depois você pode cadastrar outros veículos e escolher qual está usando.',
                ),
                VehicleFields(
                  type: _vehicleType,
                  onTypeChanged: (type) => setState(() => _vehicleType = type),
                  controllers: _vehicle,
                ),
                const SizedBox(height: 32),
                const AppSectionHeader(
                  title: 'Associação',
                  subtitle: 'Todo entregador do OpenBag faz parte de uma associação ou cooperativa.',
                ),
                AssociationPicker(
                  value: _association,
                  initialInviteCode: widget.inviteCode,
                  onChanged: (choice) => setState(() => _association = choice),
                ),
                const SizedBox(height: 32),
                AppButton(
                  text: 'Criar cadastro',
                  icon: Icons.check,
                  size: ButtonSize.large,
                  fullWidth: true,
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
