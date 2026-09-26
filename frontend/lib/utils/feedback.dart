import 'package:flutter/material.dart';
import '../core/ui/ui.dart';
import '../services/api_client.dart';

/// Executa uma ação da API e dá o retorno ao usuário: toast de sucesso (opcional)
/// ou a mensagem de erro do backend
Future<bool> runWithFeedback(BuildContext context, Future<void> Function() action, {String? success}) async {
  try {
    await action();
    if (success != null && context.mounted) {
      AppToast.show(context, message: success, type: ToastType.success);
    }
    return true;
  } on ApiException catch (e) {
    if (context.mounted) {
      AppToast.show(context, message: e.message, type: ToastType.error, duration: const Duration(seconds: 6));
    }
    return false;
  }
}
