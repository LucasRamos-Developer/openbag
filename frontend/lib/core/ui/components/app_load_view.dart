import 'package:flutter/material.dart';
import 'app_empty_state.dart';

/// Carrega dados e mostra os três estados: carregando, erro (com "Tentar novamente") e o conteúdo.
/// O [builder] recebe `reload` para atualizar depois de uma ação; puxar a lista para baixo também recarrega.
///
/// ```dart
/// AppLoadView<List<Benefit>>(
///   load: () => service.fetchBenefits(orgId),
///   builder: (context, benefits, reload) => ListView(...),
/// )
/// ```
class AppLoadView<T> extends StatefulWidget {
  final Future<T> Function() load;
  final Widget Function(BuildContext context, T data, Future<void> Function() reload) builder;

  /// Converte o erro em mensagem (padrão: `toString()`, que nas exceções da API já é a mensagem pronta)
  final String Function(Object error)? errorMessage;

  const AppLoadView({super.key, required this.load, required this.builder, this.errorMessage});

  @override
  State<AppLoadView<T>> createState() => _AppLoadViewState<T>();
}

class _AppLoadViewState<T> extends State<AppLoadView<T>> {
  T? _data;
  Object? _error;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    try {
      final data = await widget.load();
      if (!mounted) return;
      setState(() {
        _data = data;
        _error = null;
        _loaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      if (_error != null) {
        return AppEmptyState(
          icon: Icons.cloud_off_outlined,
          message: widget.errorMessage?.call(_error!) ?? _error.toString(),
          actionLabel: 'Tentar novamente',
          onAction: () {
            setState(() => _error = null);
            _reload();
          },
        );
      }
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(onRefresh: _reload, child: widget.builder(context, _data as T, _reload));
  }
}
