import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/restaurant.dart';

/// Situação da loja em uma frase: "Aberto · fecha às 23:00", "Fechado · abre amanhã às 11:00",
/// "Pausado · volta às 20:15". Usa cores de status, nunca a cor da marca.
class RestaurantHoursLabel extends StatelessWidget {
  final Restaurant restaurant;
  final double fontSize;

  const RestaurantHoursLabel({super.key, required this.restaurant, this.fontSize = 13});

  static const _weekdays = ['seg.', 'ter.', 'qua.', 'qui.', 'sex.', 'sáb.', 'dom.'];

  static String _time(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// "às 18:00" (hoje), "amanhã às 11:00", "qua. às 11:00". Com [soon], a madrugada seguinte
  /// também vira só "às 02:00" (fechamento de um turno que vira a noite).
  static String _when(DateTime at, DateTime now, {bool soon = false}) {
    final days = DateTime(at.year, at.month, at.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (days == 0 || (soon && days == 1 && at.difference(now) < const Duration(hours: 12))) {
      return 'às ${_time(at)}';
    }
    return '${days == 1 ? 'amanhã' : _weekdays[at.weekday - 1]} às ${_time(at)}';
  }

  /// Título curto (Aberto/Pausado/Fechado) e o complemento com horário, se houver
  static (String, String?) textOf(Restaurant restaurant, [DateTime? now]) {
    now ??= DateTime.now();
    if (restaurant.openNow) {
      final closesAt = restaurant.closesAt;
      return ('Aberto', closesAt != null ? 'fecha ${_when(closesAt, now, soon: true)}' : null);
    }
    final next = restaurant.nextOpenAt;
    if (restaurant.paused) {
      return ('Pausado', next != null ? 'volta ${_when(next, now, soon: true)}' : null);
    }
    return ('Fechado', next != null ? 'abre ${_when(next, now)}' : null);
  }

  static Color colorOf(BuildContext context, Restaurant restaurant) {
    final c = context.appColors;
    if (restaurant.openNow) return c.success;
    return restaurant.paused ? AppColors.warningDarker : c.danger;
  }

  @override
  Widget build(BuildContext context) {
    final (title, detail) = textOf(restaurant);
    final color = colorOf(context, restaurant);
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Flexible(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: title, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
              if (detail != null) TextSpan(text: ' · $detail', style: TextStyle(color: context.appColors.textMuted)),
            ]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: fontSize),
          ),
        ),
      ],
    );
  }
}
