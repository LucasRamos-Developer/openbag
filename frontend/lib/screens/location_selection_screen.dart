import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/map_widget.dart';
import '../models/restaurant.dart';

class LocationSelectionScreen extends StatefulWidget {
  final Function(LatLng)? onLocationSelected;
  final LatLng? initialLocation;
  final List<Restaurant>? nearbyRestaurants;

  const LocationSelectionScreen({
    super.key,
    this.onLocationSelected,
    this.initialLocation,
    this.nearbyRestaurants,
  });

  @override
  State<LocationSelectionScreen> createState() => _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  LatLng? _selectedLocation;
  String _selectedAddress = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Localização'),
        actions: [
          if (_selectedLocation != null)
            TextButton(
              onPressed: () {
                if (widget.onLocationSelected != null) {
                  widget.onLocationSelected!(_selectedLocation!);
                }
                Navigator.of(context).pop(_selectedLocation);
              },
              child: const Text(
                'Confirmar',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Informações da localização selecionada
          if (_selectedLocation != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Localização Selecionada:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (_selectedAddress.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _selectedAddress,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          
          // Mapa
          Expanded(
            child: MapWidget(
              initialLocation: widget.initialLocation,
              onLocationSelected: (location) {
                setState(() {
                  _selectedLocation = location;
                  _selectedAddress = 'Endereço aproximado: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
                });
              },
              markers: _buildRestaurantMarkers(),
            ),
          ),
        ],
      ),
    );
  }

  List<MapMarker> _buildRestaurantMarkers() {
    if (widget.nearbyRestaurants == null) return [];

    return widget.nearbyRestaurants!.map((restaurant) {
      if (restaurant.address?.latitude != null && restaurant.address?.longitude != null) {
        return MapMarker(
          position: LatLng(
            restaurant.address!.latitude!,
            restaurant.address!.longitude!,
          ),
          title: restaurant.name,
          description: restaurant.description,
          icon: Icons.restaurant,
          color: Theme.of(context).primaryColor,
          onTap: () {
            _showRestaurantDetails(restaurant);
          },
        );
      }
      return null;
    }).where((marker) => marker != null).cast<MapMarker>().toList();
  }

  void _showRestaurantDetails(Restaurant restaurant) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              restaurant.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              restaurant.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('${restaurant.rating}'),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 4),
                Text('${restaurant.deliveryTimeMin}-${restaurant.deliveryTimeMax} min'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navegar para detalhes do restaurante
                  Navigator.pushNamed(
                    context,
                    '/restaurant',
                    arguments: restaurant,
                  );
                },
                child: const Text('Ver Restaurante'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
