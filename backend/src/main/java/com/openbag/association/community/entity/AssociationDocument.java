package com.openbag.association.community.entity;

import com.openbag.association.core.entity.Organization;
import com.openbag.account.entity.User;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Documento da associação (ata de reunião, estatuto, prestação de contas) em PDF, disponível para os cooperados.
 * O arquivo fica numa pasta restrita e só sai pela rota que confere se quem pede é cooperado ou gestor.
 */
@Entity
@Table(name = "association_documents",
        indexes = @Index(name = "idx_documents_organization", columnList = "organization_id"))
@Getter
@Setter
@NoArgsConstructor
public class AssociationDocument {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "organization_id", nullable = false)
    private Organization organization;

    @Column(nullable = false, length = 150)
    private String title;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private AssociationDocumentType type;

    /** Data da reunião (atas) ou do documento */
    @Column(name = "document_date")
    private LocalDate date;

    @Column(length = 1000)
    private String description;

    @Column(name = "file_path", nullable = false)
    private String filePath;

    @Column(name = "file_name", nullable = false, length = 200)
    private String fileName;

    @Column(name = "file_size", nullable = false)
    private long fileSize;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "uploaded_by_id")
    private User uploadedBy;

    @CreationTimestamp
    @Column(name = "created_at")
    private LocalDateTime createdAt;
}
