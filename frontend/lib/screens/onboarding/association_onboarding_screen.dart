import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/ui/ui.dart';
import '../../models/onboarding/association_onboarding_data.dart';
import '../../services/onboarding_service.dart';
import '../../widgets/onboarding/step_dots.dart';
import 'steps/address_step.dart';
import 'steps/association_info_step.dart';
import 'steps/user_info_step.dart';

/// Cadastro de associação/cooperativa de entregadores
///
/// 3 steps:
/// 1. Dados do gestor (conta de acesso)
/// 2. Dados da associação
/// 3. Endereço
///
/// Após o envio, a associação fica aguardando aprovação de um administrador.
class AssociationOnboardingScreen extends StatefulWidget {
  const AssociationOnboardingScreen({super.key});

  @override
  State<AssociationOnboardingScreen> createState() => _AssociationOnboardingScreenState();
}

class _AssociationOnboardingScreenState extends State<AssociationOnboardingScreen> {
  static const _totalSteps = 3;

  final OnboardingService _onboardingService = OnboardingService();
  final PageController _pageController = PageController();
  final Map<String, dynamic> _formData = {};
  final List<bool Function()?> _validators = List.filled(_totalSteps, null);

  int _currentStep = 0;
  bool _isSubmitting = false;
  // Muda a key dos steps para recriá-los com os dados do rascunho restaurado
  int _draftVersion = 0;

  @override
  void initState() {
    super.initState();
    _restoreDraft();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _restoreDraft() async {
    final draft = await _onboardingService.loadAssociationDraft();
    if (draft == null || draft.isEmpty || !mounted) return;

    final shouldRestore = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cadastro em andamento'),
        content: const Text(
          'Encontramos um cadastro que você começou anteriormente. Deseja continuar de onde parou? '
          'Por segurança, a senha precisará ser digitada novamente.',
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

    if (!mounted) return;
    if (shouldRestore == true) {
      setState(() {
        _formData.addAll(draft);
        _draftVersion++;
      });
    } else {
      await _onboardingService.clearAssociationDraft();
    }
  }

  void _onStepDataChanged(Map<String, dynamic> data) {
    setState(() => _formData.addAll(data));
  }

  Future<void> _confirmExit() async {
    if (_isSubmitting) return;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Deseja sair do cadastro?'),
        content: const Text(
          'Seu progresso será salvo e você poderá continuar mais tarde (exceto a senha e a logo).',
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

    if (shouldExit == true && mounted) {
      await _onboardingService.saveAssociationDraft(_formData);
      if (mounted) context.go('/login');
    }
  }

  Future<void> _goToNextStep() async {
    final isValid = _validators[_currentStep]?.call() ?? true;
    if (!isValid) return;

    await _onboardingService.saveAssociationDraft(_formData);

    if (_currentStep == _totalSteps - 1) {
      await _submit();
      return;
    }

    setState(() => _currentStep++);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPreviousStep() {
    if (_currentStep == 0) return;
    setState(() => _currentStep--);
    _pageController.animateToPage(
      _currentStep,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    try {
      final data = AssociationOnboardingData(
        _formData,
        logoFile: _formData['logoFile'] as XFile?,
      );
      await _onboardingService.submitAssociationOnboarding(data);
      await _onboardingService.clearAssociationDraft();

      if (!mounted) return;
      AppToast.show(
        context,
        message: 'Cadastro enviado! Entre com seu email e senha para acompanhar a aprovação.',
        type: ToastType.success,
        duration: const Duration(seconds: 6),
      );
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      AppToast.show(
        context,
        message: e.toString(),
        type: ToastType.error,
        duration: const Duration(seconds: 6),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.1),
                      colorScheme.secondary.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(color: colorScheme.primary.withValues(alpha: 0.08)),
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(colorScheme),
                      Flexible(
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 640),
                          padding: const EdgeInsets.all(24),
                          child: PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            children: _buildSteps(),
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

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          Text(
            'Cadastro de Associação',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Para associações e cooperativas de entregadores',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          StepDots(currentStep: _currentStep, totalSteps: _totalSteps),
        ],
      ),
    );
  }

  List<Widget> _buildSteps() {
    return [
      _withNavigation(UserInfoStep(
        key: ValueKey('user-$_draftVersion'),
        initialData: _formData,
        onDataChanged: _onStepDataChanged,
        onValidationCallback: (validator) => _validators[0] = validator,
      )),
      _withNavigation(AssociationInfoStep(
        key: ValueKey('association-$_draftVersion'),
        initialData: _formData,
        onDataChanged: _onStepDataChanged,
        onValidationCallback: (validator) => _validators[1] = validator,
      )),
      _withNavigation(AddressStep(
        key: ValueKey('address-$_draftVersion'),
        initialData: _formData,
        onDataChanged: _onStepDataChanged,
        onValidationCallback: (validator) => _validators[2] = validator,
        subtitle: 'Sede da associação e região de atuação',
      )),
    ];
  }

  Widget _withNavigation(Widget step) {
    final isLast = _currentStep == _totalSteps - 1;
    return Column(
      children: [
        Expanded(child: step),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppButton(
              text: _currentStep > 0 ? 'ANTERIOR' : 'FAZER LOGIN',
              onPressed: _isSubmitting
                  ? null
                  : (_currentStep > 0 ? _goToPreviousStep : () => context.go('/login')),
              variant: ButtonVariant.text,
              textColor: Colors.grey[900],
              size: ButtonSize.large,
            ),
            AppButton(
              text: isLast ? 'ENVIAR CADASTRO' : 'PRÓXIMO',
              onPressed: _isSubmitting ? null : _goToNextStep,
              isLoading: _isSubmitting,
              variant: ButtonVariant.contained,
              size: ButtonSize.large,
            ),
          ],
        ),
      ],
    );
  }
}
