package com.openbag.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OpeningHourDTO {

    @Size(max = 50, message = "Label deve ter no máximo 50 caracteres")
    private String label;

    @NotNull(message = "Dia da semana é obrigatório")
    @Min(value = 1, message = "Dia da semana deve ser entre 1 (segunda) e 7 (domingo)")
    @Max(value = 7, message = "Dia da semana deve ser entre 1 (segunda) e 7 (domingo)")
    private Integer weekday;

    @NotNull(message = "Horário de abertura é obrigatório")
    private LocalTime openTime;

    @NotNull(message = "Horário de fechamento é obrigatório")
    private LocalTime closeTime;

    @Size(max = 255, message = "Observação deve ter no máximo 255 caracteres")
    private String observation;
}
