package com.openbag.entity;

import jakarta.persistence.*;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalTime;

@Entity
@Table(name = "opening_hours")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class OpeningHour {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "restaurant_id", nullable = false)
    private Restaurant restaurant;

    @Size(max = 50, message = "Label deve ter no máximo 50 caracteres")
    @Column(length = 50)
    private String label;

    @NotNull(message = "Dia da semana é obrigatório")
    @Min(value = 1, message = "Dia da semana deve ser entre 1 (segunda) e 7 (domingo)")
    @Max(value = 7, message = "Dia da semana deve ser entre 1 (segunda) e 7 (domingo)")
    @Column(nullable = false)
    private Integer weekday;

    @NotNull(message = "Horário de abertura é obrigatório")
    @Column(name = "open_time", nullable = false)
    private LocalTime openTime;

    @NotNull(message = "Horário de fechamento é obrigatório")
    @Column(name = "close_time", nullable = false)
    private LocalTime closeTime;

    @Size(max = 255, message = "Observação deve ter no máximo 255 caracteres")
    @Column(length = 255)
    private String observation;
}
