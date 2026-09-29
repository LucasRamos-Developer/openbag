import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../utils/redirects.dart';
import '../../utils/validators.dart';
import '../../core/ui/ui.dart';
import '../../widgets/auth/auth_card.dart';
import '../../widgets/navigation/storefront_footer.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Para onde voltar depois de entrar (ex: ?next=/checkout)
  String? get _next => safeNextPath(GoRouterState.of(context).uri.queryParameters['next']);

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authService = context.read<AuthService>();
      final success = await authService.login(_emailController.text.trim(), _passwordController.text);
      if (!mounted) return;
      if (success) {
        context.go(_next ?? authService.homeRoute);
      } else {
        AppToast.show(context, message: 'Email ou senha incorretos', type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Ainda não há envio de email: a recuperação é feita pelo contato do projeto
  Future<void> _forgotPassword() async {
    final write = await AppDialog.confirm(
      context,
      title: 'Esqueceu a senha?',
      message: 'Escreva para ${StorefrontFooter.contactEmail} com o email da sua conta que a gente ajuda você a '
          'criar uma senha nova.',
      confirmLabel: 'Escrever email',
      cancelLabel: 'Fechar',
    );
    if (write) {
      await launchUrl(Uri(scheme: 'mailto', path: StorefrontFooter.contactEmail,
          queryParameters: {'subject': 'Recuperar senha do OpenBag'}));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AuthCard(
      icon: Icons.restaurant,
      title: 'Bem-vindo!',
      subtitle: 'Entre para fazer e acompanhar seus pedidos',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _emailController,
              labelText: 'Email',
              hintText: 'Digite seu email',
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined),
              validator: validateEmail,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _passwordController,
              labelText: 'Senha',
              hintText: 'Digite sua senha',
              obscureText: _obscurePassword,
              prefixIcon: const Icon(Icons.lock_outlined),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Mostrar senha' : 'Esconder senha',
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Digite sua senha' : null,
              onSubmitted: (_) => _login(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(text: 'Esqueceu a senha?', variant: ButtonVariant.text, onPressed: _forgotPassword),
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Entrar',
              onPressed: _isLoading ? null : _login,
              isLoading: _isLoading,
              size: ButtonSize.large,
              fullWidth: true,
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Não tem uma conta?', style: textTheme.bodyMedium),
                AppButton(
                  text: 'Cadastre-se',
                  variant: ButtonVariant.text,
                  onPressed: () => context.go(withNext('/registrar/usuario', _next)),
                ),
              ],
            ),
            const Divider(height: 32),
            AppButton(
              text: 'Quero ser entregador',
              icon: Icons.two_wheeler,
              variant: ButtonVariant.text,
              onPressed: () => context.go('/registrar/entregador'),
            ),
            AppButton(
              text: 'Cadastrar associação',
              icon: Icons.groups_outlined,
              variant: ButtonVariant.text,
              onPressed: () => context.go('/registrar/associacao'),
            ),
          ],
        ),
      ),
    );
  }
}
