import '../association/association.dart' show parseDate;

double _money(dynamic value) => (value as num?)?.toDouble() ?? 0;

enum LedgerAccount {
  GENERAL('Caixa da associação'),
  SOLIDARITY_FUND('Caixinha solidária');

  final String label;
  const LedgerAccount(this.label);

  static LedgerAccount fromName(String? name) => values.firstWhere((e) => e.name == name, orElse: () => GENERAL);
}

enum LedgerCategory {
  MEMBERSHIP_FEE('Mensalidade'),
  ADDON('Adicional'),
  CONTRIBUTION('Contribuição'),
  AID('Auxílio'),
  EXPENSE('Despesa'),
  OTHER('Outro');

  final String label;
  const LedgerCategory(this.label);

  static LedgerCategory fromName(String? name) => values.firstWhere((e) => e.name == name, orElse: () => OTHER);
}

/// Lançamento que o gestor registra à mão
enum ManualEntryKind {
  EXPENSE('Despesa', 'Saída do caixa da associação'),
  INCOME('Outra entrada', 'Entrada no caixa da associação'),
  CONTRIBUTION('Contribuição para a caixinha', 'Doação, rifa ou contribuição avulsa'),
  AID('Auxílio da caixinha', 'Ajuda a um cooperado que passou por um problema');

  final String label;
  final String description;
  const ManualEntryKind(this.label, this.description);
}

class LedgerEntry {
  final int id;
  final LedgerAccount account;
  final bool isIn;
  final LedgerCategory category;
  final double amount;
  final DateTime date;
  final String description;
  final String? memberName;
  final bool manual;

  const LedgerEntry({
    required this.id,
    required this.account,
    required this.isIn,
    required this.category,
    required this.amount,
    required this.date,
    required this.description,
    this.memberName,
    required this.manual,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => LedgerEntry(
        id: json['id'],
        account: LedgerAccount.fromName(json['account']),
        isIn: json['direction'] == 'IN',
        category: LedgerCategory.fromName(json['category']),
        amount: _money(json['amount']),
        date: parseDate(json['date']) ?? DateTime.now(),
        description: json['description'] ?? '',
        memberName: json['memberName'],
        manual: json['manual'] ?? false,
      );
}

class LedgerPage {
  final List<LedgerEntry> items;
  final int page;
  final bool hasMore;

  const LedgerPage({required this.items, required this.page, required this.hasMore});

  factory LedgerPage.fromJson(Map<String, dynamic> json) => LedgerPage(
        items: [for (final e in (json['content'] as List? ?? [])) LedgerEntry.fromJson(e)],
        page: json['number'] ?? 0,
        hasMore: !(json['last'] ?? true),
      );
}

class FinanceMonth {
  final DateTime month;
  final double inAmount;
  final double outAmount;
  final double fundIn;
  final double fundOut;

  const FinanceMonth({required this.month, required this.inAmount, required this.outAmount, required this.fundIn, required this.fundOut});

  factory FinanceMonth.fromJson(Map<String, dynamic> json) => FinanceMonth(
        month: parseDate(json['month']) ?? DateTime.now(),
        inAmount: _money(json['in']),
        outAmount: _money(json['out']),
        fundIn: _money(json['fundIn']),
        fundOut: _money(json['fundOut']),
      );
}

/// Painel financeiro: arrecadado, gasto, a receber e saldos no período
class FinanceSummary {
  final DateTime from;
  final DateTime to;
  final double collected;
  final double spent;
  final double receivable;
  final double overdue;
  final double generalBalance;
  final double fundBalance;
  final double fundIn;
  final double fundOut;
  final List<FinanceMonth> months;

  const FinanceSummary({
    required this.from,
    required this.to,
    required this.collected,
    required this.spent,
    required this.receivable,
    required this.overdue,
    required this.generalBalance,
    required this.fundBalance,
    required this.fundIn,
    required this.fundOut,
    required this.months,
  });

  factory FinanceSummary.fromJson(Map<String, dynamic> json) => FinanceSummary(
        from: parseDate(json['from']) ?? DateTime.now(),
        to: parseDate(json['to']) ?? DateTime.now(),
        collected: _money(json['collected']),
        spent: _money(json['spent']),
        receivable: _money(json['receivable']),
        overdue: _money(json['overdue']),
        generalBalance: _money(json['generalBalance']),
        fundBalance: _money(json['fundBalance']),
        fundIn: _money(json['fundIn']),
        fundOut: _money(json['fundOut']),
        months: [for (final m in (json['months'] as List? ?? [])) FinanceMonth.fromJson(m)],
      );
}

class FundMovement {
  final DateTime date;
  final bool isIn;
  final double amount;
  final String description;

  const FundMovement({required this.date, required this.isIn, required this.amount, required this.description});

  factory FundMovement.fromJson(Map<String, dynamic> json) => FundMovement(
        date: parseDate(json['date']) ?? DateTime.now(),
        isIn: json['in'] ?? true,
        amount: _money(json['amount']),
        description: json['description'] ?? '',
      );
}

/// A caixinha vista pelo cooperado (sem os nomes de quem recebeu auxílio)
class SolidarityFund {
  final double balance;
  final double totalIn;
  final double totalOut;
  final int aids;
  final double myContribution;
  final List<FundMovement> recent;

  const SolidarityFund({
    required this.balance,
    required this.totalIn,
    required this.totalOut,
    required this.aids,
    required this.myContribution,
    required this.recent,
  });

  factory SolidarityFund.fromJson(Map<String, dynamic> json) => SolidarityFund(
        balance: _money(json['balance']),
        totalIn: _money(json['totalIn']),
        totalOut: _money(json['totalOut']),
        aids: json['aids'] ?? 0,
        myContribution: _money(json['myContribution']),
        recent: [for (final m in (json['recent'] as List? ?? [])) FundMovement.fromJson(m)],
      );
}
