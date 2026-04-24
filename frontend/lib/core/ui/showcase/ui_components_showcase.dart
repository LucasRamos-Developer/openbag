import 'package:flutter/material.dart';
import '../ui.dart';

/// Showcase/exemplo de todos os componentes UI disponíveis
/// 
/// Use esta tela para visualizar e testar todos os componentes.
class UIComponentsShowcase extends StatefulWidget {
  const UIComponentsShowcase({super.key});

  @override
  State<UIComponentsShowcase> createState() => _UIComponentsShowcaseState();
}

class _UIComponentsShowcaseState extends State<UIComponentsShowcase> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Componentes UI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfo(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // TextField Examples
          _buildSection(
            'Text Fields',
            Icons.text_fields,
            [
              const Text('Variante Outlined (padrão):'),
              const SizedBox(height: 12),
              AppTextField(
                labelText: 'Email',
                hintText: 'seu@email.com',
                prefixIcon: const Icon(Icons.email_outlined),
                variant: TextFieldVariant.outlined,
              ),
              const SizedBox(height: 16),
              
              const Text('Variante Filled:'),
              const SizedBox(height: 12),
              AppTextField(
                labelText: 'Nome completo',
                hintText: 'Digite seu nome',
                prefixIcon: const Icon(Icons.person_outline),
                variant: TextFieldVariant.filled,
              ),
              const SizedBox(height: 16),
              
              const Text('Variante Standard:'),
              const SizedBox(height: 12),
              AppTextField(
                labelText: 'Telefone',
                hintText: '(11) 99999-9999',
                prefixIcon: const Icon(Icons.phone_outlined),
                variant: TextFieldVariant.standard,
              ),
              const SizedBox(height: 16),
              
              const Text('Com Helper Text:'),
              const SizedBox(height: 12),
              AppTextField(
                labelText: 'Senha',
                hintText: 'Mínimo 6 caracteres',
                helperText: 'Use letras e números',
                obscureText: true,
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              const SizedBox(height: 16),
              
              const Text('Com Error:'),
              const SizedBox(height: 12),
              AppTextField(
                labelText: 'Email',
                hintText: 'seu@email.com',
                errorText: 'Email inválido',
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              const SizedBox(height: 16),
              
              const Text('Tamanhos:'),
              const SizedBox(height: 12),
              AppTextField(
                labelText: 'Small',
                size: TextFieldSize.small,
              ),
              const SizedBox(height: 12),
              AppTextField(
                labelText: 'Medium',
                size: TextFieldSize.medium,
              ),
              const SizedBox(height: 12),
              AppTextField(
                labelText: 'Large',
                size: TextFieldSize.large,
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Button Examples
          _buildSection(
            'Buttons',
            Icons.smart_button,
            [
              const Text('Variante Contained (padrão):'),
              const SizedBox(height: 12),
              Row(
                children: [
                  AppButton(
                    text: 'Small',
                    onPressed: () {},
                    size: ButtonSize.small,
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    text: 'Medium',
                    onPressed: () {},
                    size: ButtonSize.medium,
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    text: 'Large',
                    onPressed: () {},
                    size: ButtonSize.large,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              const Text('Variante Outlined:'),
              const SizedBox(height: 12),
              Row(
                children: [
                  AppButton(
                    text: 'Cancelar',
                    onPressed: () {},
                    variant: ButtonVariant.outlined,
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    text: 'Com ícone',
                    onPressed: () {},
                    variant: ButtonVariant.outlined,
                    icon: Icons.star_outline,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              const Text('Variante Text:'),
              const SizedBox(height: 12),
              Row(
                children: [
                  AppButton(
                    text: 'Texto simples',
                    onPressed: () {},
                    variant: ButtonVariant.text,
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    text: 'Com ícone',
                    onPressed: () {},
                    variant: ButtonVariant.text,
                    icon: Icons.arrow_forward,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              const Text('Variante Soft:'),
              const SizedBox(height: 12),
              Row(
                children: [
                  AppButton(
                    text: 'Soft button',
                    onPressed: () {},
                    variant: ButtonVariant.soft,
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    text: 'Com ícone',
                    onPressed: () {},
                    variant: ButtonVariant.soft,
                    icon: Icons.cloud_upload_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              const Text('Com cores customizadas:'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  AppButton(
                    text: 'Secondary',
                    onPressed: () {},
                    backgroundColor: AppColors.secondary,
                  ),
                  AppButton(
                    text: 'Error',
                    onPressed: () {},
                    backgroundColor: AppColors.error,
                  ),
                  AppButton(
                    text: 'Warning',
                    onPressed: () {},
                    backgroundColor: AppColors.warning,
                  ),
                  AppButton(
                    text: 'Info',
                    onPressed: () {},
                    backgroundColor: AppColors.info,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              const Text('Estados:'),
              const SizedBox(height: 12),
              Row(
                children: [
                  AppButton(
                    text: 'Loading',
                    onPressed: () {},
                    isLoading: true,
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    text: 'Disabled',
                    onPressed: null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              const Text('Full width:'),
              const SizedBox(height: 12),
              AppButton(
                text: 'Botão de largura total',
                onPressed: () {},
                fullWidth: true,
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Card Examples
          _buildSection(
            'Cards & Papers',
            Icons.crop_square_rounded,
            [
              const Text('AppCard com elevação:'),
              const SizedBox(height: 12),
              AppCard(
                elevation: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Card com sombra',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Este card tem elevation = 2',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              const Text('AppCard com borda:'),
              const SizedBox(height: 12),
              AppCard(
                elevation: 0,
                borderColor: AppColors.primary,
                borderWidth: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Card com borda',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Este card tem borda customizada',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              const Text('AppCard com gradiente:'),
              const SizedBox(height: 12),
              AppCard(
                gradient: AppColors.primaryGradient,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Card com gradiente',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Este card usa um gradiente de cores',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              const Text('AppPaper variantes:'),
              const SizedBox(height: 12),
              AppPaper(
                variant: PaperVariant.elevation,
                child: const Text('Elevation variant'),
              ),
              const SizedBox(height: 12),
              AppPaper(
                variant: PaperVariant.outlined,
                child: const Text('Outlined variant'),
              ),
              const SizedBox(height: 12),
              AppPaper(
                variant: PaperVariant.filled,
                child: const Text('Filled variant'),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Colors Showcase
          _buildSection(
            'Paleta de Cores',
            Icons.palette,
            [
              _buildColorRow('Primary', AppColors.primary, AppColors.primaryDark, AppColors.primaryLight),
              _buildColorRow('Secondary', AppColors.secondary, AppColors.secondaryDark, AppColors.secondaryLight),
              const SizedBox(height: 8),
              _buildColorRow('Error', AppColors.error, AppColors.errorDark, AppColors.errorLight),
              _buildColorRow('Warning', AppColors.warning, AppColors.warningDark, AppColors.warningLight),
              _buildColorRow('Info', AppColors.info, AppColors.infoDark, AppColors.infoLight),
              _buildColorRow('Success', AppColors.success, AppColors.successDark, AppColors.successLight),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildColorRow(String label, Color main, Color? dark, Color? light) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          _buildColorBox(main),
          if (dark != null) ...[
            const SizedBox(width: 8),
            _buildColorBox(dark),
          ],
          if (light != null) ...[
            const SizedBox(width: 8),
            _buildColorBox(light),
          ],
        ],
      ),
    );
  }

  Widget _buildColorBox(Color color) {
    return Container(
      width: 60,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLine),
      ),
    );
  }

  void _showInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sobre os Componentes'),
        content: const Text(
          'Estes são componentes reutilizáveis baseados no design MUI Minimal.\n\n'
          'Para usar em outro projeto, copie a pasta lib/core/ui/ inteira.\n\n'
          'Veja o README.md para mais detalhes.',
        ),
        actions: [
          AppButton(
            text: 'Entendi',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
