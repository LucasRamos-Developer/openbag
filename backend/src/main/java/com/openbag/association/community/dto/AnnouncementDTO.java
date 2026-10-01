package com.openbag.association.community.dto;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.openbag.association.community.entity.AnnouncementType;

import java.time.LocalDateTime;

/**
 * Comunicado. O gestor recebe {@code readCount} de {@code memberCount} cooperados; o cooperado recebe {@code read}.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record AnnouncementDTO(Long id, AnnouncementType type, String title, String body, LocalDateTime eventAt,
                              LocalDateTime publishedAt, LocalDateTime archivedAt, Long readCount, Long memberCount,
                              Boolean read) {
}
