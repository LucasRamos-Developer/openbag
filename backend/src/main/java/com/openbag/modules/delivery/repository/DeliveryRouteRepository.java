package com.openbag.modules.delivery.repository;

import com.openbag.enums.RouteStatus;
import com.openbag.modules.delivery.entity.DeliveryRoute;
import org.locationtech.jts.geom.LineString;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface DeliveryRouteRepository extends JpaRepository<DeliveryRoute, Long> {

    @Query("SELECT DISTINCT r FROM DeliveryRoute r LEFT JOIN FETCH r.orders WHERE r.restaurant.id = :restaurantId "
            + "AND r.status IN :statuses ORDER BY r.createdAt")
    List<DeliveryRoute> findByRestaurantAndStatusIn(@Param("restaurantId") Long restaurantId,
                                                    @Param("statuses") Collection<RouteStatus> statuses);

    Optional<DeliveryRoute> findByIdAndRestaurantId(Long id, Long restaurantId);

    /** Caminhos pelas ruas já salvos das rotas (só as colunas do caminho, sem carregar a rota) */
    @Query("SELECT r.id AS id, r.streetPathKey AS streetPathKey, r.streetPath AS streetPath FROM DeliveryRoute r "
            + "WHERE r.id IN :ids AND r.streetPath IS NOT NULL")
    List<StreetPath> findStreetPaths(@Param("ids") Collection<Long> ids);

    /** Grava só o caminho, sem sobrescrever status e pedidos que o despacho pode estar mudando */
    @Modifying
    @Transactional
    @Query("UPDATE DeliveryRoute r SET r.streetPath = :path, r.streetPathKey = :pathKey WHERE r.id = :id")
    void saveStreetPath(@Param("id") Long id, @Param("pathKey") String pathKey, @Param("path") LineString path);

    interface StreetPath {
        Long getId();

        String getStreetPathKey();

        LineString getStreetPath();
    }
}
