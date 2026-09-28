package com.openbag.modules.cooperative.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Faturas de um mês. {@code preview} = mês em andamento (valores parciais). {@code missing} = cooperados
 * ainda sem fatura num mês fechado (o botão "Gerar faturas" cria as que faltam).
 */
public record InvoiceMonthDTO(LocalDate month, boolean preview, int missing, List<InvoiceDTO> invoices,
                              Totals totals) {

    public record Totals(int count, BigDecimal total, BigDecimal paid, BigDecimal open, BigDecimal overdue,
                         BigDecimal waived) {
    }
}
