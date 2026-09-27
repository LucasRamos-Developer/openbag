import 'package:flutter/material.dart';
import 'app_card.dart';
import 'app_section_header.dart';

/// Card de bloco de configuração dos painéis: título, subtítulo opcional e conteúdo
class AppPanelCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget child;

  const AppPanelCard({super.key, required this.title, this.subtitle, this.action, required this.child});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      borderColor: Theme.of(context).colorScheme.outline,
      borderWidth: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(title: title, subtitle: subtitle, action: action),
          child,
        ],
      ),
    );
  }
}
