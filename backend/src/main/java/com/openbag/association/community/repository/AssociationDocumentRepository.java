package com.openbag.association.community.repository;

import com.openbag.association.community.entity.AssociationDocument;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AssociationDocumentRepository extends JpaRepository<AssociationDocument, Long> {

    List<AssociationDocument> findByOrganizationIdOrderByDateDescCreatedAtDesc(Long organizationId);

    Optional<AssociationDocument> findByIdAndOrganizationId(Long id, Long organizationId);
}
