import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';

/// Esqueleto da página do restaurante enquanto os dados carregam
class RestaurantPageSkeleton extends StatelessWidget {
  const RestaurantPageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton.group(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSkeleton(height: 200, radius: AppRadius.xl),
                  const SizedBox(height: 16),
                  const AppSkeleton(height: 120, radius: AppRadius.lg),
                  const SizedBox(height: 20),
                  const AppSkeleton(height: 52, radius: AppRadius.pill),
                  const SizedBox(height: 16),
                  Row(
                    children: List.generate(
                      4,
                      (_) => const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: AppSkeleton(width: 120, height: 44, radius: AppRadius.pill),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const AppSkeleton(width: 200, height: 28),
                  const SizedBox(height: 16),
                  for (var i = 0; i < 3; i++) ...[
                    const AppSkeleton(height: 118, radius: AppRadius.lg),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
