/// Validadores para o onboarding de restaurante

/// Valida formato de email
String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Email é obrigatório';
  }

  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  if (!emailRegex.hasMatch(value)) {
    return 'Email inválido';
  }

  return null;
}

/// Valida CNPJ no formato ##.###.###/####-00
/// Os 12 primeiros caracteres são alfanuméricos e os 2 últimos são dígitos verificadores
String? validateCNPJ(String? value) {
  if (value == null || value.isEmpty) {
    return 'CNPJ é obrigatório';
  }

  // Remove pontuação
  final cnpj = value.replaceAll(RegExp(r'[.\-/]'), '');

  // Verifica se tem 14 caracteres
  if (cnpj.length != 14) {
    return 'CNPJ deve ter 14 caracteres';
  }

  // Verifica se os primeiros 12 são alfanuméricos
  final firstTwelve = cnpj.substring(0, 12);
  if (!RegExp(r'^[a-zA-Z0-9]{12}$').hasMatch(firstTwelve)) {
    return 'Formato inválido. Use: ##.###.###/####-00';
  }

  // Verifica se os últimos 2 são dígitos
  final lastTwo = cnpj.substring(12);
  if (!RegExp(r'^[0-9]{2}$').hasMatch(lastTwo)) {
    return 'Os dois últimos caracteres devem ser dígitos';
  }

  // TODO: Validação matemática dos dígitos verificadores
  // O algoritmo será fornecido pelo usuário
  if (!_validateCNPJDigits(cnpj)) {
    return 'CNPJ inválido (dígitos verificadores)';
  }

  return null;
}

/// Validação matemática dos dígitos verificadores do CNPJ
/// NOTA: Algoritmo a ser fornecido pelo usuário
bool _validateCNPJDigits(String cnpj) {
  // TODO: Implementar algoritmo de validação matemática
  // Por enquanto, retorna true (aceita qualquer CNPJ com formato válido)
  // O usuário fornecerá o algoritmo correto
  return true;
}

/// Converte texto em slug (formato: lowercase, sem acentos, espaços → hífens)
String slugify(String text) {
  if (text.isEmpty) return '';

  // Map de acentos para substituição
  const accents = {
    'á': 'a', 'à': 'a', 'ã': 'a', 'â': 'a', 'ä': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i',
    'ó': 'o', 'ò': 'o', 'õ': 'o', 'ô': 'o', 'ö': 'o',
    'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u',
    'ç': 'c', 'ñ': 'n',
    'Á': 'a', 'À': 'a', 'Ã': 'a', 'Â': 'a', 'Ä': 'a',
    'É': 'e', 'È': 'e', 'Ê': 'e', 'Ë': 'e',
    'Í': 'i', 'Ì': 'i', 'Î': 'i', 'Ï': 'i',
    'Ó': 'o', 'Ò': 'o', 'Õ': 'o', 'Ô': 'o', 'Ö': 'o',
    'Ú': 'u', 'Ù': 'u', 'Û': 'u', 'Ü': 'u',
    'Ç': 'c', 'Ñ': 'n',
  };

  String result = text;

  // Substituir acentos
  accents.forEach((key, value) {
    result = result.replaceAll(key, value);
  });

  // Converter para lowercase
  result = result.toLowerCase();

  // Substituir espaços e underscores por hífens
  result = result.replaceAll(RegExp(r'[\s_]+'), '-');

  // Remover caracteres especiais (manter apenas letras, números e hífens)
  result = result.replaceAll(RegExp(r'[^a-z0-9\-]'), '');

  // Remover hífens duplicados
  result = result.replaceAll(RegExp(r'-+'), '-');

  // Remover hífens no início e fim
  result = result.replaceAll(RegExp(r'^-+|-+$'), '');

  return result;
}

/// Valida se a senha é forte o suficiente
String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Senha é obrigatória';
  }

  if (value.length < 6) {
    return 'Senha deve ter no mínimo 6 caracteres';
  }

  if (value.length > 100) {
    return 'Senha deve ter no máximo 100 caracteres';
  }

  return null;
}

/// Valida campo obrigatório genérico
String? validateRequired(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldName é obrigatório';
  }
  return null;
}

/// Valida se é um número válido maior ou igual a zero
String? validateNonNegativeNumber(String? value, String fieldName) {
  if (value == null || value.isEmpty) {
    return '$fieldName é obrigatório';
  }

  // Substituir vírgula por ponto para aceitar formato brasileiro
  final normalizedValue = value.replaceAll(',', '.');
  final number = double.tryParse(normalizedValue);
  
  if (number == null) {
    return '$fieldName deve ser um número válido';
  }

  if (number < 0) {
    return '$fieldName não pode ser negativo';
  }

  return null;
}

/// Valida se é um inteiro positivo
String? validatePositiveInteger(String? value, String fieldName) {
  if (value == null || value.isEmpty) {
    return '$fieldName é obrigatório';
  }

  final number = int.tryParse(value);
  if (number == null) {
    return '$fieldName deve ser um número inteiro';
  }

  if (number <= 0) {
    return '$fieldName deve ser maior que zero';
  }

  return null;
}

/// Valida formato de cor hexadecimal (#RRGGBB)
String? validateHexColor(String? value) {
  if (value == null || value.isEmpty) {
    return 'Cor é obrigatória';
  }

  if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) {
    return 'Formato inválido. Use: #RRGGBB';
  }

  return null;
}

/// Valida coordenada geográfica (latitude ou longitude)
String? validateCoordinate(String? value, String fieldName) {
  if (value == null || value.isEmpty) {
    return '$fieldName é obrigatória';
  }

  // Aceitar tanto vírgula quanto ponto como separador decimal
  final normalizedValue = value.replaceAll(',', '.');
  final number = double.tryParse(normalizedValue);

  if (number == null) {
    return '$fieldName deve ser um número válido';
  }

  return null;
}
