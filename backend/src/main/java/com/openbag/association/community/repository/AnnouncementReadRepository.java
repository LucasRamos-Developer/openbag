package com.openbag.association.community.repository;

import com.openbag.association.community.entity.AnnouncementRead;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;

public interface AnnouncementReadRepository extends JpaRepository<AnnouncementRead, Long> {

    /** Registra a leitura; se já existe (outra aba, outro toque), não faz nada */
    @Modifying
    @Query(value = "INSERT INTO association_announcement_reads (announcement_id, membership_id, read_at) "
            + "VALUES (:announcementId, :membershipId, :readAt) ON CONFLICT (announcement_id, membership_id) DO NOTHING",
            nativeQuery = true)
    void markRead(@Param("announcementId") Long announcementId, @Param("membershipId") Long membershipId,
                  @Param("readAt") LocalDateTime readAt);

    /** Quantos cooperados leram cada comunicado: [id do comunicado, leituras] */
    @Query("SELECT r.announcement.id, COUNT(r) FROM AnnouncementRead r WHERE r.announcement.id IN :ids "
            + "GROUP BY r.announcement.id")
    List<Object[]> countByAnnouncement(@Param("ids") Collection<Long> ids);

    /** Comunicados que o cooperado já leu, entre os pedidos */
    @Query("SELECT r.announcement.id FROM AnnouncementRead r WHERE r.membership.id = :membershipId "
            + "AND r.announcement.id IN :ids")
    List<Long> readBy(@Param("membershipId") Long membershipId, @Param("ids") Collection<Long> ids);
}
