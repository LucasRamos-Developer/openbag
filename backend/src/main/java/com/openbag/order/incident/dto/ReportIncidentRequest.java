package com.openbag.order.incident.dto;

import com.openbag.order.incident.entity.IncidentType;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** Ocorrência relatada pelo entregador: o tipo e, se quiser (obrigatória em "outro"), uma observação */
public record ReportIncidentRequest(@NotNull IncidentType type, @Size(max = 300) String note) {
}
