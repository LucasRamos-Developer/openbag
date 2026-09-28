import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/cooperative/community.dart';
import '../../utils/formatters.dart';

/// Documento da associação (ata, estatuto...) com o botão de baixar e ações extras opcionais
class DocumentTile extends StatelessWidget {
  final AssociationDocument document;
  final VoidCallback onDownload;
  final bool downloading;
  /// Menu de ações; recebe o contexto do botão (o menu abre junto dele no desktop)
  final void Function(BuildContext buttonContext)? onMore;

  const DocumentTile({super.key, required this.document, required this.onDownload, this.downloading = false, this.onMore});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final d = document;
    return AppListTileCard(
      onTap: downloading ? null : onDownload,
      showChevron: false,
      leading: CircleAvatar(
        backgroundColor: colors.primary.withValues(alpha: 0.10),
        child: Icon(d.type.icon, color: colors.primaryText),
      ),
      title: d.title,
      subtitle: [
        d.type.label,
        if (d.date != null) formatDate(d.date),
        'PDF ${d.sizeLabel}',
      ].join(' · '),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          downloading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(Icons.download_outlined, color: colors.primaryText),
          if (onMore != null)
            Builder(
              builder: (buttonContext) => IconButton(
                  tooltip: 'Mais ações', icon: const Icon(Icons.more_vert), onPressed: () => onMore!(buttonContext)),
            ),
        ],
      ),
    );
  }
}
