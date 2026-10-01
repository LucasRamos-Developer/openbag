import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/ui/ui.dart';
import '../../../../models/cooperative/announcement.dart';
import '../../../../services/association_service.dart';
import '../../../../services/cooperative_service.dart';
import '../../../../utils/feedback.dart';
import '../../../../utils/formatters.dart';
import '../../../../widgets/cooperative/announcement_card.dart';

/// Mural de comunicados: o gestor publica (na hora), corrige e arquiva. O cooperado vê na área dele.
class AnnouncementsView extends StatefulWidget {
  const AnnouncementsView({super.key});

  @override
  State<AnnouncementsView> createState() => _AnnouncementsViewState();
}

class _AnnouncementsViewState extends State<AnnouncementsView> {
  int _version = 0;
  bool _showArchived = false;

  int get _orgId => context.read<AssociationService>().association!.id;
  CooperativeService get _service => context.read<CooperativeService>();

  void _reload() => setState(() => _version++);

  Future<void> _edit([Announcement? announcement]) async {
    final saved = await showAppAdaptive<bool>(context, builder: (_) => _AnnouncementForm(announcement: announcement));
    if (saved == true) _reload();
  }

  Future<void> _archive(Announcement announcement, bool archive) async {
    if (archive) {
      final confirmed = await AppDialog.confirm(context,
          title: 'Arquivar o comunicado?',
          message: 'Ele sai da área dos cooperados e fica aqui, nos arquivados.',
          confirmLabel: 'Arquivar');
      if (!confirmed || !mounted) return;
    }
    final ok = await runWithFeedback(
      context,
      () => _service.announcementAction(_orgId, announcement.id, archive ? 'archive' : 'restore'),
      success: archive ? 'Comunicado arquivado' : 'Comunicado de volta no mural',
    );
    if (ok) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final compact = AppLayout.isCompact(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: compact
          ? FloatingActionButton.extended(onPressed: _edit, icon: const Icon(Icons.add), label: const Text('Novo comunicado'))
          : null,
      body: AppLoadView<List<Announcement>>(
        key: ValueKey(_version),
        load: () => _service.fetchAnnouncements(_orgId),
        builder: (context, all, reload) {
          final shown = all.where((a) => a.archived == _showArchived).toList();
          return AppPageListView(
            top: 8,
            bottom: compact ? 96 : 32,
            maxWidth: 820,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppFilterChips<bool>(
                      items: [
                        SelectItem(value: false, label: 'No mural (${all.where((a) => !a.archived).length})'),
                        SelectItem(value: true, label: 'Arquivados (${all.where((a) => a.archived).length})'),
                      ],
                      value: _showArchived,
                      onSelected: (v) => setState(() => _showArchived = v),
                    ),
                  ),
                  if (!compact) AppButton(text: 'Novo comunicado', icon: Icons.add, onPressed: _edit),
                ],
              ),
              const SizedBox(height: 12),
              if (shown.isEmpty)
                AppEmptyState(
                  icon: Icons.campaign_outlined,
                  message: _showArchived
                      ? 'Nenhum comunicado arquivado.'
                      : 'Nenhum comunicado no mural. Avise sobre reuniões, mudanças de valor e novas parcerias.',
                  actionLabel: _showArchived ? null : 'Escrever comunicado',
                  onAction: _showArchived ? null : _edit,
                ),
              for (final a in shown) ...[
                AnnouncementCard(
                  announcement: a,
                  manager: true,
                  actions: a.archived
                      ? [AppButton(text: 'Devolver ao mural', variant: ButtonVariant.outlined, onPressed: () => _archive(a, false))]
                      : [
                          AppButton(text: 'Arquivar', variant: ButtonVariant.text, onPressed: () => _archive(a, true)),
                          AppButton(text: 'Corrigir', variant: ButtonVariant.outlined, onPressed: () => _edit(a)),
                        ],
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Comunicado: tipo, título, texto e, em reunião e treinamento, data e hora. Publica na hora.
class _AnnouncementForm extends StatefulWidget {
  final Announcement? announcement;

  const _AnnouncementForm({this.announcement});

  @override
  State<_AnnouncementForm> createState() => _AnnouncementFormState();
}

class _AnnouncementFormState extends State<_AnnouncementForm> {
  final _formKey = GlobalKey<FormState>();
  late AnnouncementType _type = widget.announcement?.type ?? AnnouncementType.NOTICE;
  late final _title = TextEditingController(text: widget.announcement?.title);
  late final _body = TextEditingController(text: widget.announcement?.body);
  late DateTime? _day = widget.announcement?.eventAt;
  late TimeOfDay _time = widget.announcement?.eventAt != null
      ? TimeOfDay.fromDateTime(widget.announcement!.eventAt!)
      : const TimeOfDay(hour: 19, minute: 0);
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_type == AnnouncementType.MEETING && _day == null) {
      AppToast.show(context, message: 'Escolha o dia da reunião', type: ToastType.warning);
      return;
    }
    final day = _day;
    setState(() => _saving = true);
    final ok = await runWithFeedback(
      context,
      () => context.read<CooperativeService>().saveAnnouncement(
            context.read<AssociationService>().association!.id,
            type: _type,
            title: _title.text.trim(),
            body: _body.text.trim(),
            eventAt: _type.hasEvent && day != null
                ? DateTime(day.year, day.month, day.day, _time.hour, _time.minute)
                : null,
            announcementId: widget.announcement?.id,
          ),
      success: widget.announcement == null ? 'Comunicado publicado' : 'Comunicado corrigido',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.announcement != null;
    return AppAdaptiveSheet(
      title: editing ? 'Corrigir comunicado' : 'Novo comunicado',
      subtitle: editing ? null : 'Os cooperados veem na hora, na área deles',
      maxWidth: 620,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Tipo', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in AnnouncementType.values)
                  ChoiceChip(
                    avatar: Icon(t.icon, size: 18),
                    label: Text(t.label),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _title,
              labelText: 'Título',
              hintText: 'Ex.: Assembleia de outubro',
              variant: TextFieldVariant.filled,
              maxLength: 150,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => (v ?? '').trim().isEmpty ? 'Escreva um título' : null,
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _body,
              labelText: 'Comunicado',
              variant: TextFieldVariant.filled,
              maxLines: 6,
              maxLength: 2000,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) => (v ?? '').trim().isEmpty ? 'Escreva o comunicado' : null,
            ),
            if (_type.hasEvent) ...[
              const SizedBox(height: 12),
              AppDateField(
                label: _type == AnnouncementType.MEETING ? 'Dia da reunião' : 'Dia do treinamento (opcional)',
                value: _day,
                clearable: _type != AnnouncementType.MEETING,
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                onChanged: (d) => setState(() => _day = d),
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'Horário: ${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                icon: Icons.schedule,
                variant: ButtonVariant.outlined,
                fullWidth: true,
                onPressed: _pickTime,
              ),
              if (_day != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Os cooperados veem: ${formatDate(_day)} às ${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: context.appColors.textMuted, fontSize: 13),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        AppButton(text: 'Cancelar', variant: ButtonVariant.outlined, onPressed: () => Navigator.of(context).pop(false)),
        AppButton(
            text: editing ? 'Salvar' : 'Publicar',
            icon: Icons.campaign_outlined,
            isLoading: _saving,
            onPressed: _saving ? null : _save),
      ],
    );
  }
}
