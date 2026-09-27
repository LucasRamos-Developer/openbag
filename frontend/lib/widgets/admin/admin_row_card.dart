import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';

/// Linha das listas do painel admin: avatar, título, linhas de apoio e um selo à direita
class AdminRowCard extends StatelessWidget {
  final Widget leading;
  final String title;
  final List<String> lines;
  final List<Widget> trailing;
  final VoidCallback? onTap;

  const AdminRowCard({
    super.key,
    required this.leading,
    required this.title,
    this.lines = const [],
    this.trailing = const [],
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return AppCard(
      padding: const EdgeInsets.all(16),
      backgroundColor: c.surface,
      borderColor: c.border,
      borderWidth: 1,
      onTap: onTap,
      child: Row(
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.text, fontSize: 15, fontWeight: FontWeight.w700)),
                for (final line in lines)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(line,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.textMuted, fontSize: 13)),
                  ),
              ],
            ),
          ),
          if (trailing.isNotEmpty) ...[
            const SizedBox(width: 12),
            Wrap(spacing: 8, runSpacing: 6, alignment: WrapAlignment.end, children: trailing),
          ],
        ],
      ),
    );
  }
}
