import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';

/// Atualiza o filho a cada segundo (base dos cronômetros)
class _Ticker extends StatefulWidget {
  final Widget Function(BuildContext context, DateTime now) builder;

  const _Ticker({required this.builder});

  @override
  State<_Ticker> createState() => _TickerState();
}

class _TickerState extends State<_Ticker> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, DateTime.now());
}

/// Tempo desde [since] ("12 min"), amarelo a partir de [warnAfter] e vermelho a partir de [dangerAfter]
class ElapsedTimer extends StatelessWidget {
  final DateTime since;
  final Duration? warnAfter;
  final Duration? dangerAfter;
  final TextStyle? style;

  const ElapsedTimer({super.key, required this.since, this.warnAfter, this.dangerAfter, this.style});

  static String format(Duration elapsed) {
    if (elapsed.inMinutes < 1) return 'agora';
    if (elapsed.inHours < 1) return '${elapsed.inMinutes} min';
    return '${elapsed.inHours}h${(elapsed.inMinutes % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => _Ticker(builder: (context, now) {
        final elapsed = now.difference(since);
        Color? color;
        if (dangerAfter != null && elapsed >= dangerAfter!) {
          color = AppColors.errorDark;
        } else if (warnAfter != null && elapsed >= warnAfter!) {
          color = AppColors.warningDarker;
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: (style?.fontSize ?? 14) + 2, color: color ?? style?.color),
            const SizedBox(width: 4),
            Text(format(elapsed), style: (style ?? const TextStyle()).copyWith(color: color, fontWeight: FontWeight.w600)),
          ],
        );
      });
}

/// Contagem regressiva até [deadline] ("Aceite em 07:42"); vermelho no último [urgentWithin]
class DeadlineCountdown extends StatelessWidget {
  final DateTime deadline;
  final String label;
  final Duration urgentWithin;

  const DeadlineCountdown({
    super.key,
    required this.deadline,
    this.label = 'Aceite em',
    this.urgentWithin = const Duration(minutes: 2),
  });

  @override
  Widget build(BuildContext context) => _Ticker(builder: (context, now) {
        final left = deadline.difference(now);
        if (left.isNegative) {
          return const Text('Prazo esgotado', style: TextStyle(color: AppColors.errorDark, fontWeight: FontWeight.w700));
        }
        final mm = left.inMinutes.toString().padLeft(2, '0');
        final ss = (left.inSeconds % 60).toString().padLeft(2, '0');
        return Text(
          '$label $mm:$ss',
          style: TextStyle(
            color: left <= urgentWithin ? AppColors.errorDark : AppColors.warningDarker,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      });
}
