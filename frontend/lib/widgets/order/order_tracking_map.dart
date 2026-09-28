import 'package:flutter/material.dart';
import '../../core/ui/ui.dart';
import '../../models/order/order.dart';

/// Entregador a caminho no mapa do cliente: loja, destino e a posição do entregador.
/// A câmera enquadra só a loja e o destino, para não pular a cada nova posição do entregador.
/// Cores bem distintas: loja em preto, destino em azul e entregador na cor principal (maior).
class OrderTrackingMap extends StatelessWidget {
  final Order order;
  final GeoPosition courier;
  final double height;

  const OrderTrackingMap({super.key, required this.order, required this.courier, this.height = 260});

  static const _destinationColor = Color(0xFF2A78D6);

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final courierPoint = AppMapPoint(courier.latitude, courier.longitude);
    final store = order.restaurant.latitude != null && order.restaurant.longitude != null
        ? AppMapPoint(order.restaurant.latitude!, order.restaurant.longitude!)
        : null;
    final destination = order.deliveryLatitude != null && order.deliveryLongitude != null
        ? AppMapPoint(order.deliveryLatitude!, order.deliveryLongitude!)
        : null;
    final fit = [if (store != null) store, if (destination != null) destination];

    return Semantics(
      label: 'Mapa com a posição do entregador',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(
          height: height,
          child: AppMap(
            center: courierPoint,
            zoom: 15,
            fitPoints: fit.length > 1 ? fit : const [],
            markers: [
              if (store != null) AppMapMarker(point: store, color: const Color(0xFF1A1A19), radius: 9, caption: 'Loja'),
              if (destination != null) AppMapMarker(point: destination, color: _destinationColor, radius: 10, caption: 'Você'),
              AppMapMarker(point: courierPoint, color: c.primary, radius: 13, caption: 'Entregador'),
            ],
          ),
        ),
      ),
    );
  }
}
