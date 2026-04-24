import 'package:flutter/material.dart';
import '../../models/restaurant.dart';
import '../../services/category_service.dart';

/// Widget para selecionar múltiplas categorias
class CategorySelector extends StatefulWidget {
  final List<int> selectedCategoryIds;
  final ValueChanged<List<int>> onSelectionChanged;

  const CategorySelector({
    super.key,
    required this.selectedCategoryIds,
    required this.onSelectionChanged,
  });

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  final CategoryService _categoryService = CategoryService();
  List<Category>? _categories;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categories = await _categoryService.getAllCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar categorias';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCategories,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_categories == null || _categories!.isEmpty) {
      return const Center(
        child: Text('Nenhuma categoria disponível'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecione pelo menos 1 categoria',
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories!.map((category) {
            final isSelected = widget.selectedCategoryIds.contains(category.id);
            
            return FilterChip(
              label: Text(category.name),
              selected: isSelected,
              onSelected: (selected) {
                _toggleCategory(category.id, selected);
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
              avatar: !isSelected
                  ? null
                  : Icon(
                      Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                      size: 18,
                    ),
            );
          }).toList(),
        ),

        if (widget.selectedCategoryIds.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Selecione pelo menos uma categoria',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),

        if (widget.selectedCategoryIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${widget.selectedCategoryIds.length} categoria(s) selecionada(s)',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  void _toggleCategory(int categoryId, bool selected) {
    final newSelection = List<int>.from(widget.selectedCategoryIds);
    
    if (selected) {
      if (!newSelection.contains(categoryId)) {
        newSelection.add(categoryId);
      }
    } else {
      newSelection.remove(categoryId);
    }

    widget.onSelectionChanged(newSelection);
  }
}
