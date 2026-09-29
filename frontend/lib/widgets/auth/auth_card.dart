import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui/ui.dart';

/// Moldura das telas de entrada (login e cadastro): fundo suave, card centralizado com ícone,
/// título e subtítulo, e um "Voltar" que leva de volta à loja ou à vitrine.
class AuthCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const AuthCard({super.key, required this.icon, required this.title, required this.subtitle, required this.child});

  void _back(BuildContext context) => context.canPop() ? context.pop() : context.go('/home');

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final compact = AppLayout.isCompact(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(colors.primary.withValues(alpha: 0.14), colors.background),
              Color.alphaBlend(colors.primary.withValues(alpha: 0.06), colors.background),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(compact ? 16 : 24, 64, compact ? 16 : 24, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      padding: EdgeInsets.all(compact ? 24 : 40),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(color: colors.border),
                        boxShadow: colors.cardShadow,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: colors.secondary, shape: BoxShape.circle),
                              child: Icon(icon, size: 40, color: colors.primaryText),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(title,
                              textAlign: TextAlign.center,
                              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: colors.text)),
                          const SizedBox(height: 8),
                          Text(subtitle,
                              textAlign: TextAlign.center, style: textTheme.bodyMedium?.copyWith(color: colors.textMuted)),
                          const SizedBox(height: 32),
                          child,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: AppButton(
                  text: 'Voltar',
                  icon: Icons.arrow_back,
                  variant: ButtonVariant.text,
                  onPressed: () => _back(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
