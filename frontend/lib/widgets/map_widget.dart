import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapWidget extends StatefulWidget {
  final LatLng? initialLocation;
  final List<MapMarker>? markers;
  final Function(LatLng)? onLocationSelected;
  final double zoom;
  final bool showCurrentLocation;

  const MapWidget({
    super.key,
    this.initialLocation,
    this.markers,
    this.onLocationSelected,
    this.zoom = 13.0,
    this.showCurrentLocation = true,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  LatLng? _selectedLocation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.showCurrentLocation) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      // Move o mapa para a localização atual
      _mapController.move(_currentLocation!, widget.zoom);
    } catch (e) {
      setState(() => _isLoading = false);
      print('Erro ao obter localização: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            center: widget.initialLocation ?? 
                   _currentLocation ?? 
                   const LatLng(-23.550520, -46.633308), // São Paulo como padrão
            zoom: widget.zoom,
            onTap: (tapPosition, point) {
              if (widget.onLocationSelected != null) {
                setState(() => _selectedLocation = point);
                widget.onLocationSelected!(point);
              }
            },
          ),
          children: [
            // Camada de tiles do OpenStreetMap
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.openbag.app',
              maxZoom: 19,
            ),
            
            // Marcadores
            MarkerLayer(
              markers: _buildMarkers(),
            ),
          ],
        ),
        
        // Loading indicator
        if (_isLoading)
          const Positioned(
            top: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
        
        // Botão para centralizar na localização atual
        if (widget.showCurrentLocation)
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              onPressed: _getCurrentLocation,
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.my_location),
            ),
          ),
      ],
    );
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    // Localização atual
    if (_currentLocation != null) {
      markers.add(
        Marker(
          point: _currentLocation!,
          width: 40,
          height: 40,
          builder: (context) => Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }

    // Localização selecionada
    if (_selectedLocation != null) {
      markers.add(
        Marker(
          point: _selectedLocation!,
          width: 40,
          height: 40,
          builder: (context) => Container(
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      );
    }

    // Marcadores customizados
    if (widget.markers != null) {
      for (var mapMarker in widget.markers!) {
        markers.add(
          Marker(
            point: mapMarker.position,
            width: 40,
            height: 40,
            builder: (context) => GestureDetector(
              onTap: mapMarker.onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: mapMarker.color ?? Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  mapMarker.icon ?? Icons.location_on,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }
}

class MapMarker {
  final LatLng position;
  final String? title;
  final String? description;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  MapMarker({
    required this.position,
    this.title,
    this.description,
    this.icon,
    this.color,
    this.onTap,
  });
}
