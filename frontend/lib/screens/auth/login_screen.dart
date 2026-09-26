import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../services/auth_service.dart';
import '../../utils/theme.dart';
import '../../utils/validators.dart';
import '../../core/ui/ui.dart';

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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final success = await authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        AppToast.show(
          context,
          message: 'Login realizado com sucesso!',
          type: ToastType.success,
        );
        // Volta para onde o usuário estava (ex: ?next=/checkout); só caminhos internos
        final next = GoRouterState.of(context).uri.queryParameters['next'];
        context.go(next != null && next.startsWith('/') && !next.startsWith('//') ? next : authService.homeRoute);
      } else if (mounted) {
        AppToast.show(
          context,
          message: 'Email ou senha incorretos',
          type: ToastType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Erro ao fazer login: ${e.toString()}',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Stack(
        children: [
          // Background com blur
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primary.withOpacity(0.1),
                    colorScheme.secondary.withOpacity(0.05),
                  ],
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  color: colorScheme.primary.withOpacity(0.08),
                ),
              ),
            ),
          ),
          
          // Conteúdo
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.restaurant,
                                size: 48,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Title
                            Text(
                              'Bem-vindo!',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            
                            Text(
                              'Faça login para continuar',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 40),
                            
                            // Email Field
                            AppTextField(
                              controller: _emailController,
                              labelText: 'Email',
                              hintText: 'Digite seu email',
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: const Icon(Icons.email_outlined),
                              variant: TextFieldVariant.outlined,
                              validator: validateEmail,
                            ),
                            const SizedBox(height: 16),
                            
                            // Password Field
                            AppTextField(
                              controller: _passwordController,
                              labelText: 'Senha',
                              hintText: 'Digite sua senha',
                              obscureText: _obscurePassword,
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              variant: TextFieldVariant.outlined,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, digite sua senha';
                                }
                                if (value.length < 6) {
                                  return 'A senha deve ter pelo menos 6 caracteres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            
                            // Forgot Password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // TODO: Implement forgot password
                                },
                                child: Text(
                                  'Esqueceu a senha?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Login Button
                            AppButton(
                              text: 'Entrar',
                              onPressed: _isLoading ? null : _login,
                              isLoading: _isLoading,
                              variant: ButtonVariant.contained,
                              size: ButtonSize.large,
                              fullWidth: true,
                            ),
                            const SizedBox(height: 24),
                            
                            // Register Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Não tem uma conta? ',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                AppButton(
                                  text: 'Cadastre-se',
                                  onPressed: () => context.go('/registrar/usuario'),
                                  variant: ButtonVariant.text,
                                  size: ButtonSize.medium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: AppButton(
                                text: 'Quero ser entregador',
                                icon: Icons.two_wheeler,
                                onPressed: () => context.go('/registrar/entregador'),
                                variant: ButtonVariant.text,
                                size: ButtonSize.medium,
                              ),
                            ),
                            Text(
                              'É uma associação ou cooperativa de entregadores?',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Center(
                              child: AppButton(
                                text: 'Cadastre sua organização',
                                onPressed: () => context.go('/registrar/associacao'),
                                variant: ButtonVariant.text,
                                size: ButtonSize.medium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
