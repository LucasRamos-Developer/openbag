import '../../utils/formatters.dart';
import '../association/association.dart' show parseDate;

double _money(dynamic value) => (value as num?)?.toDouble() ?? 0;
double? _moneyOrNull(dynamic value) => (value as num?)?.toDouble();

/// Como a associação cobra a mensalidade
enum FeeMode {
  FIXED('Valor fixo', 'O mesmo valor todo mês'),
  PERCENTAGE('Percentual dos ganhos', 'Um percentual do que o cooperado ganhou no mês, até um teto');

  final String label;
  final String description;
  const FeeMode(this.label, this.description);

  static FeeMode? fromName(String? name) => values.where((e) => e.name == name).firstOrNull;
}

/// Cobrança da mensalidade: fixa ou percentual dos ganhos até o teto (depois do teto, só os adicionais)
class FeePolicy {
  final FeeMode? mode;
  final double? fixedAmount;
  final double? percentage;
  final double? monthlyCap;
  final int dueDay;
  final bool configured;

  const FeePolicy({this.mode, this.fixedAmount, this.percentage, this.monthlyCap, this.dueDay = 10, this.configured = false});

  factory FeePolicy.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const FeePolicy();
    return FeePolicy(
      mode: FeeMode.fromName(json['mode']),
      fixedAmount: _moneyOrNull(json['fixedAmount']),
      percentage: _moneyOrNull(json['percentage']),
      monthlyCap: _moneyOrNull(json['monthlyCap']),
      dueDay: json['dueDay'] ?? 10,
      configured: json['configured'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'mode': mode?.name,
        'fixedAmount': fixedAmount,
        'percentage': percentage,
        'monthlyCap': monthlyCap,
        'dueDay': dueDay,
      };

  /// "5% dos ganhos, até R$ 100,00" ou "R$ 80,00 por mês"
  String get summary {
    if (!configured || mode == null) return 'Cobrança ainda não definida';
    if (mode == FeeMode.FIXED) return '${formatMoney(fixedAmount ?? 0)} por mês';
    final pct = '${formatPercent(percentage ?? 0)} dos ganhos';
    return monthlyCap != null ? '$pct, até ${formatMoney(monthlyCap!)}' : pct;
  }
}

/// Como um adicional é cobrado
enum AddonPricing {
  PERCENT_OF_FEE('% da mensalidade'),
  FIXED('Valor fixo por mês');

  final String label;
  const AddonPricing(this.label);

  static AddonPricing fromName(String? name) => values.firstWhere((e) => e.name == name, orElse: () => FIXED);
}

String _addonPrice(AddonPricing pricing, double value) =>
    pricing == AddonPricing.PERCENT_OF_FEE ? '+${formatPercent(value)} na mensalidade' : '${formatMoney(value)}/mês';

/// Adicional oferecido pela associação (ex: seguro de vida)
class AddonPlan {
  final int id;
  final String name;
  final String? description;
  final AddonPricing pricing;
  final double value;
  final bool active;
  final int activeMembers;
  final int proposedMembers;

  const AddonPlan({
    required this.id,
    required this.name,
    this.description,
    required this.pricing,
    required this.value,
    required this.active,
    this.activeMembers = 0,
    this.proposedMembers = 0,
  });

  factory AddonPlan.fromJson(Map<String, dynamic> json) => AddonPlan(
        id: json['id'],
        name: json['name'] ?? '',
        description: json['description'],
        pricing: AddonPricing.fromName(json['pricing']),
        value: _money(json['value']),
        active: json['active'] ?? true,
        activeMembers: json['activeMembers'] ?? 0,
        proposedMembers: json['proposedMembers'] ?? 0,
      );

  String get priceLabel => _addonPrice(pricing, value);
}

enum MemberAddonStatus {
  PROPOSED('Aguardando resposta'),
  ACTIVE('Ativo'),
  DECLINED('Recusado'),
  CANCELLED('Cancelado');

  final String label;
  const MemberAddonStatus(this.label);

  static MemberAddonStatus fromName(String? name) =>
      values.firstWhere((e) => e.name == name, orElse: () => CANCELLED);
}

/// Adicional de um cooperado
class MemberAddon {
  final int id;
  final int planId;
  final String name;
  final String? description;
  final AddonPricing pricing;
  final double value;
  final MemberAddonStatus status;
  final DateTime? proposedAt;
  final String memberName;

  const MemberAddon({
    required this.id,
    required this.planId,
    required this.name,
    this.description,
    required this.pricing,
    required this.value,
    required this.status,
    this.proposedAt,
    this.memberName = '',
  });

  factory MemberAddon.fromJson(Map<String, dynamic> json) => MemberAddon(
        id: json['id'],
        planId: json['planId'],
        name: json['name'] ?? '',
        description: json['description'],
        pricing: AddonPricing.fromName(json['pricing']),
        value: _money(json['value']),
        status: MemberAddonStatus.fromName(json['status']),
        proposedAt: parseDate(json['proposedAt']),
        memberName: json['memberName'] ?? '',
      );

  String get priceLabel => _addonPrice(pricing, value);
  bool get isOpen => status == MemberAddonStatus.PROPOSED || status == MemberAddonStatus.ACTIVE;
}

enum InvoiceStatus {
  OPEN('Em aberto'),
  PAID('Paga'),
  WAIVED('Dispensada');

