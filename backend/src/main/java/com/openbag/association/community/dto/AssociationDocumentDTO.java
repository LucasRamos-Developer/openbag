package com.openbag.association.community.dto;

import com.openbag.enums.AssociationDocumentType;
import com.openbag.association.community.entity.AssociationDocument;

import java.time.LocalDate;
import java.time.LocalDateTime;

public record AssociationDocumentDTO(Long id, String title, AssociationDocumentType type, LocalDate date,
                                     String description, String fileName, long fileSize, LocalDateTime createdAt) {

    public static AssociationDocumentDTO from(AssociationDocument document) {
        return new AssociationDocumentDTO(document.getId(), document.getTitle(), document.getType(), document.getDate(),
                document.getDescription(), document.getFileName(), document.getFileSize(), document.getCreatedAt());
    }
}
