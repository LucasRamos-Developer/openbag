import 'dart:async';
import 'package:flutter/material.dart';

/// Contagem regressiva até [until] com barra de progresso; chama [onFinished] ao chegar a zero
class AppCountdown extends StatefulWidget {
  final DateTime until;
  final Duration total;
  final VoidCallback? onFinished;
  final Color? color;

  const AppCountdown({super.key, required this.until, required this.total, this.onFinished, this.color});

  @override
  State<AppCountdown> createState() => _AppCountdownState();
}

class _AppCountdownState extends State<AppCountdown> {
  Timer? _timer;
  bool _finished = false;

  Duration get _left {
    final left = widget.until.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      setState(() {});
      if (_left == Duration.zero && !_finished) {
        _finished = true;
        widget.onFinished?.call();
      }
    });
  }

  @override
  void didUpdateWidget(covariant AppCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.until != widget.until) _finished = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final totalMs = widget.total.inMilliseconds;
    final progress = totalMs <= 0 ? 0.0 : (_left.inMilliseconds / totalMs).clamp(0.0, 1.0);
    final seconds = (_left.inMilliseconds / 1000).ceil();

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(seconds >= 60 ? '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}' : '${seconds}s', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontFeatures: const [FontFeature.tabularFigures()])),
      ],
    );
  }
}
