import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// TextField reutilizável baseado no design MUI Minimal
/// 
/// Suporta múltiplas variantes, tamanhos e estados.
/// Pode ser facilmente exportado para outros projetos.
/// 
/// Exemplo de uso:
/// ```dart
/// AppTextField(
///   labelText: 'Email',
///   hintText: 'seu@email.com',
///   variant: TextFieldVariant.outlined,
///   size: TextFieldSize.medium,
/// )
/// ```
class AppTextField extends StatefulWidget {
  // Controllers e dados
  final TextEditingController? controller;
  final String? initialValue;
  
  // Labels e textos
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  
  // Validação
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;
  
  // Estilo e variante
  final TextFieldVariant variant;
  final TextFieldSize size;
  
  // Tipo de input
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  
  // Formatters
  final List<TextInputFormatter>? inputFormatters;
  
  // Ícones e adornos
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final String? suffixText;
  
  // Estados
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  
  // Callbacks
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final VoidCallback? onTap;
  final void Function()? onEditingComplete;
  
  // Cores customizadas
  final Color? fillColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? errorBorderColor;

  const AppTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.validator,
    this.autovalidateMode,
    this.variant = TextFieldVariant.outlined,
    this.size = TextFieldSize.medium,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onEditingComplete,
    this.fillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() => _isFocused = hasFocus);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          validator: widget.validator,
          autovalidateMode: widget.autovalidateMode,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscureText,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          minLines: widget.minLines,
          maxLength: widget.maxLength,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          autofocus: widget.autofocus,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          onTap: widget.onTap,
          onEditingComplete: widget.onEditingComplete,
          style: _getTextStyle(colorScheme),
          decoration: _buildDecoration(theme, colorScheme),
        ),
      ),
    );
  }

  TextStyle _getTextStyle(ColorScheme colorScheme) {
    double fontSize;
    
    switch (widget.size) {
      case TextFieldSize.small:
        fontSize = 14;
        break;
      case TextFieldSize.large:
        fontSize = 16;
        break;
      case TextFieldSize.medium:
      default:
        fontSize = 15;
    }

    return TextStyle(
      color: widget.enabled ? colorScheme.onSurface : colorScheme.onSurface.withOpacity(0.38),
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
    );
  }

  InputDecoration _buildDecoration(ThemeData theme, ColorScheme colorScheme) {
    final hasError = widget.errorText != null;
    
    return InputDecoration(
      labelText: widget.labelText,
      hintText: widget.hintText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      prefixIcon: widget.prefixIcon,
      suffixIcon: widget.suffixIcon,
      prefixText: widget.prefixText,
      suffixText: widget.suffixText,
      
      // Cores e preenchimento
      filled: widget.variant != TextFieldVariant.standard,
      fillColor: _getFillColor(colorScheme),
      
      // Estilo do label
      labelStyle: TextStyle(
        fontSize: 14,
        color: hasError 
            ? colorScheme.error 
            : (_isFocused ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.6)),
        fontWeight: FontWeight.w400,
      ),
      
      // Estilo do hint
      hintStyle: TextStyle(
        fontSize: _getLabelSize(),
        color: colorScheme.onSurface.withOpacity(0.38),
        fontWeight: FontWeight.w400,
      ),
      
      // Helper text
      helperStyle: TextStyle(
        fontSize: 12,
        color: colorScheme.onSurface.withOpacity(0.6),
      ),
      
      // Error text
      errorStyle: TextStyle(
        fontSize: 12,
        color: colorScheme.error,
      ),
      
      // Padding
      contentPadding: _getContentPadding(),
      
      // Bordas baseadas na variante
      border: _buildBorder(colorScheme, BorderType.normal),
      enabledBorder: _buildBorder(colorScheme, BorderType.enabled),
      focusedBorder: _buildBorder(colorScheme, BorderType.focused),
      errorBorder: _buildBorder(colorScheme, BorderType.error),
      focusedErrorBorder: _buildBorder(colorScheme, BorderType.focusedError),
      disabledBorder: _buildBorder(colorScheme, BorderType.disabled),
    );
  }

  double _getLabelSize() {
    switch (widget.size) {
      case TextFieldSize.small:
        return 13;
      case TextFieldSize.large:
        return 15;
      case TextFieldSize.medium:
      default:
        return 14;
    }
  }

  Color _getFillColor(ColorScheme colorScheme) {
    if (!widget.enabled) {
      return colorScheme.surfaceVariant.withOpacity(0.3);
    }
    
    if (widget.fillColor != null) {
      return widget.fillColor!;
    }
    
    switch (widget.variant) {
      case TextFieldVariant.filled:
        return colorScheme.surfaceVariant.withOpacity(0.06);
      case TextFieldVariant.outlined:
        return colorScheme.surface;
      case TextFieldVariant.standard:
        return Colors.transparent;
    }
  }

  EdgeInsets _getContentPadding() {
    switch (widget.size) {
      case TextFieldSize.small:
        return const EdgeInsets.symmetric(horizontal: 14, vertical: 10);
      case TextFieldSize.large:
        return const EdgeInsets.symmetric(horizontal: 18, vertical: 18);
      case TextFieldSize.medium:
      default:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 14);
    }
  }

  InputBorder _buildBorder(ColorScheme colorScheme, BorderType type) {
    final hasError = widget.errorText != null;
    Color borderColor;
    double borderWidth;

    // Determinar cor da borda
    switch (type) {
      case BorderType.focused:
        borderColor = widget.focusedBorderColor ?? colorScheme.primary;
        borderWidth = 2.0;
        break;
      case BorderType.error:
        borderColor = widget.errorBorderColor ?? colorScheme.error;
        borderWidth = 1.5;
        break;
      case BorderType.focusedError:
        borderColor = widget.errorBorderColor ?? colorScheme.error;
        borderWidth = 2.0;
        break;
      case BorderType.disabled:
        borderColor = colorScheme.outline.withOpacity(0.12);
        borderWidth = 1.0;
        break;
      case BorderType.enabled:
      case BorderType.normal:
      default:
        borderColor = widget.borderColor ?? colorScheme.outline.withOpacity(0.23);
        borderWidth = 1.0;
    }

    // Retornar borda baseada na variante
    switch (widget.variant) {
      case TextFieldVariant.outlined:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: borderColor,
            width: borderWidth,
          ),
        );
      
      case TextFieldVariant.filled:
        return OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: type == BorderType.error || type == BorderType.focusedError
                ? borderColor
                : type == BorderType.focused
                    ? borderColor
                    : colorScheme.outline.withOpacity(0.2),
            width: type == BorderType.focused || type == BorderType.focusedError ? 2 : 1,
          ),
        );
      
      case TextFieldVariant.standard:
        return UnderlineInputBorder(
          borderSide: BorderSide(
            color: borderColor,
            width: borderWidth,
          ),
        );
    }
  }
}

/// Variantes de estilo do TextField
enum TextFieldVariant {
  /// Borda ao redor (padrão MUI)
  outlined,
  
  /// Fundo preenchido com borda inferior
  filled,
  
  /// Apenas linha inferior
  standard,
}

/// Tamanhos do TextField
enum TextFieldSize {
  small,
  medium,
  large,
}

/// Tipos de borda para diferentes estados
enum BorderType {
  normal,
  enabled,
  focused,
  error,
  focusedError,
  disabled,
}
