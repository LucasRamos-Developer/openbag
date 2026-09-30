import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/order/order_incident.dart';

/// Ocorrência escolhida: o tipo e, em "outro problema", o que aconteceu
typedef IncidentReport = ({IncidentType type, String? note});

/// "Relatar problema" na entrega em andamento: um toque por tipo. No celular abre em tela cheia.
/// Os tipos já avisados aparecem marcados; "outro problema" pede uma observação e pode ser enviado de novo.
Future<IncidentReport?> showReportIncidentSheet(BuildContext context, {required Set<IncidentType> reported}) =>
    showAppAdaptive<IncidentReport>(context, builder: (_) => _ReportIncidentSheet(reported: reported));

class _ReportIncidentSheet extends StatelessWidget {
  final Set<IncidentType> reported;

  const _ReportIncidentSheet({required this.reported});

  Future<void> _choose(BuildContext context, IncidentType type) async {
    String? note;
    if (type == IncidentType.OTHER) {
      note = await AppDialog.reason(
        context,
        title: 'O que aconteceu?',
        message: 'Conte em poucas palavras. A loja vê na hora.',
        confirmLabel: 'Avisar a loja',
        required: true,
        maxLength: 300,
      );
      if (note == null || !context.mounted) return;
    }
    Navigator.of(context).pop<IncidentReport>((type: type, note: note));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppAdaptiveSheet(
      title: 'Relatar problema',
      subtitle: 'A loja vê na hora',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Isso não vira nota nem conta contra você: serve para a loja agir e para a cooperativa '
              'conversar com as lojas.',
              style: TextStyle(color: colors.textMuted)),
          const SizedBox(height: 12),
          for (final type in IncidentType.values)
            _IncidentTile(
              type: type,
              done: type != IncidentType.OTHER && reported.contains(type),
              onTap: () => _choose(context, type),
            ),
        ],
      ),
    );
  }
}

class _IncidentTile extends StatelessWidget {
  final IncidentType type;
  final bool done;
  final VoidCallback onTap;

  const _IncidentTile({required this.type, required this.done, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: done ? null : onTap,
        child: ListTile(
          minTileHeight: 56,
          leading: Icon(type.icon, color: done ? colors.textMuted : colors.primaryText),
          title: Text(type.label, style: TextStyle(fontWeight: FontWeight.w600, color: done ? colors.textMuted : colors.text)),
          subtitle: done ? Text('A loja já foi avisada', style: TextStyle(color: colors.textMuted)) : null,
          trailing: Icon(done ? Icons.check_circle : Icons.chevron_right,
              color: done ? colors.success : colors.textMuted),
        ),
      ),
    );
  }
}
