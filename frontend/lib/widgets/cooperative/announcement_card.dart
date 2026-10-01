import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/cooperative/announcement.dart';
import '../../utils/formatters.dart';

/// Comunicado no mural: tipo, título, data do evento e texto. Para o gestor, quantos leram e as ações; para o
/// cooperado, o selo "Novo" até ler. Com [collapsed], mostra só o começo do texto (toque abre e marca como lido).
class AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final bool manager;
  final bool collapsed;
  final VoidCallback? onTap;
  final List<Widget> actions;

  const AnnouncementCard({
    super.key,
    required this.announcement,
    this.manager = false,
    this.collapsed = false,
    this.onTap,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final a = announcement;
    final unread = !manager && !a.read;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      borderColor: unread ? c.primary.withValues(alpha: 0.45) : null,
      borderWidth: unread ? 1.5 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(a.type.icon, size: 18, color: c.primaryText),
                  const SizedBox(width: 6),
                  Text(a.type.label, style: TextStyle(color: c.primaryText, fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
              if (unread) const AppStatusChip(label: 'Novo', color: AppColors.primaryDark),
              if (a.archived) const AppStatusChip(label: 'Arquivado', color: AppColors.grey600),
            ],
          ),
          const SizedBox(height: 8),
          Text(a.title, style: TextStyle(color: c.text, fontSize: 17, fontWeight: FontWeight.w800)),
          if (a.eventAt != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.event_outlined, size: 16, color: c.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('${formatDate(a.eventAt)} às ${formatTime(a.eventAt)}',
                      style: TextStyle(color: c.text, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(a.body,
              maxLines: collapsed ? 3 : null,
              overflow: collapsed ? TextOverflow.ellipsis : null,
              style: TextStyle(color: c.text, height: 1.35)),
          const SizedBox(height: 8),
          Text(
            [
              if (a.publishedAt != null) 'Publicado em ${formatDate(a.publishedAt)}',
              if (manager && a.memberCount != null) 'lido por ${a.readCount ?? 0} de ${a.memberCount}',
              if (collapsed) 'toque para ler',
            ].join(' · '),
            style: TextStyle(color: c.textMuted, fontSize: 12),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: actions),
          ],
        ],
      ),
    );
  }
}
