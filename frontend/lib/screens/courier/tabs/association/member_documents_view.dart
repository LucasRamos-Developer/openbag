import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/ui/ui.dart';
import '../../../../models/cooperative/community.dart';
import '../../../../services/member_area_service.dart';
import '../../../../utils/feedback.dart';
import '../../../../utils/file_download.dart';
import '../../../../widgets/cooperative/document_tile.dart';

/// Atas, estatuto e prestações de contas da associação, para baixar
class MemberDocumentsView extends StatefulWidget {
  const MemberDocumentsView({super.key});

  @override
  State<MemberDocumentsView> createState() => _MemberDocumentsViewState();
}

class _MemberDocumentsViewState extends State<MemberDocumentsView> {
  int? _downloading;

  Future<void> _download(AssociationDocument document) async {
    if (!canDownloadFiles) {
      AppToast.show(context, message: 'O download está disponível na versão web');
      return;
    }
    setState(() => _downloading = document.id);
    await runWithFeedback(context, () async {
      final bytes = await context.read<MemberAreaService>().downloadDocument(document.id);
      downloadBytes(bytes, fileName: document.fileName, mimeType: 'application/pdf');
    });
    if (mounted) setState(() => _downloading = null);
  }

  @override
  Widget build(BuildContext context) {
    return AppLoadView<List<AssociationDocument>>(
      load: () => context.read<MemberAreaService>().fetchDocuments(),
      builder: (context, documents, reload) => AppPageListView(
        top: 8,
        maxWidth: 820,
        children: [
          if (documents.isEmpty)
            const AppEmptyState(icon: Icons.folder_outlined, message: 'A associação ainda não publicou documentos.'),
          for (final document in documents) ...[
            DocumentTile(
              document: document,
              downloading: _downloading == document.id,
              onDownload: () => _download(document),
            ),
            if (document.description != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(document.description!, style: TextStyle(color: context.appColors.textMuted, fontSize: 13)),
              ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
