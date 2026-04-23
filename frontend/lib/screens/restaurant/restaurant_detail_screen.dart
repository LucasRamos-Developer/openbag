import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/restaurant.dart';
import '../../services/restaurant_service.dart';

class RestaurantDetailScreen extends StatefulWidget {
  final String restaurantId;

  const RestaurantDetailScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  State<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends State<RestaurantDetailScreen> {
  Restaurant? _restaurant;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurant();
  }

  Future<void> _loadRestaurant() async {
    final restaurantService = context.read<RestaurantService>();
    final restaurant = await restaurantService.getRestaurantById(widget.restaurantId);
    
    if (mounted) {
      setState(() {
        _restaurant = restaurant;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_restaurant == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Restaurante')),
        body: const Center(
          child: Text('Restaurante não encontrado'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_restaurant!.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_restaurant!.bannerUrl != null)
              Image.network(
                _restaurant!.bannerUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 64),
                  );
                },
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _restaurant!.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(_restaurant!.description),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text('${_restaurant!.formattedRating} (${_restaurant!.totalReviews})'),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, size: 20),
                      const SizedBox(width: 4),
                      Text(_restaurant!.deliveryTimeRange),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Taxa de entrega: R\$ ${_restaurant!.deliveryFee.toStringAsFixed(2)}'),
                  Text('Pedido mínimo: R\$ ${_restaurant!.minimumOrder.toStringAsFixed(2)}'),
                  const SizedBox(height: 16),
                  // TODO: Add menu items here
                  const Text('Cardápio em breve...'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
