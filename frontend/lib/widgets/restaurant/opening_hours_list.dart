import 'package:flutter/material.dart';
import '../../models/store/store.dart';

/// Horários de funcionamento (somente leitura), com o dia de hoje destacado
class OpeningHoursList extends StatelessWidget {
  final List<OpeningHour> hours;

  const OpeningHoursList({super.key, required this.hours});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().weekday;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);

    if (hours.isEmpty) {
      return Text('Horários não informados', style: TextStyle(color: muted));
    }

    return Column(
      children: [
        for (var day = 1; day <= 7; day++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: DefaultTextStyle.merge(
              style: TextStyle(fontWeight: day == today ? FontWeight.w700 : FontWeight.normal),
              child: Row(
                children: [
                  SizedBox(width: 90, child: Text(OpeningHour.weekdayNames[day - 1])),
                  Expanded(
                    child: Text(
                      () {
                        final shifts = hours.where((h) => h.weekday == day).toList()
                          ..sort((a, b) => a.openTime.compareTo(b.openTime));
                        if (shifts.isEmpty) return 'Fechado';
                        return shifts.map((s) => '${s.openTime} – ${s.closeTime}').join('  ·  ');
                      }(),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
