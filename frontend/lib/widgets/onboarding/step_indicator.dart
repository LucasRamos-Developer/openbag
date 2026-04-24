import 'package:flutter/material.dart';

/// Widget que exibe um indicador visual do progresso entre os steps
class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps * 2 - 1, (index) {
        if (index.isOdd) {
          // Connector
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex < currentStep;
          return _buildConnector(context, isCompleted: isCompleted);
        } else {
          // Step circle
          final stepIndex = index ~/ 2;
          final stepNumber = stepIndex + 1;
          final isActive = stepNumber == currentStep + 1;
          final isCompleted = stepNumber < currentStep + 1;
          
          return _buildStepCircle(
            context,
            stepNumber: stepNumber,
            isActive: isActive,
            isCompleted: isCompleted,
          );
        }
      }),
    );
  }

  Widget _buildStepCircle(
    BuildContext context, {
    required int stepNumber,
    required bool isActive,
    required bool isCompleted,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color backgroundColor;
    final Color textColor;

    if (isCompleted || isActive) {
      backgroundColor = colorScheme.primary;
      textColor = colorScheme.onPrimary;
    } else {
      backgroundColor = colorScheme.surfaceVariant.withOpacity(0.3);
      textColor = colorScheme.onSurface.withOpacity(0.38);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          stepNumber.toString(),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildConnector(BuildContext context, {required bool isCompleted}) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: 48,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isCompleted
            ? colorScheme.primary
            : colorScheme.outline.withOpacity(0.2),
      ),
    );
  }
}
