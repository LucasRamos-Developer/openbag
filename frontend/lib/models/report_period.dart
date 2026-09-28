/// Períodos prontos dos relatórios (Caixa da loja e relatórios da associação)
enum ReportPeriod {
  today('Hoje'),
  yesterday('Ontem'),
  week('7 dias'),
  month('Este mês'),
  lastMonth('Mês passado');

  final String label;

  const ReportPeriod(this.label);

  /// Datas locais, [início, fim] inclusivo
  (DateTime, DateTime) range(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      ReportPeriod.today => (today, today),
      ReportPeriod.yesterday => (today.subtract(const Duration(days: 1)), today.subtract(const Duration(days: 1))),
      ReportPeriod.week => (today.subtract(const Duration(days: 6)), today),
      ReportPeriod.month => (DateTime(now.year, now.month, 1), today),
      ReportPeriod.lastMonth => (DateTime(now.year, now.month - 1, 1), DateTime(now.year, now.month, 0)),
    };
  }
}
