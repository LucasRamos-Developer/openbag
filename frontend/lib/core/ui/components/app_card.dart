import 'package:flutter/material.dart';

/// Card/Container reutilizável baseado no design MUI Minimal
/// 
/// Suporta diferentes estilos de sombra, bordas e elevações.
/// Pode ser facilmente exportado para outros projetos.
/// 
/// Exemplo de uso:
/// ```dart
/// AppCard(
///   child: Text('Conteúdo'),
///   elevation: 2,
///   borderRadius: 12,
/// )
/// ```
class AppCard extends StatelessWidget {
  final Widget child;
  
  // Espaçamento
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  
  // Estilo
  final Color? backgroundColor;
  final double borderRadius;
  final double elevation;
  
  // Borda
  final Color? borderColor;
  final double? borderWidth;
  
  // Gradiente
  final Gradient? gradient;
  
  // Interação
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  
  // Tamanho
  final double? width;
  final double? height;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius = 16,
    this.elevation = 0,
    this.borderColor,
    this.borderWidth,
    this.gradient,
    this.onTap,
    this.onLongPress,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    Widget container = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? (backgroundColor ?? colorScheme.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderColor != null
            ? Border.all(
                color: borderColor!,
                width: borderWidth ?? 1,
              )
            : null,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(_getShadowOpacity()),
                  blurRadius: elevation * 4,
                  offset: Offset(0, elevation / 2),
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (onTap != null || onLongPress != null) {
      container = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(borderRadius),
          child: container,
        ),
      );
    }

    return container;
  }

  double _getShadowOpacity() {
    if (elevation <= 1) return 0.05;
    if (elevation <= 2) return 0.08;
    if (elevation <= 4) return 0.12;
    return 0.16;
  }
}

/// Card com variante específica para paper/surface
class AppPaper extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final PaperVariant variant;
  final double borderRadius;

  const AppPaper({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.variant = PaperVariant.elevation,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    switch (variant) {
      case PaperVariant.elevation:
        return AppCard(
          padding: padding,
          margin: margin,
          borderRadius: borderRadius,
          elevation: 2,
          child: child,
        );
      
      case PaperVariant.outlined:
        return AppCard(
          padding: padding,
          margin: margin,
          borderRadius: borderRadius,
          elevation: 0,
          borderColor: colorScheme.outline.withOpacity(0.23),
          borderWidth: 1,
          child: child,
        );
      
      case PaperVariant.filled:
        return AppCard(
          padding: padding,
          margin: margin,
          borderRadius: borderRadius,
          elevation: 0,
          backgroundColor: colorScheme.surfaceVariant.withOpacity(0.5),
          child: child,
        );
    }
  }
}

/// Variantes de Paper
enum PaperVariant {
  /// Com sombra (elevation)
  elevation,
  
  /// Com borda
  outlined,
  
  /// Com fundo preenchido
  filled,
}
