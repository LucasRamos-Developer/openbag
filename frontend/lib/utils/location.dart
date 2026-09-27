import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../core/ui/ui.dart';

/// Coordenadas atuais do aparelho, pedindo permissão se preciso.
/// Retorna null (e avisa o usuário) quando o serviço está desligado ou a permissão foi negada.
Future<Position?> currentPosition(BuildContext context) async {
  void warn(String message, ToastType type) {
    if (context.mounted) AppToast.show(context, message: message, type: type);
  }

  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      warn('Serviço de localização desabilitado. Ative nas configurações do navegador.', ToastType.warning);
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        warn('Permissão de localização negada', ToastType.error);
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      warn('Permissão de localização permanentemente negada. Ative nas configurações.', ToastType.error);
      return null;
    }

    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  } catch (e) {
    warn('Erro ao obter localização: $e', ToastType.error);
    return null;
  }
}
