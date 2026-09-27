import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/ui/ui.dart';
import '../../../../models/menu/menu.dart';
import '../../../../models/restaurant.dart';
import '../../../../models/store/store.dart';
import '../../../../services/restaurant_panel_service.dart';
import '../../../../utils/feedback.dart';
import '../../../../widgets/menu/menu_product_card.dart';
import '../../../../widgets/restaurant/restaurant_header.dart';
import '../../../../widgets/restaurant/restaurant_theme_scope.dart';
import '../../../../widgets/restaurant/theme_preset_picker.dart';

/// Loja › Aparência: imagem de destaque, logo, slogan, tema e cor da marca, com prévia ao vivo
/// (ao lado do formulário em telas largas). Imagens sobem na hora; o resto é salvo no botão.
class AppearanceTab extends StatefulWidget {
  final Store store;

  const AppearanceTab({super.key, required this.store});

  @override
  State<AppearanceTab> createState() => _AppearanceTabState();
}

class _AppearanceTabState extends State<AppearanceTab> {
  /// Largura útil a partir da qual a prévia fica ao lado do formulário
  static const double _sideBySideWidth = 960;

  static const String _defaultBrand = '#00A878';

  late final TextEditingController _slogan = TextEditingController(text: widget.store.slogan);
  late AppThemePreset _preset = AppThemePreset.fromKey(widget.store.themePreset);
  late bool _useBrand = widget.store.brandColor != null;
  late String _brand = widget.store.brandColor ?? _defaultBrand;
  StoreImage? _uploading;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _slogan.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _slogan.dispose();
    super.dispose();
  }

  String? get _brandColor => _useBrand ? _brand : null;

  bool get _dirty =>
      _preset.key != widget.store.themePreset ||
      _brandColor != widget.store.brandColor ||
      (_slogan.text.trim().isEmpty ? null : _slogan.text.trim()) != widget.store.slogan;

  Future<void> _pickImage(StoreImage kind) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: kind == StoreImage.banner ? 2000 : 800,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    setState(() => _uploading = kind);
    await runWithFeedback(context, () => context.read<RestaurantPanelService>().uploadStoreImage(kind, file),
        success: kind == StoreImage.banner ? 'Imagem de destaque atualizada' : 'Logo atualizado');
    if (mounted) setState(() => _uploading = null);
  }

  Future<void> _removeImage(StoreImage kind) async {
    setState(() => _uploading = kind);
    await runWithFeedback(context, () => context.read<RestaurantPanelService>().removeStoreImage(kind),
        success: kind == StoreImage.banner ? 'Imagem de destaque removida' : 'Logo removido');
    if (mounted) setState(() => _uploading = null);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await runWithFeedback(
      context,
      () => context.read<RestaurantPanelService>().updateAppearance(
            themePreset: _preset.key,
            brandColor: _brandColor,
            slogan: _slogan.text.trim().isEmpty ? null : _slogan.text.trim(),
          ),
      success: 'Aparência salva',
    );
    if (mounted) setState(() => _saving = false);
  }

  /// Abre a página pública numa aba nova com o tema ainda não salvo
  void _openPage() {
    final uri = Uri.base.replace(
      path: '/r/${widget.store.slug}',
      queryParameters: _dirty ? {'tema': _preset.slug, if (_brandColor != null) 'cor': _brandColor!} : null,
      fragment: '',
    );
    launchUrl(uri, webOnlyWindowName: '_blank');
  }

  Restaurant get _previewRestaurant {
    final store = widget.store;
    return Restaurant(
      id: store.id,
      name: store.name,
      slug: store.slug,
      logoUrl: store.logoUrl,
      bannerUrl: store.bannerUrl,
      slogan: _slogan.text.trim().isEmpty ? null : _slogan.text.trim(),
      rating: store.rating,
      totalReviews: store.totalReviews,
      categories: store.categories,
      deliveryFee: store.deliveryFee,
      minimumOrder: store.minimumOrder,
      deliveryTimeMin: store.deliveryTimeMin,
      deliveryTimeMax: store.deliveryTimeMax,
      priceRange: store.priceRange,
      openNow: store.openNow,
      pausedUntil: store.pausedUntil,
    );
  }

  /// Primeiro item com foto do cardápio, para a prévia mostrar um produto de verdade
  MenuItem? get _sampleItem {
    final items = context.watch<RestaurantPanelService>().menu?.sections.expand((s) => s.items).toList() ?? const [];
    if (items.isEmpty) return null;
    return items.firstWhere((i) => i.imageUrl != null, orElse: () => items.first);
  }

  @override
  Widget build(BuildContext context) {
    final preview = AppPanelCard(
      title: 'Prévia',
      subtitle: 'Como os clientes veem sua página',
      child: _Preview(restaurant: _previewRestaurant, preset: _preset, brandColor: _brandColor, item: _sampleItem),
    );

    return LayoutBuilder(builder: (context, constraints) {
      final padding = AppLayout.contentPadding(constraints.maxWidth, top: 16);
      final form = _buildForm(context);

      if (constraints.maxWidth - padding.horizontal < _sideBySideWidth) {
        return AppPageListView(top: 16, children: [preview, const SizedBox(height: 16), ...form]);
      }
      return Padding(
        padding: EdgeInsets.only(left: padding.left, right: padding.right),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: ListView(padding: EdgeInsets.only(top: padding.top, bottom: padding.bottom), children: form),
            ),
            const SizedBox(width: 24),
            // A prévia fica parada enquanto o formulário rola
            Expanded(
              flex: 6,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(top: padding.top, bottom: padding.bottom),
                child: preview,
              ),
            ),
          ],
        ),
      );
    });
  }

  List<Widget> _buildForm(BuildContext context) {
    final ui = context.appColors;
    final resolved = AppThemeColors.resolve(_preset, brandColor: _brandColor);
    final adjusted = _useBrand && (resolved.action != resolved.primary || resolved.primaryText != resolved.primary);
    final store = widget.store;

    return [
      AppPanelCard(
        title: 'Imagens',
        subtitle: 'Sobem na hora, sem precisar salvar',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ImageRow(
              icon: Icons.panorama_outlined,
              title: 'Imagem de destaque',
              hint: 'Recomendado 1600×500 px, com o prato à direita: o lado esquerdo recebe o nome e o slogan.',
              hasImage: store.bannerUrl != null,
              busy: _uploading == StoreImage.banner,
              onPick: () => _pickImage(StoreImage.banner),
              onRemove: () => _removeImage(StoreImage.banner),
            ),
            const SizedBox(height: 12),
            _ImageRow(
              icon: Icons.storefront_outlined,
              title: 'Logo',
              hint: 'Quadrado, de preferência 512×512 px. Sem logo, mostramos as iniciais.',
              hasImage: store.logoUrl != null,
              busy: _uploading == StoreImage.logo,
              onPick: () => _pickImage(StoreImage.logo),
              onRemove: () => _removeImage(StoreImage.logo),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      AppPanelCard(
        title: 'Banner e cores',
        subtitle: 'Slogan do banner e as cores de botões, preços, selos e fundo',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _slogan,
              labelText: 'Slogan (opcional)',
              hintText: 'Ex: Sabor de verdade, todo dia!',
              variant: TextFieldVariant.filled,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            Text('Tema', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('As cores de botões, preços, selos e fundo da sua página.', style: TextStyle(color: ui.textMuted)),
            const SizedBox(height: 12),
            ThemePresetPicker(value: _preset, onChanged: (p) => setState(() => _preset = p)),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Usar a cor da minha marca'),
              subtitle: const Text('Troca a cor principal do tema; as demais são ajustadas automaticamente'),
              value: _useBrand,
              onChanged: (v) => setState(() => _useBrand = v),
            ),
            if (_useBrand) ...[
              const SizedBox(height: 8),
              AppColorField(
                label: 'Cor da marca',
                value: _brand,
                onChanged: (hex) => setState(() => _brand = hex),
                helperText: adjusted ? 'Ajustamos o tom de botões e preços para garantir a leitura.' : null,
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 16),
      Wrap(
        alignment: WrapAlignment.end,
        spacing: 12,
        runSpacing: 12,
        children: [
          AppButton(
            text: _dirty ? 'Ver página com este tema' : 'Ver minha página',
            icon: Icons.open_in_new,
            variant: ButtonVariant.outlined,
            onPressed: _openPage,
          ),
          AppButton(
            text: 'Salvar aparência',
            icon: Icons.check,
            isLoading: _saving,
            onPressed: _dirty && !_saving ? _save : null,
          ),
        ],
      ),
    ];
  }
}

/// Miniatura da página com o tema escolhido: topo + um produto
class _Preview extends StatelessWidget {
  final Restaurant restaurant;
  final AppThemePreset preset;
  final String? brandColor;
  final MenuItem? item;

  const _Preview({required this.restaurant, required this.preset, this.brandColor, this.item});

  @override
  Widget build(BuildContext context) {
    return RestaurantThemeScope(
      themePreset: preset.key,
      brandColor: brandColor,
      child: Builder(builder: (context) {
        final c = context.appColors;
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            color: c.background,
            padding: const EdgeInsets.only(bottom: 16),
            child: IgnorePointer(
              child: Column(
                children: [
                  RestaurantHeader(restaurant: restaurant),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: MenuProductCard(
                      name: item?.name ?? 'Seu produto',
                      description: item?.description ?? 'A descrição do item aparece aqui',
                      imageUrl: item?.imageUrl,
                      price: item?.price ?? 32.90,
                      promotionalPrice: item == null ? 27.90 : item!.promotionalPrice,
                      badges: item?.badges ?? const ['Tradicional'],
                      onTap: () {},
                      onAdd: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _ImageRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  final bool hasImage;
  final bool busy;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  const _ImageRow({
    required this.icon,
    required this.title,
    required this.hint,
    required this.hasImage,
    required this.busy,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final actions = Wrap(
      spacing: 8,
      children: [
        if (hasImage)
          AppButton(text: 'Remover', variant: ButtonVariant.text, size: ButtonSize.small, onPressed: busy ? null : onRemove),
        AppButton(
          text: hasImage ? 'Trocar' : 'Enviar',
          icon: Icons.upload_outlined,
          variant: ButtonVariant.outlined,
          size: ButtonSize.small,
          isLoading: busy,
          onPressed: busy ? null : onPick,
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: LayoutBuilder(builder: (context, constraints) {
        final info = Row(
          children: [
            Icon(icon, color: c.primaryText),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(hint, style: TextStyle(color: c.textMuted, fontSize: 12)),
                ],
              ),
            ),
          ],
        );
        if (constraints.maxWidth < 520) {
          return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [info, const SizedBox(height: 8), actions]);
        }
        return Row(children: [Expanded(child: info), const SizedBox(width: 12), actions]);
      }),
    );
  }
}
