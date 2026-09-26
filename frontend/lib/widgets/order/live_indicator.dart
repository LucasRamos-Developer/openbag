import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';

/// Situação da conexão em tempo real: "Ao vivo" ou "Reconectando…"
class LiveIndicator extends StatelessWidget {
  final bool connected;
  final Color? textColor;

  const LiveIndicator({super.key, required this.connected, this.textColor});

  @override
  Widget build(BuildContext context) {
    final color = connected ? AppColors.success : AppColors.warningDark;
    return Tooltip(
      message: connected
          ? 'Pedidos chegam na hora, sem recarregar'
          : 'Sem conexão em tempo real. Tentando reconectar; os pedidos serão sincronizados ao voltar.',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(connected ? 'Ao vivo' : 'Reconectando…',
              style: TextStyle(color: textColor ?? color, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