  final String label;
  const InvoiceStatus(this.label);

  static InvoiceStatus fromName(String? name) => values.firstWhere((e) => e.name == name, orElse: () => OPEN);
}

enum InvoiceLineType { FEE, ADDON, SOLIDARITY }

enum MemberPaymentMethod {
  PIX('Pix'),
  CASH('Dinheiro'),
  TRANSFER('Transferência'),
  OTHER('Outro');

  final String label;
  const MemberPaymentMethod(this.label);

  static MemberPaymentMethod? fromName(String? name) => values.where((e) => e.name == name).firstOrNull;
}

class InvoiceLine {
  final InvoiceLineType type;
  final String description;
  final double amount;

  const InvoiceLine({required this.type, required this.description, required this.amount});

  factory InvoiceLine.fromJson(Map<String, dynamic> json) => InvoiceLine(
        type: InvoiceLineType.values.firstWhere((e) => e.name == json['type'], orElse: () => InvoiceLineType.FEE),
        description: json['description'] ?? '',
        amount: _money(json['amount']),
      );
}

/// Fatura mensal do cooperado. [preview] = mês em andamento (valores parciais, sem id)
class Invoice {
  final int? id;
  final bool preview;
  final int membershipId;
  final int? memberNumber;
  final String memberName;
  final DateTime month;
  final double earnings;
  final int deliveries;
  final List<InvoiceLine> lines;
  final double total;
  final InvoiceStatus status;
  final DateTime? dueDate;
  final bool overdue;
  final DateTime? paidOn;
  final MemberPaymentMethod? paymentMethod;
  final String? notes;

  const Invoice({
    this.id,
    required this.preview,
    required this.membershipId,
    this.memberNumber,
    required this.memberName,
    required this.month,
    required this.earnings,
    required this.deliveries,
    required this.lines,
    required this.total,
    required this.status,
    this.dueDate,
    required this.overdue,
    this.paidOn,
    this.paymentMethod,
    this.notes,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['id'],
        preview: json['preview'] ?? false,
        membershipId: json['membershipId'],
        memberNumber: json['memberNumber'],
        memberName: json['memberName'] ?? '',
        month: parseDate(json['month']) ?? DateTime.now(),
        earnings: _money(json['earnings']),
        deliveries: json['deliveries'] ?? 0,
        lines: [for (final l in (json['lines'] as List? ?? [])) InvoiceLine.fromJson(l)],
        total: _money(json['total']),
        status: InvoiceStatus.fromName(json['status']),
        dueDate: parseDate(json['dueDate']),
        overdue: json['overdue'] ?? false,
        paidOn: parseDate(json['paidOn']),
        paymentMethod: MemberPaymentMethod.fromName(json['paymentMethod']),
        notes: json['notes'],
      );

  String get memberLabel => memberNumber != null ? '$memberName · nº $memberNumber' : memberName;
}

class InvoiceTotals {
  final int count;
  final double total;
  final double paid;
  final double open;
  final double overdue;
  final double waived;

  const InvoiceTotals({this.count = 0, this.total = 0, this.paid = 0, this.open = 0, this.overdue = 0, this.waived = 0});

  factory InvoiceTotals.fromJson(Map<String, dynamic>? json) => json == null
      ? const InvoiceTotals()
      : InvoiceTotals(
          count: json['count'] ?? 0,
          total: _money(json['total']),
          paid: _money(json['paid']),
          open: _money(json['open']),
          overdue: _money(json['overdue']),
          waived: _money(json['waived']),
        );
}

/// Faturas de um mês; [missing] = cooperados sem fatura num mês fechado
class InvoiceMonth {
  final DateTime month;
  final bool preview;
  final int missing;
  final List<Invoice> invoices;
  final InvoiceTotals totals;

  const InvoiceMonth({required this.month, required this.preview, required this.missing, required this.invoices, required this.totals});

  factory InvoiceMonth.fromJson(Map<String, dynamic> json) => InvoiceMonth(
        month: parseDate(json['month']) ?? DateTime.now(),
        preview: json['preview'] ?? false,
        missing: json['missing'] ?? 0,
        invoices: [for (final i in (json['invoices'] as List? ?? [])) Invoice.fromJson(i)],
        totals: InvoiceTotals.fromJson(json['totals']),
      );
}

/// Faturas do cooperado logado: a prévia do mês e o histórico
class MyInvoices {
  final FeePolicy policy;
  final Invoice? current;
  final List<Invoice> history;
  final double solidarityContribution;

  const MyInvoices({required this.policy, this.current, required this.history, this.solidarityContribution = 0});

  factory MyInvoices.fromJson(Map<String, dynamic> json) => MyInvoices(
        policy: FeePolicy.fromJson(json['policy']),
        current: json['current'] != null ? Invoice.fromJson(json['current']) : null,
        history: [for (final i in (json['history'] as List? ?? [])) Invoice.fromJson(i)],
        solidarityContribution: _money(json['solidarityContribution']),
      );

  List<Invoice> get open => history.where((i) => i.status == InvoiceStatus.OPEN).toList();
}
