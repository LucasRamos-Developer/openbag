import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/order/order.dart';
import '../../utils/formatters.dart';

/// Ocorrências do pedido para a loja: uma linha no card ([compact]) ou a lista com quem relatou e quando
class OrderIncidents extends StatelessWidget {
  final List<OrderIncident> incidents;
  final bool compact;

  const OrderIncidents({super.key, required this.incidents, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (incidents.isEmpty) return const SizedBox.shrink();
    if (compact) {
      final last = incidents.last;
      final more = incidents.length > 1 ? ' (+${incidents.length - 1})' : '';
      return Row(
        children: [
          const Icon(Icons.report_problem_outlined, size: 14, color: AppColors.warningDarker),
          const SizedBox(width: 4),
          Expanded(
            child: Text('${last.title}$more',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.warningDarker, fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      );
    }

    final muted = context.appColors.textMuted;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningLighter.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < incidents.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(incidents[i].type.icon, size: 20, color: AppColors.warningDarker),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(incidents[i].type.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                      if (incidents[i].type == IncidentType.OTHER && incidents[i].note != null) Text(incidents[i].note!),
                      Text(
                        [
                          if (incidents[i].reportedBy != null) incidents[i].reportedBy!,
                          if (incidents[i].at != null) 'às ${formatTime(incidents[i].at)}',
                        ].join(' · '),
                        style: TextStyle(color: muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
