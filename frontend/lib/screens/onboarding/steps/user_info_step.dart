import 'package:flutter/material.dart';
import '../../../utils/validators.dart';
import '../../../utils/formatters.dart';
import '../../../core/ui/ui.dart';

/// Step 1: Dados do Usuário (apenas se não estiver logado)
class UserInfoStep extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final ValueChanged<Map<String, dynamic>> onDataChanged;
  final ValueChanged<bool Function()>? onValidationCallback;

  const UserInfoStep({
    super.key,
    required this.initialData,
    required this.onDataChanged,
    this.onValidationCallback,
  });

  @override
  State<UserInfoStep> createState() => _UserInfoStepState();
}

class _UserInfoStepState extends State<UserInfoStep> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData['ownerFullName']);
    _emailController = TextEditingController(text: widget.initialData['ownerEmail']);
    _phoneController = TextEditingController(text: widget.initialData['ownerPhoneNumber']);
    _passwordController = TextEditingController(text: widget.initialData['ownerPassword']);
    _confirmPasswordController = TextEditingController();

    // Registrar callback de validação
    widget.onValidationCallback?.call(validate);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool validate() {
    return _formKey.currentState?.validate() ?? false;
  }

  void _notifyChanges() {
    widget.onDataChanged({
      'ownerFullName': _nameController.text.trim(),
      'ownerEmail': _emailController.text.trim(),
      'ownerPhoneNumber': _phoneController.text.trim(),
      'ownerPassword': _passwordController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'Dados do Proprietário',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Preencha seus dados pessoais para criar sua conta',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),

            // Nome completo
            AppTextField(
              controller: _nameController,
              labelText: 'Nome completo',
              hintText: 'Digite seu nome completo',
              variant: TextFieldVariant.filled,
              keyboardType: TextInputType.name,
              validator: (value) => validateRequired(value, 'Nome completo'),
              onChanged: (_) => _notifyChanges(),
            ),
            const SizedBox(height: 20),

            // Email
            AppTextField(
              controller: _emailController,
              labelText: 'Email',
              hintText: 'seu@email.com',
              variant: TextFieldVariant.filled,
              keyboardType: TextInputType.emailAddress,
              validator: validateEmail,
              onChanged: (_) => _notifyChanges(),
            ),
            const SizedBox(height: 20),

            // Telefone
            AppTextField(
              controller: _phoneController,
              labelText: 'Telefone',
              hintText: '(XX) XXXXX-XXXX',
              variant: TextFieldVariant.filled,
              keyboardType: TextInputType.phone,
              inputFormatters: [phoneFormatterShort],
              validator: (value) => validateRequired(value, 'Telefone'),
              onChanged: (_) => _notifyChanges(),
            ),
            const SizedBox(height: 20),

            // Senha
            AppTextField(
              controller: _passwordController,
              labelText: 'Senha',
              hintText: 'Mínimo 6 caracteres',
              variant: TextFieldVariant.filled,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              validator: validatePassword,
              onChanged: (_) => _notifyChanges(),
            ),
            const SizedBox(height: 20),

            // Confirmar senha
            AppTextField(
              controller: _confirmPasswordController,
              labelText: 'Confirmar senha',
              hintText: 'Digite a senha novamente',
              variant: TextFieldVariant.filled,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirme sua senha';
                }
                if (value != _passwordController.text) {
                  return 'As senhas não coincidem';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Info card removido para manter minimalista
          ],
        ),
      ),
    );
  }
}
