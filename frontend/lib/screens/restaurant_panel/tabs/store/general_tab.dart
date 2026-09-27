import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/ui/ui.dart';
import '../../../../models/store/store.dart';
import '../../../../services/restaurant_panel_service.dart';
import '../../../../utils/feedback.dart';
import '../../../../utils/formatters.dart';
import '../../../../utils/validators.dart';
import '../../../../widgets/onboarding/category_selector.dart';

/// Loja › Geral: nome, telefone, descrição, faixa de preço e categorias. O endereço da página (slug)
/// e o CNPJ só aparecem para consulta.
class GeneralTab extends StatefulWidget {
  final Store store;

  const GeneralTab({super.key, required this.store});

  @override
  State<GeneralTab> createState() => _GeneralTabState();
}

class _GeneralTabState extends State<GeneralTab> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.store.name);
  late final _phone = TextEditingController(text: PhoneFormatter.format(widget.store.phoneNumber ?? ''));
  late final _description = TextEditingController(text: widget.store.description);
  // '' = não informar (o seletor não mostra rótulo para valor nulo)
  late String _priceRange = widget.store.priceRange ?? '';
  late List<int> _categoryIds = List.of(widget.store.categoryIds);
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _phone, _description]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _trimmed(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  bool get _dirty {
    final s = widget.store;
    return _name.text.trim() != s.name ||
        _phone.text.trim() != PhoneFormatter.format(s.phoneNumber ?? '') ||
        _trimmed(_description) != s.description ||
        _priceRange != (s.priceRange ?? '') ||
        !_sameIds(_categoryIds, s.categoryIds);
  }

  static bool _sameIds(List<int> a, List<int> b) => a.length == b.length && a.toSet().containsAll(b);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryIds.isEmpty) {
      AppToast.show(context, message: 'Escolha pelo menos uma categoria', type: ToastType.warning);
      return;
    }
    setState(() => _isSaving = true);
    await runWithFeedback(
      context,
      () => context.read<RestaurantPanelService>().updateProfile({
        'name': _name.text.trim(),
        'phoneNumber': _phone.text.trim(),
        'description': _trimmed(_description),
        'priceRange': _priceRange.isEmpty ? null : _priceRange,
        'categoryIds': _categoryIds,
      }),
      success: 'Dados salvos',
    );
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppPageListView(
      top: 16,
      children: [
        Form(
          key: _formKey,
          child: AppPanelCard(
            title: 'Dados do restaurante',
            subtitle: 'Nome, contato e descrição aparecem na sua página e nas buscas',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppResponsiveRow(
                  children: [
                    AppTextField(
                      controller: _name,
                      labelText: 'Nome do restaurante',
                      variant: TextFieldVariant.filled,
                      maxLength: 100,
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => validateRequired(v, 'Nome'),
                    ),
                    AppTextField(
                      controller: _phone,
                      labelText: 'Telefone',
                      hintText: '(00) 00000-0000',
                      variant: TextFieldVariant.filled,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [PhoneFormatter()],
                      validator: (v) => validateRequired(v, 'Telefone'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _description,
                  labelText: 'Descrição (opcional)',
                  hintText: 'Conte o que sua loja tem de especial',
                  variant: TextFieldVariant.filled,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 8),
                AppSelect<String>(
                  labelText: 'Faixa de preço',
                  variant: TextFieldVariant.filled,
                  value: _priceRange,
                  items: const [
                    SelectItem(value: '', label: 'Não informar'),
                    SelectItem(value: '\$', label: '\$ · econômico'),
                    SelectItem(value: '\$\$', label: '\$\$ · moderado'),
                    SelectItem(value: '\$\$\$', label: '\$\$\$ · caro'),
                    SelectItem(value: '\$\$\$\$', label: '\$\$\$\$ · sofisticado'),
                  ],
                  onChanged: (v) => setState(() => _priceRange = v ?? ''),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        AppPanelCard(
          title: 'Categorias',
          subtitle: 'Tipos de cozinha em que sua loja aparece na vitrine',
          child: CategorySelector(
            selectedCategoryIds: _categoryIds,
            onSelectionChanged: (ids) => setState(() => _categoryIds = ids),
          ),
        ),
        const SizedBox(height: 16),
        _IdentityCard(store: widget.store),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: AppButton(
            text: 'Salvar dados',
            icon: Icons.check,
            isLoading: _isSaving,
            onPressed: _dirty && !_isSaving ? _save : null,
          ),
        ),
      ],
    );
  }
}

/// Endereço público da página e CNPJ (só consulta)
class _IdentityCard extends StatelessWidget {
  final Store store;

  const _IdentityCard({required this.store});

  Uri get _pageUrl => Uri.base.replace(path: '/r/${store.slug}', query: '', fragment: '');

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final url = _pageUrl.toString().replaceAll(RegExp(r'[?#]+$'), '');

    return AppPanelCard(
      title: 'Identificação',
      subtitle: 'O endereço da página não muda quando você troca o nome, para os links já compartilhados continuarem funcionando',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            decoration: BoxDecoration(color: c.surfaceAlt, borderRadius: BorderRadius.circular(AppRadius.md)),
            child: Row(
              children: [
                Icon(Icons.link_rounded, color: c.primaryText),
                const SizedBox(width: 12),
                Expanded(
                  child: SelectableText(url, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                IconButton(
                  tooltip: 'Copiar endereço',
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: url));
                    if (context.mounted) AppToast.show(context, message: 'Endereço copiado', type: ToastType.success);
                  },
                ),
                IconButton(
                  tooltip: 'Abrir minha página',
                  icon: const Icon(Icons.open_in_new_rounded, size: 20),
                  onPressed: () => launchUrl(Uri.parse(url), webOnlyWindowName: '_blank'),
                ),
              ],
            ),
          ),
          if (store.cnpj != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.badge_outlined, color: c.textMuted),
                const SizedBox(width: 12),
                Text('CNPJ ', style: TextStyle(color: c.textMuted)),
                Text(store.cnpj!, style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Flexible(
                  child: Text(
                    'Para alterar, fale com o suporte',
                    textAlign: TextAlign.end,
                    style: TextStyle(color: c.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
