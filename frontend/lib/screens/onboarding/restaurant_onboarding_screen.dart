import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/onboarding_service.dart';
import '../../models/onboarding/restaurant_onboarding_data.dart';
import '../../widgets/onboarding/step_indicator.dart';
import '../../core/ui/ui.dart';
import 'steps/user_info_step.dart';
import 'steps/organization_step.dart';
import 'steps/address_step.dart';
import 'steps/customization_step.dart';

/// Tela principal do onboarding de restaurante
/// 
/// 4 steps para novos usuários:
/// 1. Dados do proprietário
/// 2. Dados do restaurante
/// 3. Endereço
/// 4. Personalização + categorias
/// 
/// 3 steps para usuários logados (pula step 1):
/// 1. Dados do restaurante
/// 2. Endereço
/// 3. Personalização + categorias
class RestaurantOnboardingScreen extends StatefulWidget {
  const RestaurantOnboardingScreen({super.key});

  @override
  State<RestaurantOnboardingScreen> createState() => _RestaurantOnboardingScreenState();
}

class _RestaurantOnboardingScreenState extends State<RestaurantOnboardingScreen> {
  final OnboardingService _onboardingService = OnboardingService();
  final PageController _pageController = PageController();
  
  late bool _isLoggedIn;
  late int _totalSteps;
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Armazenar dados de cada step
  final Map<String, dynamic> _formData = {};

