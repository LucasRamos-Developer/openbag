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
  final TextCapitalization textCapitalization;
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
  final Color? prefixTextColor;
  final Color? suffixTextColor;

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
    this.textCapitalization = TextCapitalization.none,
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
    this.prefixTextColor,
    this.suffixTextColor,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 0), // Sem padding, controlado externamente
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: TextFormField(
              focusNode: _focusNode,
              controller: widget.controller,
              initialValue: widget.initialValue,
              validator: (value) {
                final error = widget.validator?.call(value);
                // Atualiza o estado do erro
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _errorText != error) {
                    setState(() {
                      _errorText = error;
                    });
                  }
                });
                return error;
              },
              autovalidateMode: widget.autovalidateMode,
              keyboardType: widget.keyboardType,
              textCapitalization: widget.textCapitalization,
              obscureText: widget.obscureText,
              inputFormatters: widget.inputFormatters,
              maxLines: widget.obscureText ? 1 : widget.maxLines,
              minLines: widget.minLines,
              maxLength: widget.maxLength,
              enabled: widget.enabled,
              readOnly: widget.readOnly,
              autofocus: widget.autofocus,
              cursorColor: const Color(0xFF000000),
              onChanged: widget.onChanged,
              onFieldSubmitted: widget.onSubmitted,
              onTap: widget.onTap,
              onEditingComplete: widget.onEditingComplete,
              style: _getTextStyle(colorScheme),
              decoration: _buildDecoration(theme, colorScheme),
            ),
          ),
          // Helper text posicionado absolutamente
          if (widget.helperText != null && _errorText == null)
            Positioned(
              left: 0,
              top: 52, // Abaixo do input
              child: Text(
                widget.helperText!,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          // Error text posicionado absolutamente
          if (_errorText != null)
            Positioned(
              left: 0,
              top: 52, // Abaixo do input
              child: Text(
                _errorText!,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.error,
                ),
              ),
            ),
        ],
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
    final hasError = _errorText != null;
    
    return InputDecoration(
      labelText: widget.labelText,
      hintText: widget.hintText,
      helperText: null, // Não mostrar inline
      errorText: null, // Não mostrar inline
      prefixIcon: widget.prefixIcon,
      suffixIcon: widget.suffixIcon,
      prefixText: widget.prefixText,
      suffixText: widget.suffixText,
      
      // Estilos do prefix e suffix text
      prefixStyle: widget.prefixText != null
          ? TextStyle(
              fontSize: _getLabelSize(),
              color: widget.prefixTextColor ?? colorScheme.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w400,
            )
          : null,
      suffixStyle: widget.suffixText != null
          ? TextStyle(
              fontSize: _getLabelSize(),
              color: widget.suffixTextColor ?? colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w400,
            )
          : null,
      
      // Alinhar label no topo para textarea
      alignLabelWithHint: (widget.maxLines ?? 1) > 1,
      
      // Cores e preenchimento
      filled: widget.variant != TextFieldVariant.standard,
      fillColor: _getFillColor(colorScheme),
      
      // Estilo do label
      labelStyle: TextStyle(
        fontSize: 14,
        color: hasError 
            ? colorScheme.error 
            : (_isFocused ? const Color(0xFF000000) : colorScheme.onSurface.withOpacity(0.6)),
        fontWeight: _isFocused ? FontWeight.w600 : FontWeight.w400,
      ),
      
      // Estilo do hint
      hintStyle: TextStyle(
        fontSize: _getLabelSize(),
        color: colorScheme.onSurface.withOpacity(0.38),
        fontWeight: FontWeight.w400,
      ),
      
      // Helper text - oculto (será mostrado com Positioned)
      helperStyle: const TextStyle(
        fontSize: 0,
        height: 0,
      ),
      helperMaxLines: 1,
      
      // Error text - oculto (será mostrado com Positioned)
      errorStyle: const TextStyle(
        fontSize: 0,
        height: 0,
      ),
      errorMaxLines: 1,
      
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
        borderColor = widget.focusedBorderColor ?? const Color(0xFF000000);
        borderWidth = 1.0;
        break;
      case BorderType.error:
        borderColor = widget.errorBorderColor ?? colorScheme.error;
        borderWidth = 1.0;
        break;
      case BorderType.focusedError:
        borderColor = widget.errorBorderColor ?? colorScheme.error;
        borderWidth = 1.0;
        break;
      case BorderType.disabled:
        borderColor = colorScheme.outline.withOpacity(0.12);
        borderWidth = 1.0;
        break;
      case BorderType.enabled:
      case BorderType.normal:
      default:
        borderColor = widget.borderColor ?? const Color(0xFFDFE3E8);
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
            color: borderColor,
            width: borderWidth,
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
