import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/restaurant.dart';

class CategoryService {
  static const String baseUrl = 'http://localhost:8080/api';

  /// Busca todas as categorias disponíveis
  Future<List<Category>> getAllCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Se a resposta for paginada, extrair o conteúdo
        if (data is Map && data.containsKey('content')) {
          final categories = (data['content'] as List)
              .map((cat) => Category.fromJson(cat))
              .toList();
          return categories;
        }
        
        // Se for uma lista direta
        if (data is List) {
          final categories = data
              .map((cat) => Category.fromJson(cat))
              .toList();
          return categories;
        }

        return [];
      } else {
        throw Exception('Erro ao buscar categorias: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar categorias: $e');
    }
  }

  /// Busca categorias por IDs específicos
  Future<List<Category>> getCategoriesByIds(List<int> ids) async {
    if (ids.isEmpty) return [];

    try {
      final allCategories = await getAllCategories();
      return allCategories.where((cat) => ids.contains(cat.id)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar categorias: $e');
    }
  }
}
