package com.openbag.delivery.courier.repository;

import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Page;
import com.openbag.delivery.courier.entity.DeliveryPerson;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DeliveryPersonRepository extends JpaRepository<DeliveryPerson, Long> {

    Optional<DeliveryPerson> findByUserId(Long userId);

    /**
     * Busca o entregador com lock pessimista, para serializar mudanças de vínculo com associações
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT dp FROM DeliveryPerson dp WHERE dp.user.id = :userId")
    Optional<DeliveryPerson> findByUserIdForUpdate(@Param("userId") Long userId);

    @Query("SELECT dp FROM DeliveryPerson dp JOIN FETCH dp.user WHERE dp.slug = :slug")
    Optional<DeliveryPerson> findBySlug(@Param("slug") String slug);

    boolean existsBySlug(String slug);

    /**
     * Perfis criados antes do perfil público/veículos: sem slug ou sem veículo em uso
     */
    @Query("SELECT dp FROM DeliveryPerson dp WHERE dp.slug IS NULL OR dp.activeVehicle IS NULL")
    List<DeliveryPerson> findProfilesToInitialize();

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT dp FROM DeliveryPerson dp WHERE dp.id = :id")
    Optional<DeliveryPerson> findByIdForUpdate(@Param("id") Long id);

    /**
     * Grava só a posição, sem carregar e salvar o entregador inteiro: o ping de localização (a cada 20 s) nunca
     * desfaz uma mudança de situação feita ao mesmo tempo (ex.: o aceite de uma oferta)
     */
    @Modifying
    @Query("UPDATE DeliveryPerson d SET d.lastLatitude = :latitude, d.lastLongitude = :longitude, "
            + "d.lastSeenAt = :seenAt WHERE d.id = :id")
    int updateLocation(@Param("id") Long id, @Param("latitude") Double latitude, @Param("longitude") Double longitude,
                       @Param("seenAt") java.time.LocalDateTime seenAt);

    /**
     * Entregadores online no modo livre com localização recente: candidatos às ofertas
     */
    @Query("SELECT dp FROM DeliveryPerson dp JOIN FETCH dp.user JOIN FETCH dp.organization org "
            + "JOIN dp.currentShift s "
            + "WHERE dp.workStatus = com.openbag.enums.CourierWorkStatus.ONLINE AND dp.isActive = true "
            + "AND s.mode = com.openbag.enums.ShiftMode.FREE AND s.endedAt IS NULL "
            + "AND dp.lastSeenAt >= :seenSince AND dp.lastLatitude IS NOT NULL AND dp.lastLongitude IS NOT NULL")
    List<DeliveryPerson> findFreeOnlineCouriers(@Param("seenSince") java.time.LocalDateTime seenSince);

    Optional<DeliveryPerson> findByDocumentNumber(String documentNumber);

    Optional<DeliveryPerson> findByDriverLicense(String driverLicense);

    List<DeliveryPerson> findByIsActiveTrue();

    List<DeliveryPerson> findByIsAvailableTrue();

    @Query("SELECT dp FROM DeliveryPerson dp WHERE dp.isActive = true AND dp.isAvailable = true")
    List<DeliveryPerson> findAvailableDeliveryPersons();

    @Query("SELECT dp FROM DeliveryPerson dp WHERE dp.organization.id = :organizationId")
    List<DeliveryPerson> findByOrganizationId(@Param("organizationId") Long organizationId);

    @Query("SELECT dp FROM DeliveryPerson dp WHERE dp.organization IS NULL AND dp.isActive = true")
    List<DeliveryPerson> findIndependentDeliveryPersons();

    boolean existsByDocumentNumber(String documentNumber);

    boolean existsByDriverLicense(String driverLicense);

    /** Painel admin: busca por nome ou e-mail do entregador ([q] já em minúsculas com %) */
    @Query("select d from DeliveryPerson d join d.user u where lower(u.fullName) like :q or lower(u.email) like :q")
    Page<DeliveryPerson> searchForAdmin(@Param("q") String q, Pageable pageable);

    long countByWorkStatusIn(java.util.Collection<com.openbag.enums.CourierWorkStatus> statuses);
}
