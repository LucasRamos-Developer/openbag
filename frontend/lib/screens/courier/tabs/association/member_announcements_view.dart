import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/ui/ui.dart';
import '../../../../models/cooperative/announcement.dart';
import '../../../../services/member_area_service.dart';
import '../../../../widgets/cooperative/announcement_card.dart';

/// Mural da associação para o cooperado: os não lidos aparecem fechados, com o selo "Novo"; um toque abre o texto
/// inteiro e marca como lido (é o que tira o aviso do resumo).
class MemberAnnouncementsView extends StatefulWidget {
  const MemberAnnouncementsView({super.key});

  @override
  State<MemberAnnouncementsView> createState() => _MemberAnnouncementsViewState();
}

class _MemberAnnouncementsViewState extends State<MemberAnnouncementsView> {
  // Lidos nesta tela (o servidor já registrou); evita recarregar a lista a cada toque
  final Set<int> _readNow = {};

  Future<void> _open(Announcement announcement) async {
    if (announcement.read || _readNow.contains(announcement.id)) return;
    setState(() => _readNow.add(announcement.id));
    try {
      await context.read<MemberAreaService>().markAnnouncementRead(announcement.id);
    } catch (_) {
      // Sem rede: o texto já está aberto; a leitura fica para a próxima vez
      if (mounted) setState(() => _readNow.remove(announcement.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<MemberAreaService>();
    return AppLoadView<List<Announcement>>(
      load: service.fetchAnnouncements,
      builder: (context, announcements, reload) => AppPageListView(
        top: 8,
        maxWidth: 720,
        children: [
          if (announcements.isEmpty)
            const AppEmptyState(icon: Icons.campaign_outlined, message: 'Nenhum comunicado da associação por enquanto.'),
          for (final a in announcements) ...[
            Builder(builder: (context) {
              final read = a.read || _readNow.contains(a.id);
              return AnnouncementCard(
                announcement: read
                    ? Announcement(
                        id: a.id, type: a.type, title: a.title, body: a.body, eventAt: a.eventAt,
                        publishedAt: a.publishedAt, read: true)
                    : a,
                collapsed: !read,
                onTap: read ? null : () => _open(a),
              );
            }),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
