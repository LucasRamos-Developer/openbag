import 'package:flutter/material.dart';
import 'app_button.dart';
import 'app_text_field.dart';

/// Diálogos padrão do app
class AppDialog {
  AppDialog._();

  /// Confirmação simples. Retorna true se o usuário confirmar.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    String cancelLabel = 'Cancelar',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          AppButton(text: cancelLabel, variant: ButtonVariant.text, onPressed: () => Navigator.of(context).pop(false)),
          AppButton(text: confirmLabel, onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );
    return result ?? false;
  }

  /// Confirma uma ação pedindo um motivo (opcional ou obrigatório).
  /// Retorna o motivo digitado (vazio se opcional e não preenchido) ou null se cancelado.
  static Future<String?> reason(
    BuildContext context, {
    required String title,
    required String confirmLabel,
    String? message,
    bool required = false,
    int maxLength = 500,
  }) {
    return showDialog<String>(
      context: context,
      builder: (context) => _ReasonDialog(
        title: title,
        confirmLabel: confirmLabel,
        message: message,
        required: required,
        maxLength: maxLength,
      ),
    );
  }
}

class _ReasonDialog extends StatefulWidget {
  final String title;
  final String confirmLabel;
  final String? message;
  final bool required;
  final int maxLength;

  const _ReasonDialog({
    required this.title,
    required this.confirmLabel,
    required this.message,
    required this.required,
    required this.maxLength,
  });

  @override
  State<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<_ReasonDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.message != null) ...[Text(widget.message!), const SizedBox(height: 16)],
              AppTextField(
                controller: _controller,
                labelText: widget.required ? 'Motivo' : 'Motivo (opcional)',
                maxLines: 3,
                maxLength: widget.maxLength,
                variant: TextFieldVariant.filled,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) =>
                    widget.required && (value == null || value.trim().isEmpty) ? 'Informe o motivo' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        AppButton(text: 'Cancelar', variant: ButtonVariant.text, onPressed: () => Navigator.of(context).pop()),
        AppButton(
          text: widget.confirmLabel,
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
        ),
      ],
    );
  }
}
