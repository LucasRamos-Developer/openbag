import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/restaurant.dart';
import '../../utils/maps.dart';

/// Botão quadrado "Abrir no mapa": mostra a loja no app de mapas do cliente
class OpenInMapsButton extends StatelessWidget {
  final Address address;
  final String? label;

  const OpenInMapsButton({super.key, required this.address, this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Tooltip(
      message: 'Abrir no mapa',
      child: Material(
        color: c.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => openPlaceInMaps(
            latitude: address.latitude,
            longitude: address.longitude,
            label: label,
            address: address.fullAddress,
          ),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(Icons.directions_outlined, color: c.primaryText, size: 22),
          ),
        ),
      ),
    );
  }
}
