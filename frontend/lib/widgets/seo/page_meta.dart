import 'package:flutter/widgets.dart';
import '../../utils/seo.dart';

/// Define o título e as meta tags da página enquanto ela está na tela (vitrine, loja, perfil público).
///
/// Ao sair, volta para o padrão do site, a não ser que outra página já tenha definido as suas.
class PageMeta extends StatefulWidget {
  final PageMetaData meta;
  final Widget child;

  const PageMeta({super.key, required this.meta, required this.child});

  @override
  State<PageMeta> createState() => _PageMetaState();
}

class _PageMetaState extends State<PageMeta> {
  /// Página que definiu as meta tags atuais
  static _PageMetaState? _owner;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant PageMeta oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meta != widget.meta) _schedule();
  }

  // Depois do quadro: a página que sai (dispose) roda antes e não apaga as tags da que entra
  void _schedule() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _owner = this;
        applyPageMeta(widget.meta);
      });

  @override
  void dispose() {
    if (_owner == this) {
      _owner = null;
      applyPageMeta(PageMetaData.defaults);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
