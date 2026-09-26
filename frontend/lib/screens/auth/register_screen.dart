import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../../utils/formatters.dart';
import '../../core/ui/ui.dart';

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
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    return _formKey.currentState?.validate() ?? false;
  }

  void _notifyChanges() {
    // Atualizar estado se necessário
  }

  Future<void> _register() async {
    if (!_validateForm()) return;

    setState(() => _isSubmitting = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final success = await authService.register(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        AppToast.show(
          context,
          message: 'Conta criada com sucesso! Faça login para continuar.',
          type: ToastType.success,
        );
        context.go('/login');
      } else {
        AppToast.show(
          context,
          message: 'Erro ao criar conta. Tente novamente.',
          type: ToastType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      AppToast.show(
        context,
        message: 'Erro: $e',
        type: ToastType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
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
          
          // Box centralizada
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header da box com título
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.outline.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Cadastrar Usuário',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Preencha seus dados para criar uma conta',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    // Conteúdo do formulário
                    Flexible(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 600),
                        padding: const EdgeInsets.all(32),
                        child: Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
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
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Por favor, digite sua senha';
                                    }
                                    if (value.length < 6) {
                                      return 'A senha deve ter pelo menos 6 caracteres';
                                    }
                                    return null;
                                  },
                                  onChanged: (_) => _notifyChanges(),
                                ),
                                const SizedBox(height: 20),

                                // Confirmar Senha
                                AppTextField(
                                  controller: _confirmPasswordController,
                                  labelText: 'Confirmar senha',
                                  hintText: 'Digite sua senha novamente',
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
                                      return 'Por favor, confirme sua senha';
                                    }
                                    if (value != _passwordController.text) {
                                      return 'As senhas não coincidem';
                                    }
                                    return null;
                                  },
                                  onChanged: (_) => _notifyChanges(),
                                ),
                                const SizedBox(height: 32),

                                // Navegação
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    AppButton(
                                      text: 'FAZER LOGIN',
                                      onPressed: _isSubmitting ? null : () => context.go('/login'),
                                      variant: ButtonVariant.text,
                                      textColor: Colors.grey[900],
                                      size: ButtonSize.large,
                                    ),
                                    AppButton(
                                      text: 'CRIAR CONTA',
                                      onPressed: _isSubmitting ? null : _register,
                                      isLoading: _isSubmitting,
                                      variant: ButtonVariant.contained,
                                      size: ButtonSize.large,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
