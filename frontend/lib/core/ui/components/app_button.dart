import 'package:flutter/material.dart';

/// Botão reutilizável baseado no design MUI Minimal
/// 
/// Suporta múltiplas variantes, tamanhos e estados.
/// Pode ser facilmente exportado para outros projetos.
/// 
/// Exemplo de uso:
/// ```dart
/// AppButton(
///   text: 'Enviar',
///   onPressed: () {},
///   variant: ButtonVariant.contained,
///   size: ButtonSize.medium,
/// )
/// ```
class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  
  // Estilo e variante
  final ButtonVariant variant;
  final ButtonSize size;
  
  // Estados
  final bool isLoading;
  final bool fullWidth;
  
  // Ícones
  final IconData? icon;
  final IconData? endIcon;
  
  // Cores customizadas
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  
  // Customizações
  final double? borderRadius;
  final double? elevation;
  final double? borderWidth;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.contained,
    this.size = ButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = false,
    this.icon,
    this.endIcon,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderRadius,
    this.elevation,
    this.borderWidth,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final buttonChild = _buildChild(colorScheme);
    
    Widget button;
    
    switch (widget.variant) {
      case ButtonVariant.contained:
        button = _buildContainedButton(colorScheme, buttonChild);
        break;
      case ButtonVariant.outlined:
        button = _buildOutlinedButton(colorScheme, buttonChild);
        break;
      case ButtonVariant.text:
        button = _buildTextButton(colorScheme, buttonChild);
        break;
      case ButtonVariant.soft:
        button = _buildSoftButton(colorScheme, buttonChild);
        break;
    }

    if (widget.fullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: button,
    );
  }

  Widget _buildContainedButton(ColorScheme colorScheme, Widget child) {
    final backgroundColor = widget.backgroundColor ?? colorScheme.primary;
    final foregroundColor = widget.textColor ?? colorScheme.onPrimary;
    
    return ElevatedButton(
      onPressed: widget.isLoading ? null : _handleTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
        disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
        padding: _getPadding(),
        elevation: widget.elevation ?? 2,
        shadowColor: backgroundColor.withOpacity(0.24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 8),
        ),
        minimumSize: Size(64, _getHeight()),
      ),
      child: child,
    );
  }

  Widget _buildOutlinedButton(ColorScheme colorScheme, Widget child) {
    final borderColor = widget.borderColor ?? widget.backgroundColor ?? colorScheme.primary;
    final textColor = widget.textColor ?? widget.backgroundColor ?? colorScheme.primary;
    
    return OutlinedButton(
      onPressed: widget.isLoading ? null : _handleTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
        disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
        padding: _getPadding(),
        side: BorderSide(
          color: borderColor,
          width: widget.borderWidth ?? 1.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 8),
        ),
        minimumSize: Size(64, _getHeight()),
      ),
      child: child,
    );
  }

  Widget _buildTextButton(ColorScheme colorScheme, Widget child) {
    final textColor = widget.textColor ?? widget.backgroundColor ?? colorScheme.primary;
    
    return TextButton(
      onPressed: widget.isLoading ? null : _handleTap,
      style: TextButton.styleFrom(
        foregroundColor: textColor,
        disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
        padding: _getPadding(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 8),
        ),
        minimumSize: Size(64, _getHeight()),
      ),
      child: child,
    );
  }

  Widget _buildSoftButton(ColorScheme colorScheme, Widget child) {
    final baseColor = widget.backgroundColor ?? colorScheme.primary;
    final backgroundColor = baseColor.withOpacity(0.12);
    final textColor = widget.textColor ?? baseColor;
    
    return ElevatedButton(
      onPressed: widget.isLoading ? null : _handleTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        disabledBackgroundColor: colorScheme.onSurface.withOpacity(0.12),
        disabledForegroundColor: colorScheme.onSurface.withOpacity(0.38),
        padding: _getPadding(),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.borderRadius ?? 8),
        ),
        minimumSize: Size(64, _getHeight()),
      ),
      child: child,
    );
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case ButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 6);
      case ButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 30, vertical: 10);
      case ButtonSize.medium:
      default:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 10);
    }
  }

  double _getHeight() {
    switch (widget.size) {
      case ButtonSize.small:
        return 32;
      case ButtonSize.large:
        return 48;
      case ButtonSize.medium:
      default:
        return 40;
    }
  }

  double _getFontSize() {
    switch (widget.size) {
      case ButtonSize.small:
        return 11;
      case ButtonSize.large:
        return 12;
      case ButtonSize.medium:
      default:
        return 14;
    }
  }

  Widget _buildChild(ColorScheme colorScheme) {
    if (widget.isLoading) {
      return SizedBox(
        height: _getFontSize() + 4,
        width: _getFontSize() + 4,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.textColor ?? 
            (widget.variant == ButtonVariant.contained 
                ? colorScheme.onPrimary 
                : colorScheme.primary),
          ),
        ),
      );
    }

    final textWidget = Text(
      widget.text,
      style: TextStyle(
        fontSize: _getFontSize(),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );

    if (widget.icon == null && widget.endIcon == null) {
      return textWidget;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: _getFontSize() + 4),
          const SizedBox(width: 8),
        ],
        textWidget,
        if (widget.endIcon != null) ...[
          const SizedBox(width: 8),
          Icon(widget.endIcon, size: _getFontSize() + 4),
        ],
      ],
    );
  }
}

/// Variantes de estilo do botão
enum ButtonVariant {
  /// Botão preenchido (padrão)
  contained,
  
  /// Botão com borda
  outlined,
  
  /// Botão sem fundo
  text,
  
  /// Botão com fundo suave/transparente
  soft,
}

/// Tamanhos do botão
enum ButtonSize {
  small,
  medium,
  large,
}
