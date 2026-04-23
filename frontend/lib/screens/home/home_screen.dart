import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../services/restaurant_service.dart';
import '../../widgets/restaurant_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RestaurantService>().fetchRestaurants();
      context.read<RestaurantService>().fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Open Bag'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => context.push('/cart'),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: Consumer<RestaurantService>(
        builder: (context, restaurantService, child) {
          if (restaurantService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (restaurantService.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(restaurantService.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => restaurantService.fetchRestaurants(),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          final restaurants = restaurantService.restaurants;
          
          if (restaurants.isEmpty) {
            return const Center(
              child: Text('Nenhum restaurante disponível'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: restaurants.length,
            itemBuilder: (context, index) {
              final restaurant = restaurants[index];
              return RestaurantCard(
                restaurant: restaurant,
                onTap: () => context.push('/restaurant/${restaurant.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
