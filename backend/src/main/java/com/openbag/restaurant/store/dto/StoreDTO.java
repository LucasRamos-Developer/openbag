package com.openbag.restaurant.store.dto;

import com.openbag.restaurant.store.entity.DeliveryFeeMode;
import com.openbag.restaurant.store.entity.AcceptanceMode;
import com.openbag.restaurant.store.entity.RestaurantThemePreset;
import com.openbag.account.dto.AddressDTO;
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
    private String description;
    private String phoneNumber;
    private String cnpj;
    private List<Long> categoryIds;
    private List<String> categories;
    private AddressDTO address;
    private boolean active;

    // Avaliações dos clientes (média e total)
    private BigDecimal rating;
    private Integer totalReviews;

    // Aparência da página pública
    private RestaurantThemePreset themePreset;
    private String brandColor;
    private String slogan;

    // "Fechar agora" manual
    private boolean open;
    // Resultado final: ativo, aberto, sem pausa e dentro do horário
    private boolean openNow;
    private LocalDateTime pausedUntil;

    private AcceptanceMode acceptanceMode;
    private Integer acceptanceTimeoutMinutes;
    private Integer defaultPreparationMinutes;
    private BigDecimal deliveryFee;
    /** Com PASS_THROUGH a taxa fixa não é cobrada: o cliente paga pela distância */
    private DeliveryFeeMode deliveryFeeMode;
    private BigDecimal minimumOrder;
    private Integer deliveryTimeMin;
    private Integer deliveryTimeMax;
    private String priceRange;
    private boolean autoPrintTicket;

    private List<OpeningHourDTO> openingHours;
}
