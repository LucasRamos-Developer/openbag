import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/restaurant.dart';
import '../services/restaurant_service.dart';
import '../widgets/restaurant_card.dart';
import '../widgets/category_list.dart';
import '../widgets/search_bar.dart' as custom;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late RestaurantService _restaurantService;
  List<Restaurant> _restaurants = [];
  List<Restaurant> _filteredRestaurants = [];
  bool _isLoading = false;
  String _selectedCategory = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _restaurantService = Provider.of<RestaurantService>(context, listen: false);
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final restaurants = await _restaurantService.getAllRestaurants();
      setState(() {
        _restaurants = restaurants;
        _filteredRestaurants = restaurants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar restaurantes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterRestaurants() {
    setState(() {
      _filteredRestaurants = _restaurants.where((restaurant) {
        final matchesCategory = _selectedCategory.isEmpty || 
            restaurant.category.toLowerCase() == _selectedCategory.toLowerCase();
        final matchesSearch = _searchQuery.isEmpty ||
            restaurant.name.toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _filterRestaurants();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterRestaurants();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenBag'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () {
              // TODO: Implementar seleção de localização
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Seleção de localização em breve')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implementar notificações
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notificações em breve')),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadRestaurants,
        child: CustomScrollView(
          slivers: [
            // Header com busca
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Boa refeição!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'O que você gostaria de comer hoje?',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    custom.SearchBar(
                      onChanged: _onSearchChanged,
                      hintText: 'Buscar restaurantes...',
                    ),
                  ],
                ),
              ),
            ),

            // Lista de categorias
            SliverToBoxAdapter(
              child: CategoryList(
                onCategorySelected: _onCategorySelected,
                selectedCategory: _selectedCategory,
              ),
            ),

            // Seção de restaurantes
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Restaurantes próximos',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // TODO: Implementar "Ver todos"
                      },
                      child: const Text('Ver todos'),
                    ),
                  ],
                ),
              ),
            ),

            // Lista de restaurantes
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_filteredRestaurants.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum restaurante encontrado',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tente ajustar os filtros de busca',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final restaurant = _filteredRestaurants[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: RestaurantCard(
                        restaurant: restaurant,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/restaurant',
                            arguments: restaurant,
                          );
                        },
                      ),
                    );
                  },
                  childCount: _filteredRestaurants.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
