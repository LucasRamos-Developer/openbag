import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../utils/redirects.dart';
import '../../utils/validators.dart';
import '../../utils/formatters.dart';
import '../../core/ui/ui.dart';
import '../../widgets/auth/auth_card.dart';

/// Cadastro do cliente. Depois de criar a conta, já entra e volta para onde estava (ex: o checkout).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    for (final c in [_nameController, _emailController, _phoneController, _passwordController, _confirmPasswordController]) {
      c.dispose();
    }
    super.dispose();
  }

  String? get _next => safeNextPath(GoRouterState.of(context).uri.queryParameters['next']);

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final authService = context.read<AuthService>();
      final email = _emailController.text.trim();
      final error = await authService.register(
        fullName: _nameController.text.trim(),
        email: email,
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      if (error != null) {
        AppToast.show(context, message: error, type: ToastType.error, duration: const Duration(seconds: 6));
        return;
      }

      // Conta criada: entra direto, sem pedir a senha de novo
      final loggedIn = await authService.login(email, _passwordController.text);
      if (!mounted) return;
      AppToast.show(context, message: 'Conta criada! Bem-vindo ao OpenBag.', type: ToastType.success);
      context.go(loggedIn ? (_next ?? authService.homeRoute) : withNext('/login', _next));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthCard(
      icon: Icons.person_add_alt_1_outlined,
      title: 'Criar conta',
      subtitle: 'Leva menos de um minuto',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _nameController,
              labelText: 'Nome completo',
              hintText: 'Como você se chama',
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
              prefixIcon: const Icon(Icons.person_outline),
              validator: (value) => validateRequired(value, 'Nome completo'),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _emailController,
              labelText: 'Email',
              hintText: 'seu@email.com',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
              validator: validateEmail,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _phoneController,
              labelText: 'Celular',
              hintText: '(XX) XXXXX-XXXX',
              keyboardType: TextInputType.phone,
              inputFormatters: [PhoneFormatter()],
              prefixIcon: const Icon(Icons.phone_outlined),
              validator: (value) => validateRequired(value, 'Celular'),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _passwordController,
              labelText: 'Senha',
              hintText: 'Mínimo 6 caracteres',
              obscureText: _obscurePassword,
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Mostrar senha' : 'Esconder senha',
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Crie uma senha';
                if (value.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
                return null;
              },
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _confirmPasswordController,
              labelText: 'Confirmar senha',
              hintText: 'Digite a senha de novo',
              obscureText: _obscurePassword,
              prefixIcon: const Icon(Icons.lock_outlined),
              validator: (value) => value != _passwordController.text ? 'As senhas não coincidem' : null,
              onSubmitted: (_) => _register(),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Criar conta',
              onPressed: _isSubmitting ? null : _register,
              isLoading: _isSubmitting,
              size: ButtonSize.large,
              fullWidth: true,
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Já tem conta?', style: Theme.of(context).textTheme.bodyMedium),
                AppButton(
                  text: 'Entrar',
                  variant: ButtonVariant.text,
                  onPressed: _isSubmitting ? null : () => context.go(withNext('/login', _next)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
