package com.openbag.association.finance.dto;

import com.openbag.enums.MemberPaymentMethod;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

/** Baixa manual: como e quando o cooperado pagou (sem data = hoje) */
public record PayInvoiceRequest(@NotNull(message = "Informe como foi pago") MemberPaymentMethod method,
                                LocalDate paidOn,
                                @Size(max = 500) String notes) {
}
