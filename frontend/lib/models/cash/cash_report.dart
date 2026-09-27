import '../order/order.dart';
import '../../utils/formatters.dart';

double _money(dynamic v) => (v as num?)?.toDouble() ?? 0;

/// Caixa da loja num período: vendas, formas de pagamento, acerto por entregador e acertos feitos
class CashReport {
  final DateTime from;
  final DateTime to;
  final CashSummary summary;
  final List<PaymentLine> payments;
  final List<CourierCashLine> couriers;
  final List<Settlement> settlements;

  CashReport({
    required this.from,
    required this.to,
    required this.summary,
    required this.payments,
    required this.couriers,
    required this.settlements,
  });

  factory CashReport.fromJson(Map<String, dynamic> json) => CashReport(
        from: DateTime.parse(json['from']),
        to: DateTime.parse(json['to']),
        summary: CashSummary.fromJson(json['summary']),
        payments: [for (final p in json['payments'] as List? ?? []) PaymentLine.fromJson(p)],
        couriers: [for (final c in json['couriers'] as List? ?? []) CourierCashLine.fromJson(c)],
        settlements: [for (final s in json['settlements'] as List? ?? []) Settlement.fromJson(s)],
      );
}

class CashSummary {
  final int deliveredOrders;
  final int cancelledOrders;
  final double productSales;
  final double deliveryFees;
  final double totalReceived;
  final double paidToCouriers;
  final double restaurantSubsidy;

  /// Recebido dos clientes − pago aos entregadores
  final double storeBalance;
  final double averageTicket;

  /// Entregas marcadas pela loja sem entregador atribuído
  final int withoutCourier;

  CashSummary({
    required this.deliveredOrders,
    required this.cancelledOrders,
    required this.productSales,
    required this.deliveryFees,
    required this.totalReceived,
    required this.paidToCouriers,
    required this.restaurantSubsidy,
    required this.storeBalance,
    required this.averageTicket,
    required this.withoutCourier,
  });

  factory CashSummary.fromJson(Map<String, dynamic> json) => CashSummary(
        deliveredOrders: json['deliveredOrders'] ?? 0,
        cancelledOrders: json['cancelledOrders'] ?? 0,
        productSales: _money(json['productSales']),
        deliveryFees: _money(json['deliveryFees']),
        totalReceived: _money(json['totalReceived']),
        paidToCouriers: _money(json['paidToCouriers']),
        restaurantSubsidy: _money(json['restaurantSubsidy']),
        storeBalance: _money(json['storeBalance']),
        averageTicket: _money(json['averageTicket']),
        withoutCourier: json['withoutCourier'] ?? 0,
      );
}

class PaymentLine {
  final PaymentMethod method;
  final int orders;
  final double amount;

  PaymentLine({required this.method, required this.orders, required this.amount});

  factory PaymentLine.fromJson(Map<String, dynamic> json) => PaymentLine(
        method: PaymentMethod.fromName(json['method']),
        orders: json['orders'] ?? 0,
        amount: _money(json['amount']),
      );
}

/// Um entregador no período e o que falta acertar com ele (de qualquer data)
class CourierCashLine {
  final bool staff;
  final int? deliveryPersonId;
  final int? staffCourierId;
  final String name;
  final String? photoUrl;
  final int deliveries;
  final double earnings;
  final double cashCollected;
  final double otherCollected;
  final int pendingOrders;
  final double pendingCash;
  final double pendingEarnings;

  /// Positivo = o entregador devolve à loja; negativo = a loja paga a ele
  final double pendingBalance;

  CourierCashLine({
    required this.staff,
    this.deliveryPersonId,
    this.staffCourierId,
    required this.name,
    this.photoUrl,
    required this.deliveries,
    required this.earnings,
    required this.cashCollected,
    required this.otherCollected,
    required this.pendingOrders,
    required this.pendingCash,
    required this.pendingEarnings,
    required this.pendingBalance,
  });

  bool get hasPending => pendingOrders > 0;

  factory CourierCashLine.fromJson(Map<String, dynamic> json) => CourierCashLine(
        staff: json['kind'] == 'STAFF',
        deliveryPersonId: json['deliveryPersonId'],
        staffCourierId: json['staffCourierId'],
        name: json['name'] ?? '',
        photoUrl: json['photoUrl'],
        deliveries: json['deliveries'] ?? 0,
        earnings: _money(json['earnings']),
        cashCollected: _money(json['cashCollected']),
        otherCollected: _money(json['otherCollected']),
        pendingOrders: json['pendingOrders'] ?? 0,
        pendingCash: _money(json['pendingCash']),
        pendingEarnings: _money(json['pendingEarnings']),
        pendingBalance: _money(json['pendingBalance']),
      );
}

/// Acerto feito; saldo positivo = o entregador devolveu à loja
class Settlement {
  final int id;
  final bool staff;
  final String name;
  final int ordersCount;
  final double cashCollected;
  final double courierEarnings;
  final double balance;
  final DateTime? settledAt;
  final String? settledBy;

  Settlement({
    required this.id,
    required this.staff,
    required this.name,
    required this.ordersCount,
    required this.cashCollected,
    required this.courierEarnings,
    required this.balance,
    this.settledAt,
    this.settledBy,
  });

  factory Settlement.fromJson(Map<String, dynamic> json) => Settlement(
        id: json['id'],
        staff: json['kind'] == 'STAFF',
        name: json['name'] ?? '',
        ordersCount: json['ordersCount'] ?? 0,
        cashCollected: _money(json['cashCollected']),
        courierEarnings: _money(json['courierEarnings']),
        balance: _money(json['balance']),
        settledAt: json['settledAt'] != null ? DateTime.tryParse(json['settledAt']) : null,
        settledBy: json['settledBy'],
      );
}

/// Como mostrar o saldo do acerto: quem deve a quem
String settlementBalanceLabel(double balance) {
  if (balance.abs() < 0.005) return 'Sem saldo';
  return balance > 0 ? 'Devolve ${formatMoney(balance)} à loja' : 'Loja paga ${formatMoney(-balance)}';
}