  // Callbacks de validação dos steps
  bool Function()? _validateUserInfo;
  bool Function()? _validateOrganization;
  bool Function()? _validateAddress;
  bool Function()? _validateCustomization;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateAuthState();
  }

  void _updateAuthState() {
    final authService = Provider.of<AuthService>(context, listen: false);
    _isLoggedIn = authService.isAuthenticated;
    _totalSteps = _isLoggedIn ? 3 : 4;
  }

  Future<void> _loadInitialData() async {
    // Tentar restaurar rascunho
    final hasDraft = await _onboardingService.hasDraft();
    if (hasDraft && mounted) {
      final shouldRestore = await _showRestoreDraftDialog();
      if (shouldRestore == true) {
        final draft = await _onboardingService.loadDraft();
        if (draft != null && mounted) {
          setState(() {
            _formData.addAll(draft.toJson());
          });
        }
      }
    }
  }

  Future<bool?> _showRestoreDraftDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Cadastro em andamento'),
        content: const Text(
          'Encontramos um cadastro que você começou anteriormente. Deseja continuar de onde parou ou começar novamente?',
        ),
        actions: [
          AppButton(
            text: 'Recomeçar',
            onPressed: () => Navigator.of(context).pop(false),
            variant: ButtonVariant.outlined,
          ),
          AppButton(
            text: 'Continuar cadastro',
            onPressed: () => Navigator.of(context).pop(true),
            icon: Icons.play_arrow_rounded,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onStepDataChanged(Map<String, dynamic> data) {
    setState(() {
      _formData.addAll(data);
    });
  }

  Future<void> _saveDraft() async {
    try {
      final data = RestaurantOnboardingData.fromJson(_formData);
      await _onboardingService.saveDraft(data);
    } catch (e) {
      print('Erro ao salvar rascunho: $e');
    }
  }

  Future<bool> _onWillPop() async {
    if (_isSubmitting) {
      return false; // Não permitir sair durante submit
    }

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Deseja sair do cadastro?'),
        content: const Text(
          'Não se preocupe! Seu progresso será salvo automaticamente e você poderá continuar mais tarde.',
        ),
        actions: [
          AppButton(
            text: 'Continuar editando',
            onPressed: () => Navigator.of(context).pop(false),
            variant: ButtonVariant.outlined,
          ),
          AppButton(
            text: 'Sair e salvar',
            onPressed: () => Navigator.of(context).pop(true),
            icon: Icons.exit_to_app_rounded,
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      await _saveDraft();
    }

    return shouldExit ?? false;
  }

  Future<void> _goToNextStep() async {
    // Validar o step atual
    bool isValid = false;

    if (_isLoggedIn) {
      // Usuário logado: step 0 = Organization, step 1 = Address, step 2 = Customization
      if (_currentStep == 0) {
        isValid = await _validateOrganizationStep();
      } else if (_currentStep == 1) {
        isValid = await _validateAddressStep();
      } else {
        isValid = await _validateCustomizationStep();
      }
    } else {
      // Novo usuário: step 0 = UserInfo, step 1 = Organization, step 2 = Address, step 3 = Customization
      if (_currentStep == 0) {
        isValid = await _validateUserInfoStep();
      } else if (_currentStep == 1) {
        isValid = await _validateOrganizationStep();
      } else if (_currentStep == 2) {
        isValid = await _validateAddressStep();
      } else {
        isValid = await _validateCustomizationStep();
      }
    }

    if (!isValid) return;

    // Salvar rascunho
    await _saveDraft();

    // Se for o último step, submeter
    if (_currentStep == _totalSteps - 1) {
      await _submitOnboarding();
      return;
    }

    // Ir para o próximo step
    setState(() => _currentStep++);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPreviousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<bool> _validateUserInfoStep() async {
    return _validateUserInfo?.call() ?? true;
  }

  Future<bool> _validateOrganizationStep() async {
    return _validateOrganization?.call() ?? true;
  }

  Future<bool> _validateAddressStep() async {
    return _validateAddress?.call() ?? true;
  }

  Future<bool> _validateCustomizationStep() async {
    return _validateCustomization?.call() ?? true;
  }

  Future<void> _submitOnboarding() async {
    setState(() => _isSubmitting = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final data = RestaurantOnboardingData.fromJson(_formData);

      final result = await _onboardingService.submitOnboarding(
        data: data,
        ownerEmailOverride: authService.currentUser?.email,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        // Limpar rascunho
        await _onboardingService.clearDraft();

        // Mostrar sucesso e navegar
        AppToast.show(
          context,
          message: result['message'] ?? 'Restaurante cadastrado com sucesso!',
          type: ToastType.success,
        );

        // Navegar para home ou dashboard do restaurante
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      } else {
        throw Exception(result['message'] ?? 'Erro ao cadastrar restaurante');
      }
    } catch (e) {
      if (!mounted) return;

      AppToast.show(
        context,
        message: 'Erro: $e',
        type: ToastType.error,
        duration: const Duration(seconds: 5),
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
    
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
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
                              'Cadastro de Restaurante',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            // Wizard dots simplificados
                            _buildSimpleStepIndicator(),
                          ],
                        ),
                      ),
                      
                      // Conteúdo do wizard
                      Flexible(
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 600),
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Expanded(
                                child: PageView(
                                  controller: _pageController,
                                  physics: const NeverScrollableScrollPhysics(),
                                  onPageChanged: (index) {
                                    setState(() => _currentStep = index);
                                  },
                                  children: _buildSteps(),
                                ),
                              ),
                            ],
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
      ),
    );
  }

  Widget _buildSimpleStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalSteps, (index) {
        final isActive = index == _currentStep;
        final isCompleted = index < _currentStep;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: (isActive || isCompleted)
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  List<Widget> _buildSteps() {
    final steps = <Widget>[];

    if (!_isLoggedIn) {
      // Step 1: Dados do proprietário
      steps.add(
        _buildStepWithNavigation(
          UserInfoStep(
            initialData: _formData,
            onDataChanged: _onStepDataChanged,
            onValidationCallback: (validator) => _validateUserInfo = validator,
          ),
        ),
      );
    }

    // Step 2 (ou 1 se logado): Dados do Restaurante
    steps.add(
      _buildStepWithNavigation(
        OrganizationStep(
          initialData: _formData,
          onDataChanged: _onStepDataChanged,
          onValidationCallback: (validator) => _validateOrganization = validator,
        ),
      ),
    );

    // Step 3 (ou 2 se logado): Endereço
    steps.add(
      _buildStepWithNavigation(
        AddressStep(
          initialData: _formData,
          onDataChanged: _onStepDataChanged,
          onValidationCallback: (validator) => _validateAddress = validator,
        ),
      ),
    );

    // Step 4 (ou 3 se logado): Personalização
    steps.add(
      _buildStepWithNavigation(
        CustomizationStep(
          initialData: _formData,
          onDataChanged: _onStepDataChanged,
          onSubmit: _goToNextStep,
          isSubmitting: _isSubmitting,
          onValidationCallback: (validator) => _validateCustomization = validator,
        ),
      ),
    );

    return steps;
  }

  Widget _buildStepWithNavigation(Widget stepContent) {
    return Column(
      children: [
        Expanded(
          child: stepContent,
        ),
        const SizedBox(height: 24),
        _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_currentStep > 0) ...[
          AppButton(
            text: 'ANTERIOR',
            onPressed: _isSubmitting ? null : _goToPreviousStep,
            variant: ButtonVariant.text,
            textColor: Colors.grey[900],
            size: ButtonSize.large,
          ),
          const SizedBox(width: 12),
        ],
        AppButton(
          text: _currentStep == _totalSteps - 1 ? 'CONCLUIR' : 'PRÓXIMO',
          onPressed: _isSubmitting ? null : _goToNextStep,
          isLoading: _isSubmitting,
          variant: ButtonVariant.contained,
          size: ButtonSize.large,
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Botão Voltar
            if (_currentStep > 0)
              Expanded(
                child: AppButton(
                  text: 'ANTERIOR',
                  onPressed: _isSubmitting ? null : _goToPreviousStep,
                  variant: ButtonVariant.text,
                  textColor: Colors.grey[900],
                  size: ButtonSize.large,
                  icon: Icons.arrow_back_rounded,
                ),
              ),
            
            if (_currentStep > 0) const SizedBox(width: 16),

            // Botão Próximo/Finalizar
            Expanded(
              child: AppButton(
                text: _currentStep == _totalSteps - 1 ? 'CONCLUIR CADASTRO' : 'PRÓXIMA ETAPA',
                onPressed: _isSubmitting ? null : _goToNextStep,
                isLoading: _isSubmitting,
                variant: ButtonVariant.contained,
                size: ButtonSize.large,
                endIcon: _currentStep == _totalSteps - 1 ? Icons.check_rounded : Icons.arrow_forward_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
