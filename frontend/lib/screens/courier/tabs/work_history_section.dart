import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../models/courier/courier_earnings.dart';
import '../../../models/courier/courier_work.dart' show ShiftMode;
import '../../../services/api_client.dart';
import '../../../services/courier_service.dart';
import '../../../utils/formatters.dart';
import '../../../widgets/courier/work_history_list.dart';

/// Onde o entregador trabalhou: restaurantes (com entregas) e turnos recentes. Seção da aba Lojas.
class WorkHistorySection extends StatefulWidget {
  const WorkHistorySection({super.key});

  @override
  State<WorkHistorySection> createState() => WorkHistorySectionState();
}

class WorkHistorySectionState extends State<WorkHistorySection> {
  WorkHistory? _history;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => refresh());
  }

  Future<void> refresh() async {
    try {
      final history = await context.read<CourierService>().fetchHistory();
      if (mounted) setState(() => _history = history);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = _history;
    final textTheme = Theme.of(context).textTheme;
    if (history == null) {
      return _error != null
          ? AppEmptyState(icon: Icons.cloud_off_outlined, message: _error!, actionLabel: 'Tentar novamente', onAction: refresh)
          : const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionHeader(
          title: 'Onde trabalhei',
          subtitle: 'Restaurantes em que você fez entregas. No perfil, você escolhe se isso aparece no perfil público.',
        ),
        if (history.restaurants.isEmpty)
          Text('Suas entregas concluídas aparecem aqui.', style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary))
        else
          WorkHistoryList(restaurants: history.restaurants),
        const SizedBox(height: 24),
        const AppSectionHeader(title: 'Turnos recentes'),
        if (history.recentShifts.isEmpty)
          Text('Nenhum turno ainda.', style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary))
        else
          for (final s in history.recentShifts)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(s.mode == ShiftMode.FIXED ? Icons.storefront : Icons.explore_outlined),
              title: Text(s.mode == ShiftMode.FIXED ? 'Fixo em ${s.restaurantName ?? 'restaurante'}' : 'Modo livre'),
              subtitle: Text('${formatDateTime(s.startedAt)}'
                  '${s.endedAt != null ? ' até ${formatTime(s.endedAt)}' : ' · em andamento'}'),
              trailing: Text('${s.deliveries} ${s.deliveries == 1 ? 'entrega' : 'entregas'}'),
            ),
      ],
    );
  }
}
