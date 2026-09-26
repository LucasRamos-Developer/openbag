import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

/// Alerta sonoro de pedido novo: toca em repetição enquanto houver pedido aguardando aceite.
/// No navegador o áudio só é liberado depois de uma interação do usuário ([unlock]).
class AlertSound {
  final AudioPlayer _player = AudioPlayer();
  Timer? _loop;
  bool _unlocked = false;

  bool get unlocked => _unlocked;
  bool get ringing => _loop != null;

  /// Chamar a partir de um toque do usuário (ex: botão "Ativar alertas sonoros")
  Future<void> unlock() async {
    _unlocked = true;
    await _play();
  }

  /// Toca uma vez (ex: pedido que entrou já confirmado)
  Future<void> chime() => _play();

  void startRinging() {
    if (_loop != null) return;
    _play();
    _loop = Timer.periodic(const Duration(seconds: 4), (_) => _play());
  }

  void stopRinging() {
    _loop?.cancel();
    _loop = null;
  }

  Future<void> _play() async {
    if (!_unlocked) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/new_order.wav'));
    } catch (_) {
      // Sem permissão de áudio no navegador: o destaque visual continua
    }
  }

  void dispose() {
    stopRinging();
    _player.dispose();
  }
}
