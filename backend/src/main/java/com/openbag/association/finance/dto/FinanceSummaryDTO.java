package com.openbag.association.finance.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Painel financeiro da associação no período: arrecadado, gasto, a receber e os saldos (caixa geral e caixinha),
 * com a série mensal de entradas e saídas para o gráfico
 */
public record FinanceSummaryDTO(LocalDate from, LocalDate to, BigDecimal collected, BigDecimal spent,
                                BigDecimal receivable, BigDecimal overdue, BigDecimal generalBalance,
                                BigDecimal fundBalance, BigDecimal fundIn, BigDecimal fundOut,
                                List<Month> months) {

    public record Month(LocalDate month, BigDecimal in, BigDecimal out, BigDecimal fundIn, BigDecimal fundOut) {
    }
}
