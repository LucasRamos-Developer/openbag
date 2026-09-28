package com.openbag.modules.cooperative.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * A caixinha vista pelo cooperado: saldo, quanto entrou e saiu e as movimentações recentes. Os auxílios aparecem
 * sem o nome de quem recebeu.
 */
public record SolidarityFundDTO(BigDecimal balance, BigDecimal totalIn, BigDecimal totalOut, long aids,
                                BigDecimal myContribution, List<Movement> recent) {

    public record Movement(LocalDate date, boolean in, BigDecimal amount, String description) {
    }
}
