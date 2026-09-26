import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/ui/ui.dart';
import '../../../models/association/member.dart';
import '../../../models/courier/courier_profile.dart';
import '../../../services/courier_service.dart';
import '../../../utils/feedback.dart';
import '../../../utils/formatters.dart';
import '../../../utils/validators.dart';
import '../../../widgets/association/association_logo.dart';
import '../../../widgets/association/membership_status_chip.dart';
import '../../../widgets/courier/association_picker.dart';
import '../../../widgets/courier/courier_avatar.dart';
import '../../../widgets/courier/social_links_editor.dart';

/// Perfil do entregador: foto, dados, bio, redes sociais, visibilidade e associação
class CourierProfileTab extends StatefulWidget {
  const CourierProfileTab({super.key});

  @override
  State<CourierProfileTab> createState() => _CourierProfileTabState();
}

class _CourierProfileTabState extends State<CourierProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final _linksKey = GlobalKey<SocialLinksEditorState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _bio;
  late bool _showWorkHistory;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<CourierService>().profile!;
    _name = TextEditingController(text: profile.fullName);
    _phone = TextEditingController(text: profile.phoneNumber);
    _bio = TextEditingController(text: profile.bio);
    _showWorkHistory = profile.showWorkHistory;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await runWithFeedback(
      context,
      () => context.read<CourierService>().updateProfile(
            fullName: _name.text.trim(),
            phoneNumber: _phone.text.trim(),
            bio: _bio.text.trim(),
            showWorkHistory: _showWorkHistory,
            socialLinks: _linksKey.currentState?.links ?? [],
          ),
      success: 'Perfil atualizado',
    );
    if (mounted) setState(() => _isSaving = false);
  }

  Future<void> _changePhoto() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    if (file == null || !mounted) return;
    setState(() => _isUploadingPhoto = true);
    await runWithFeedback(context, () => context.read<CourierService>().updatePhoto(file), success: 'Foto atualizada');
    if (mounted) setState(() => _isUploadingPhoto = false);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<CourierService>().profile!;
    final textTheme = Theme.of(context).textTheme;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MembershipSection(profile: profile),
                  const SizedBox(height: 32),
                  AppSectionHeader(
                    title: 'Meu perfil',
                    subtitle: 'Estas informações aparecem no seu perfil público, aberto pelo QR code da placa.',
                    action: AppButton(
                      text: 'Ver perfil público',
                      icon: Icons.open_in_new,
                      variant: ButtonVariant.text,
                      onPressed: () => context.push('/e/${profile.slug}'),
                    ),
                  ),
                  Row(
                    children: [
                      CourierAvatar(photoUrl: profile.photoUrl, name: profile.fullName, size: 88),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppButton(
                              text: profile.photoUrl == null ? 'Adicionar foto' : 'Trocar foto',
                              icon: Icons.photo_camera_outlined,
                              variant: ButtonVariant.outlined,
                              isLoading: _isUploadingPhoto,
                              onPressed: _isUploadingPhoto ? null : _changePhoto,
                            ),
                            const SizedBox(height: 6),
                            Text('Use uma foto do rosto, bem iluminada. Ela vai na placa de verificação.',
                                style: textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AppResponsiveRow(
                    breakpoint: 520,
                    children: [
                      AppTextField(
                        controller: _name,
                        labelText: 'Nome completo',
                        variant: TextFieldVariant.filled,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => validateRequired(v, 'Nome'),
                      ),
                      AppTextField(
                        controller: _phone,
                        labelText: 'Telefone',
                        variant: TextFieldVariant.filled,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [phoneFormatterShort],
                        validator: (v) => validateRequired(v, 'Telefone'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _bio,
                    labelText: 'Sobre você (opcional)',
                    hintText: 'Conte há quanto tempo entrega, a região em que roda…',
                    variant: TextFieldVariant.filled,
                    maxLines: 4,
                    maxLength: 500,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 24),
                  Text('Redes sociais', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  SocialLinksEditor(key: _linksKey, initialLinks: profile.socialLinks),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _showWorkHistory,
                    onChanged: (value) => setState(() => _showWorkHistory = value),
                    title: const Text('Mostrar onde já trabalhei no perfil público'),
                    subtitle: const Text('Lista os restaurantes em que você fez entregas.'),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: AppButton(
                      text: 'Salvar perfil',
                      icon: Icons.check,
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _save,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Associação do entregador: status do vínculo, sair/cancelar, ou entrar em uma
class _MembershipSection extends StatefulWidget {
  final CourierProfile profile;

  const _MembershipSection({required this.profile});

  @override
  State<_MembershipSection> createState() => _MembershipSectionState();
}

class _MembershipSectionState extends State<_MembershipSection> {
  AssociationChoice? _choice;
  bool _isSending = false;

  Future<void> _join() async {
    final choice = _choice;
    if (choice == null) return;
    setState(() => _isSending = true);
    await runWithFeedback(
      context,
      () => context.read<CourierService>().requestToJoin(choice),
      success: choice.isInvite ? 'Você entrou na associação' : 'Pedido enviado ao gestor da associação',
    );
    if (mounted) setState(() => _isSending = false);
  }

  Future<void> _leave(bool pending) async {
    final service = context.read<CourierService>();
    final reason = await AppDialog.reason(
      context,
      title: pending ? 'Cancelar pedido de entrada?' : 'Sair da associação?',
      confirmLabel: pending ? 'Cancelar pedido' : 'Sair',
      message: pending
          ? null
          : 'Sem associação você não pode ficar online nem receber entregas até entrar em outra.',
    );
    if (reason == null || !mounted) return;
    await runWithFeedback(context, () => service.leaveAssociation(reason: reason));
  }

  @override
  Widget build(BuildContext context) {
    final association = widget.profile.association;
    final textTheme = Theme.of(context).textTheme;

    if (association == null) {
      return AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSectionHeader(
              title: 'Minha associação',
              subtitle: 'Você não faz parte de nenhuma associação. Entre em uma para poder receber entregas.',
            ),
            AssociationPicker(value: _choice, onChanged: (choice) => setState(() => _choice = choice)),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: AppButton(
                text: _choice?.isInvite == true ? 'Entrar' : 'Pedir para entrar',
                icon: Icons.send,
                isLoading: _isSending,
                onPressed: _choice == null || _isSending ? null : _join,
              ),
            ),
          ],
        ),
      );
    }

    final pending = association.status == MembershipStatus.PENDING;
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          AssociationLogo(logoUrl: association.logoUrl, name: association.name, size: 56),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(association.name, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    MembershipStatusChip(status: association.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  pending
                      ? 'Seu pedido de entrada está aguardando a aprovação do gestor.'
                      : [
                          if (association.memberNumber != null) 'Associado nº ${association.memberNumber}',
                          if (association.status == MembershipStatus.SUSPENDED)
                            'Vínculo suspenso: fale com o gestor da associação.',
                        ].join(' · '),
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          AppButton(
            text: pending ? 'Cancelar pedido' : 'Sair',
            variant: ButtonVariant.text,
            onPressed: () => _leave(pending),
          ),
        ],
      ),
    );
  }
}
