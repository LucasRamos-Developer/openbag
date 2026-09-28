import 'dart:async';

import 'package:flutter/material.dart';
import 'app_button.dart';
import 'app_empty_state.dart';
import 'app_page_container.dart';
import 'app_search_bar.dart';
import 'app_section_header.dart';

/// Uma página de resultados vinda do backend (`Page` do Spring: content + last)
class AppPage<T> {
  final List<T> items;
  final bool last;
  final int total;

  const AppPage({required this.items, required this.last, this.total = 0});

  factory AppPage.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) fromJson) => AppPage(
        items: (json['content'] as List? ?? const []).map((e) => fromJson(e as Map<String, dynamic>)).toList(),
        last: json['last'] ?? true,
        total: json['totalElements'] ?? 0,
      );
}

/// Lista rolável com título, busca em pílula (opcional), filtros e "Carregar mais".
/// Busca de novo quando o texto muda (com espera) e quando [filterKey] muda.
///
/// ```dart
/// AppPagedList<UserRow>(
///   title: 'Usuários',
///   searchHint: 'Nome ou e-mail',
///   fetch: (query, page) => service.users(query: query, page: page),
///   itemBuilder: (context, user) => UserTile(user),
/// )
/// ```
class AppPagedList<T> extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;

  /// Sem [searchHint], a busca não aparece
  final String? searchHint;
  final Future<AppPage<T>> Function(String query, int page) fetch;
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Conteúdo fixo entre o título e a lista (ex: um resumo)
  final Widget? header;

  /// Filtros abaixo da busca (ex: chips de status); troque [filterKey] para recarregar
  final Widget? filters;
  final Object? filterKey;
  final String emptyMessage;
  final IconData emptyIcon;

  const AppPagedList({
    super.key,
    required this.title,
    required this.fetch,
    required this.itemBuilder,
    this.subtitle,
    this.leadingIcon,
    this.searchHint,
    this.header,
    this.filters,
    this.filterKey,
    this.emptyMessage = 'Nada por aqui ainda.',
    this.emptyIcon = Icons.inbox_outlined,
  });

  @override
  State<AppPagedList<T>> createState() => _AppPagedListState<T>();
}

class _AppPagedListState<T> extends State<AppPagedList<T>> {
  final _search = TextEditingController();
  Timer? _debounce;
  final List<T> _items = [];
  int _page = 0;
  bool _last = true;
  int _total = 0;
  bool _loading = false;
  String? _error;

  // Descarta respostas de buscas antigas que chegam depois de uma nova
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant AppPagedList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filterKey != widget.filterKey) _reload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    _items.clear();
    _page = 0;
    _last = true;
    await _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.fetch(_search.text.trim(), _page);
      if (!mounted || generation != _generation) return;
      setState(() {
        _items.addAll(page.items);
        _last = page.last;
        _total = page.total;
      });
    } catch (e) {
      if (mounted && generation == _generation) setState(() => _error = e.toString());
    } finally {
      if (mounted && generation == _generation) setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _reload);
  }

  Future<void> _loadMore() async {
    _page++;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.subtitle ??
        (_items.isEmpty && _loading ? null : '$_total ${_total == 1 ? 'resultado' : 'resultados'}');

    return RefreshIndicator(
      onRefresh: _reload,
      child: AppPageListView(
        children: [
          AppSectionHeader(title: widget.title, subtitle: subtitle, leadingIcon: widget.leadingIcon),
          if (widget.header != null) ...[widget.header!, const SizedBox(height: 16)],
          if (widget.searchHint != null) ...[
            AppSearchBar(controller: _search, hintText: widget.searchHint!, onChanged: _onSearchChanged),
            const SizedBox(height: 12),
          ],
          if (widget.filters != null) ...[widget.filters!, const SizedBox(height: 12)],
          if (_error != null && _items.isEmpty)
            AppEmptyState(icon: Icons.cloud_off_outlined, message: _error!, actionLabel: 'Tentar novamente', onAction: _reload)
          else if (_items.isEmpty && _loading)
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (_items.isEmpty)
            AppEmptyState(icon: widget.emptyIcon, message: widget.emptyMessage)
          else ...[
            for (final item in _items)
              Padding(padding: const EdgeInsets.only(bottom: 12), child: widget.itemBuilder(context, item)),
            if (!_last)
              Center(
                child: AppButton(
                  text: 'Carregar mais',
                  variant: ButtonVariant.outlined,
                  isLoading: _loading,
                  onPressed: _loading ? null : _loadMore,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
