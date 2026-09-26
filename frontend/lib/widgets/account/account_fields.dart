import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';

/// Controladores dos dados de acesso de uma conta nova
class AccountFieldControllers {
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();

  /// Corpo "account" da API
  Map<String, dynamic> toJson() => {
        'fullName': name.text.trim(),
        'email': email.text.trim(),
        'phoneNumber': phone.text.trim(),
        'password': password.text,
      };

  void dispose() {
    for (final c in [name, email, phone, password]) {
      c.dispose();
    }
  }
}

/// Nome, email, telefone e senha de uma conta nova
class AccountFields extends StatefulWidget {
  final AccountFieldControllers controllers;
  final String passwordLabel;

  const AccountFields({super.key, required this.controllers, this.passwordLabel = 'Senha'});

  @override
  State<AccountFields> createState() => _AccountFieldsState();
}

class _AccountFieldsState extends State<AccountFields> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final c = widget.controllers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: c.name,
          labelText: 'Nome completo',
          variant: TextFieldVariant.filled,
          textCapitalization: TextCapitalization.words,
          validator: (v) => validateRequired(v, 'Nome completo'),
        ),
        const SizedBox(height: 16),
        AppResponsiveRow(
          breakpoint: 520,
          children: [
            AppTextField(
              controller: c.email,
              labelText: 'Email',
              variant: TextFieldVariant.filled,
              keyboardType: TextInputType.emailAddress,
              validator: validateEmail,
            ),
            AppTextField(
              controller: c.phone,
              labelText: 'Telefone',
              hintText: '(XX) XXXXX-XXXX',
              variant: TextFieldVariant.filled,
              keyboardType: TextInputType.phone,
              inputFormatters: [phoneFormatterShort],
              validator: (v) => validateRequired(v, 'Telefone'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: c.password,
          labelText: widget.passwordLabel,
          variant: TextFieldVariant.filled,
          obscureText: _obscurePassword,
          validator: validatePassword,
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ],
    );
  }
}
