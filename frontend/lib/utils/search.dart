/// Busca de texto sem diferenciar maiúsculas nem acentos ("pizzaria" acha "Pizzária")

const _accents = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ã': 'a', 'ä': 'a',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', 'ö': 'o',
  'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
  'ç': 'c', 'ñ': 'n',
};

/// Texto em minúsculas e sem acentos, para comparar em buscas
String foldForSearch(String text) =>
    text.toLowerCase().split('').map((ch) => _accents[ch] ?? ch).join();

/// Se todas as palavras de [query] aparecem em algum dos [fields] (vazia = tudo)
bool matchesSearch(String query, Iterable<String?> fields) {
  final words = foldForSearch(query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  if (words.isEmpty) return true;
  final haystack = foldForSearch(fields.whereType<String>().join(' '));
  return words.every(haystack.contains);
}
