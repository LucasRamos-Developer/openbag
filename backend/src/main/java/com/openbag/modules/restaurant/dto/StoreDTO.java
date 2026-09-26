package com.openbag.modules.restaurant.dto;

import com.openbag.enums.AcceptanceMode;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Situação e configurações de operação da loja (aba "Loja" do painel do dono)
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StoreDTO {

    private Long id;
    private String name;
    private String slug;
    private String logoUrl;
    private String bannerUrl;
    private boolean active;

    // "Fechar agora" manual
    private boolean open;
    // Resultado final: ativo, aberto, sem pausa e dentro do horário
    private boolean openNow;
    private LocalDateTime pausedUntil;

    private AcceptanceMode acceptanceMode;
    private Integer acceptanceTimeoutMinutes;
    private Integer defaultPreparationMinutes;
    private BigDecimal deliveryFee;
    private BigDecimal minimumOrder;
    private Integer deliveryTimeMin;
    private Integer deliveryTimeMax;
    private String priceRange;
    private boolean autoPrintTicket;

    private List<OpeningHourDTO> openingHours;
}
