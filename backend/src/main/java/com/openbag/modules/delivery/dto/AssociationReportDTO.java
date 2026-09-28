package com.openbag.modules.delivery.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

/**
 * Relatório da associação no período: entregas e ganhos dos cooperados, por dia, por cooperado e por loja.
 * O cooperado recebe o mesmo relatório sem {@code byMember} (nunca vê os ganhos dos colegas) e com {@code mine}.
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class AssociationReportDTO {

    private Long organizationId;
    private String associationName;
    private LocalDate from;
    private LocalDate to;
    private Summary summary;
    private List<Day> daily;
    private List<MemberLine> byMember;
    private List<RestaurantLine> byRestaurant;
    private Mine mine;

    /**
     * @param earnings          total pago aos cooperados (100% da tabela)
     * @param restaurantSubsidy parte desse total que as lojas assumiram (a taxa cobrada era menor)
     */
    public record Summary(long deliveries, BigDecimal earnings, double distanceKm, long members, long restaurants,
                          BigDecimal restaurantSubsidy) {
    }

    public record Day(LocalDate date, BigDecimal earnings, long deliveries) {
    }

    public record MemberLine(Long deliveryPersonId, String name, Integer memberNumber, long deliveries,
                             BigDecimal earnings, double distanceKm) {
    }

    /** @param agreedRate a loja tem tabela especial com a associação */
    public record RestaurantLine(Long restaurantId, String name, String slug, String logoUrl, long deliveries,
                                 BigDecimal earnings, BigDecimal restaurantSubsidy, boolean agreedRate) {
    }

    public record Mine(long deliveries, BigDecimal earnings) {
    }
}
