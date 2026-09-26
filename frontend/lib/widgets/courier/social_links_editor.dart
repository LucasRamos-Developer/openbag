import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/courier/social_link.dart';
import '../../utils/validators.dart';

/// Edição da lista de redes sociais do entregador (rede + link, até [maxLinks])
class SocialLinksEditor extends StatefulWidget {
  final List<SocialLink> initialLinks;
  final int maxLinks;

  const SocialLinksEditor({super.key, required this.initialLinks, this.maxLinks = 8});

  @override
  State<SocialLinksEditor> createState() => SocialLinksEditorState();
}

class SocialLinksEditorState extends State<SocialLinksEditor> {
  final List<_LinkRow> _rows = [];

  @override
  void initState() {
    super.initState();
    for (final link in widget.initialLinks) {
      _rows.add(_LinkRow(link.platform, link.url));
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.controller.dispose();
    }
    super.dispose();
  }

  /// Links preenchidos, na ordem da tela
  List<SocialLink> get links => [
        for (final row in _rows)
          if (row.controller.text.trim().isNotEmpty) SocialLink(platform: row.platform, url: row.controller.text.trim()),
      ];

  void _add() {
    final used = _rows.map((r) => r.platform).toSet();
    final next = SocialPlatform.values.firstWhere((p) => !used.contains(p), orElse: () => SocialPlatform.OTHER);
    setState(() => _rows.add(_LinkRow(next, '')));
  }

  void _remove(_LinkRow row) {
    setState(() => _rows.remove(row));
    row.controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in _rows) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 170,
                child: AppSelect<SocialPlatform>(
                  labelText: 'Rede',
                  variant: TextFieldVariant.filled,
                  value: row.platform,
                  items: [for (final p in SocialPlatform.values) SelectItem(value: p, label: p.label)],
                  onChanged: (value) => setState(() => row.platform = value ?? row.platform),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppTextField(
                  controller: row.controller,
                  labelText: row.platform == SocialPlatform.WHATSAPP ? 'Número ou link' : 'Link',
                  hintText: row.platform.hint,
                  variant: TextFieldVariant.filled,
                  prefixIcon: Icon(row.platform.icon),
                  validator: (v) => validateRequired(v, 'Link'),
                ),
              ),
              IconButton(
                tooltip: 'Remover',
                icon: const Icon(Icons.close),
                onPressed: () => _remove(row),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (_rows.length < widget.maxLinks)
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              text: 'Adicionar rede social',
              icon: Icons.add,
              variant: ButtonVariant.text,
              onPressed: _add,
            ),
          ),
      ],
    );
  }
}

class _LinkRow {
  SocialPlatform platform;
  final TextEditingController controller;

  _LinkRow(this.platform, String url) : controller = TextEditingController(text: url);
}
