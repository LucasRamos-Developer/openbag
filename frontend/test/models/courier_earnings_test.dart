import 'package:flutter_test/flutter_test.dart';
import 'package:open_bag/models/courier/courier_earnings.dart';
import 'package:open_bag/models/courier/vehicle.dart';

void main() {
  test('lê os km de cada quadro e os km, tempo e médias do período', () {
    final earnings = CourierEarnings.fromJson({
      'today': {'amount': 18, 'deliveries': 2, 'distanceKm': 6.0},
      'week': {'amount': 18, 'deliveries': 2},
      'month': {'amount': 18, 'deliveries': 2},
      'period': {'amount': 18, 'deliveries': 2},
      'daily': [],
      'deliveries': [],
      'stats': {
        'deliveryKm': 5.0,
        'pickupKm': 1.0,
        'totalKm': 6.0,
        'onlineMinutes': 180,
        'deliveringMinutes': 50,
        'perDelivery': {'amount': 9, 'distanceKm': 2.5, 'minutes': 25},
        'perKm': 3,
        'perHour': 6,
      },
    });

    expect(earnings.today.distanceKm, 6.0);
    expect(earnings.week.distanceKm, 0, reason: 'servidor antigo, sem km');
    expect(earnings.stats!.onlineMinutes, 180);
    expect(earnings.stats!.amountPerDelivery, 9);
    expect(earnings.stats!.minutesPerDelivery, 25);
    expect(earnings.stats!.perHour, 6);
  });

  test('sem entregas nem turnos, as médias ficam vazias', () {
    final stats = CourierWorkStats.fromJson({'totalKm': 0, 'onlineMinutes': 0});

    expect(stats.amountPerDelivery, isNull);
    expect(stats.perKm, isNull);
    expect(stats.perHour, isNull);
  });

  test('resultado estimado: partes informadas, a que falta e o veículo incompleto', () {
    final cost = VehicleCostEstimate.fromJson({
      'distanceKm': 386.0,
      'revenue': 520,
      'fuel': 68.38,
      'maintenance': 69.48,
      'depreciation': null,
      'total': 137.86,
      'result': 382.14,
      'complete': false,
      'vehicles': [
        {'vehicleId': 3, 'name': 'Honda CG 160', 'distanceKm': 386.0, 'complete': false},
      ],
    });

    expect(cost.fuel, 68.38);
    expect(cost.depreciation, isNull, reason: 'não informado não é zero');
    expect(cost.complete, isFalse);
    expect(cost.vehicles.single.name, 'Honda CG 160');
    expect(CourierEarnings.fromJson({'daily': [], 'deliveries': []}).cost, isNull,
        reason: 'sem custos, o card convida a preencher');
  });

  test('custos do veículo: moto usa combustível, bicicleta não', () {
    final moto = Vehicle.fromJson({'id': 1, 'type': 'MOTORCYCLE', 'maintenancePerKm': 0.18});
    final bike = Vehicle.fromJson({'id': 2, 'type': 'BICYCLE'});

    expect(moto.usesFuel, isTrue);
    expect(moto.hasCosts, isTrue);
    expect(moto.maintenancePerKm, 0.18);
    expect(bike.usesFuel, isFalse);
    expect(bike.hasCosts, isFalse);
  });
}
