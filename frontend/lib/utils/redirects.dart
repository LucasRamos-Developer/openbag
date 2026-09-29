/// Destino interno vindo de `?next=` (ex: `/checkout`): só caminhos do próprio app, nunca outro site
String? safeNextPath(String? next) =>
    next != null && next.startsWith('/') && !next.startsWith('//') ? next : null;

/// Caminho com o `?next=` preservado (ex: do login para o cadastro, sem perder a volta ao checkout)
String withNext(String path, String? next) {
  final target = safeNextPath(next);
  return target == null ? path : Uri(path: path, queryParameters: {'next': target}).toString();
}
