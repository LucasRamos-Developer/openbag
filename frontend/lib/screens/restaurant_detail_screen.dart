import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/restaurant.dart';
import '../models/product.dart';
import '../services/restaurant_service.dart';
import '../services/cart_service.dart';
import '../widgets/product_card.dart';
import '../widgets/cart_floating_button.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({
    Key? key,
    required this.restaurant,
  }) : super(key: key);

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen>
    with TickerProviderStateMixin {
  late RestaurantService _restaurantService;
  late CartService _cartService;
  late TabController _tabController;
  
  List<Product> _products = [];
  bool _isLoading = false;
  bool _isFavorite = false;

  final List<String> _categories = [
    'Todos',
    'Principais',
    'Bebidas',
    'Sobremesas',
    'Acompanhamentos',
  ];

  @override
  void initState() {
    super.initState();
    _restaurantService = Provider.of<RestaurantService>(context, listen: false);
    _cartService = Provider.of<CartService>(context, listen: false);
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _restaurantService.getRestaurantProducts(widget.restaurant.id!);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar produtos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Product> _getFilteredProducts(String category) {
    if (category == 'Todos') return _products;
    return _products.where((product) {
      // Assumindo que temos uma propriedade category no Product
      return product.name.toLowerCase().contains(category.toLowerCase());
    }).toList();
  }

  void _addToCart(Product product) {
    _cartService.addItem(product, 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} adicionado ao carrinho'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Ver carrinho',
          onPressed: () {
            Navigator.pushNamed(context, '/cart');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              stretch: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.restaurant.imageUrl != null
                        ? Image.network(
                            widget.restaurant.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.restaurant,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.restaurant,
                              size: 64,
                              color: Colors.grey,
                            ),
                          ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.restaurant.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '4.5', // Placeholder rating
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.access_time,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.restaurant.deliveryTime ?? '30-45 min',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.delivery_dining,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'R\$ ${widget.restaurant.deliveryFee?.toStringAsFixed(2) ?? '5,00'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isFavorite = !_isFavorite;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _isFavorite 
                              ? 'Adicionado aos favoritos' 
                              : 'Removido dos favoritos',
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    // TODO: Implementar compartilhamento
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Compartilhamento em breve')),
                    );
                  },
                ),
              ],
            ),
          ];
        },
        body: Column(
          children: [
            // Informações do restaurante
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.restaurant.description != null)
                    Text(
                      widget.restaurant.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.restaurant.address ?? 'Endereço não informado',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Tabs de categorias
            TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              tabs: _categories.map((category) => Tab(text: category)).toList(),
            ),
            
            // Lista de produtos
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _categories.map((category) {
                  final filteredProducts = _getFilteredProducts(category);
                  
                  if (_isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (filteredProducts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fastfood_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum produto encontrado',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ProductCard(
                          product: product,
                          onAddToCart: () => _addToCart(product),
                          onTap: () {
                            // TODO: Abrir detalhes do produto
                          },
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Consumer<CartService>(
        builder: (context, cartService, child) {
          if (cartService.itemCount > 0) {
            return CartFloatingButton(
              itemCount: cartService.itemCount,
              onPressed: () {
                Navigator.pushNamed(context, '/cart');
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
