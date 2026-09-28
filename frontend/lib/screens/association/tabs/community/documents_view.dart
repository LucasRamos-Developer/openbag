import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/ui/ui.dart';
import '../../../../models/cooperative/community.dart';
import '../../../../services/association_service.dart';
import '../../../../services/cooperative_service.dart';
import '../../../../utils/feedback.dart';
import '../../../../utils/file_download.dart';
import '../../../../utils/file_pick.dart';
import '../../../../widgets/cooperative/document_tile.dart';

/// Atas das reuniões, estatuto e prestações de contas em PDF. Os cooperados veem e baixam no painel deles.
class DocumentsView extends StatefulWidget {
  const DocumentsView({super.key});

  @override
  State<DocumentsView> createState() => _DocumentsViewState();
}

class _DocumentsViewState extends State<DocumentsView> {
  int _version = 0;
  int? _downloading;

  int get _orgId => context.read<AssociationService>().association!.id;
  CooperativeService get _service => context.read<CooperativeService>();

  Future<void> _upload() async {
    if (!canPickFiles) {
      AppToast.show(context, message: 'O envio de documentos está disponível na versão web');
      return;
    }
    final saved = await showAppAdaptive<bool>(context, builder: (_) => const _UploadForm());
    if (saved == true) setState(() => _version++);
  }

  Future<void> _download(AssociationDocument document) async {
    if (!canDownloadFiles) {
      AppToast.show(context, message: 'O download está disponível na versão web');
      return;
    }
    setState(() => _downloading = document.id);
    await runWithFeedback(context, () async {
      final bytes = await _service.downloadDocument(_orgId, document.id);
      downloadBytes(bytes, fileName: document.fileName, mimeType: 'application/pdf');
    });
    if (mounted) setState(() => _downloading = null);
  }

  Future<void> _more(BuildContext buttonContext, AssociationDocument document) async {
    final action = await showAppActionSheet<String>(
      buttonContext,
      title: document.title,
      actions: const [
        AppSheetAction(value: 'download', label: 'Baixar', icon: Icons.download_outlined),
        AppSheetAction(value: 'delete', label: 'Apagar', icon: Icons.delete_outline, destructive: true),
      ],
    );
    if (!mounted) return;
    if (action == 'download') await _download(document);
    if (action == 'delete') {
      final confirmed = await AppDialog.confirm(context,
          title: 'Apagar documento?', message: 'Os cooperados deixam de ver "${document.title}".', confirmLabel: 'Apagar');
      if (!confirmed || !mounted) return;
      final ok = await runWithFeedback(context, () => _service.deleteDocument(_orgId, document.id),
          success: 'Documento apagado');
      if (ok) setState(() => _version++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = AppLayout.isCompact(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: compact
          ? FloatingActionButton.extended(onPressed: _upload, icon: const Icon(Icons.upload_file), label: const Text('Enviar PDF'))
          : null,
      body: AppLoadView<List<AssociationDocument>>(
        key: ValueKey(_version),
        load: () => _service.fetchDocuments(_orgId),
        builder: (context, documents, reload) => AppPageListView(
          top: 8,
          bottom: compact ? 96 : 32,
          maxWidth: 820,
          children: [
            if (!compact)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AppButton(text: 'Enviar documento', icon: Icons.upload_file, onPressed: _upload),
                ),
              ),
            if (documents.isEmpty)
              AppEmptyState(
                icon: Icons.folder_outlined,
                message: 'Nenhum documento ainda. Envie as atas das reuniões e o estatuto em PDF.',
                actionLabel: 'Enviar documento',
                onAction: _upload,
              ),
            for (final document in documents) ...[
              DocumentTile(
                document: document,
                downloading: _downloading == document.id,
                onDownload: () => _download(document),
                onMore: (buttonContext) => _more(buttonContext, document),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _UploadForm extends StatefulWidget {
  const _UploadForm();

  @override
  State<_UploadForm> createState() => _UploadFormState();
}

class _UploadFormState extends State<_UploadForm> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  AssociationDocumentType _type = AssociationDocumentType.MINUTES;
  DateTime? _date = DateTime.now();
  PickedFile? _file;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final file = await pickFile(accept: 'application/pdf');
    if (file == null || !mounted) return;
    if (file.bytes.length > 10 * 1024 * 1024) {
      AppToast.show(context, message: 'O arquivo passa de 10 MB', type: ToastType.warning);
      return;
    }
    setState(() {
      _file = file;
      if (_title.text.trim().isEmpty) _title.text = file.name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
    });
  }

  Future<void> _save() async {
    if (_file == null) {
      AppToast.show(context, message: 'Escolha o PDF', type: ToastType.warning);
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await runWithFeedback(
      context,
      () => context.read<CooperativeService>().uploadDocument(
            context.read<AssociationService>().association!.id,
            bytes: _file!.bytes,
            fileName: _file!.name,
            title: _title.text.trim(),
            type: _type,
            date: _date,
            description: _description.text.trim(),
          ),
      success: 'Documento enviado',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AppAdaptiveSheet(
      title: 'Enviar documento',
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCard(
              onTap: _pick,
              padding: const EdgeInsets.all(20),
              borderColor: colors.border,
              borderWidth: 1,
              child: Column(
                children: [
                  Icon(_file == null ? Icons.upload_file : Icons.picture_as_pdf_outlined, size: 36, color: colors.primaryText),
                  const SizedBox(height: 8),
                  Text(_file?.name ?? 'Escolher PDF (até 10 MB)', textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (_file != null) Text('Toque para trocar', style: TextStyle(color: colors.textMuted, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppSelect<AssociationDocumentType>(
              labelText: 'Tipo',
              variant: TextFieldVariant.filled,
              value: _type,
              items: [for (final t in AssociationDocumentType.values) SelectItem(value: t, label: t.label, icon: t.icon)],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _title,
              labelText: 'Título',
              hintText: 'Ex: Ata da assembleia de setembro',
              variant: TextFieldVariant.filled,
              maxLength: 150,
              validator: (v) => (v ?? '').trim().isEmpty ? 'Dê um título' : null,
            ),
            const SizedBox(height: 8),
            AppDateField(
              label: _type == AssociationDocumentType.MINUTES ? 'Data da reunião' : 'Data do documento',
              value: _date,
              clearable: true,
              lastDate: DateTime.now(),
              onChanged: (d) => setState(() => _date = d),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _description,
              labelText: 'Resumo (opcional)',
              hintText: 'O que foi decidido',
              variant: TextFieldVariant.filled,
              maxLines: 3,
              maxLength: 1000,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actions: [
        AppButton(text: 'Cancelar', variant: ButtonVariant.outlined, onPressed: () => Navigator.of(context).pop(false)),
        AppButton(text: 'Enviar', icon: Icons.upload, isLoading: _saving, onPressed: _saving ? null : _save),
      ],
    );
  }
}
