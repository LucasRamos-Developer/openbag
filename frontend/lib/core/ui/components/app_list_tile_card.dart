import 'package:flutter/material.dart';
import '../theme/app_theme_colors.dart';
import 'app_card.dart';

/// Linha de lista em forma de card, confortável no celular e no desktop:
/// avatar/ícone à esquerda, título e subtítulo, e à direita um valor e/ou um chip de status.
///
/// ```dart
/// AppListTileCard(
///   leading: CircleAvatar(child: Text('A')),
///   title: 'Ana Souza · nº 12',
///   subtitle: 'Moto · Honda CG · ABC1D23',
///   trailing: MembershipStatusChip(status: member.status),
///   onTap: () => _open(member),
/// )
/// ```
class AppListTileCard extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;

  /// Linha extra abaixo do subtítulo (ex: chips de adicionais)
  final Widget? footer;

  /// Valor em destaque à direita (ex: "R$ 85,00")
  final String? value;

  /// Widget à direita, abaixo do [value] (ex: chip de status)
  final Widget? trailing;

  final VoidCallback? onTap;

  /// Seta › quando o card abre um detalhe (padrão: sempre que há [onTap])
  final bool showChevron;

  const AppListTileCard({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.footer,
    this.value,
    this.trailing,
    this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderColor: colors.border,
      borderWidth: 1,
      child: ConstrainedBox(
        // Área de toque confortável mesmo sem subtítulo
        constraints: const BoxConstraints(minHeight: 48),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: TextStyle(color: colors.text, fontWeight: FontWeight.w600), maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: textTheme.bodySmall?.copyWith(color: colors.textMuted, fontSize: 13),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  if (footer != null) ...[const SizedBox(height: 8), footer!],
                ],
              ),
            ),
            if (value != null || trailing != null) ...[
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (value != null)
                    Text(value!,
                        style: textTheme.titleSmall?.copyWith(
                            color: colors.text,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()])),
                  if (value != null && trailing != null) const SizedBox(height: 6),
                  if (trailing != null) trailing!,
                ],
              ),
            ],
            if (onTap != null && showChevron) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: colors.textMuted),
            ],
          ],
        ),
      ),
    );
  }
}
