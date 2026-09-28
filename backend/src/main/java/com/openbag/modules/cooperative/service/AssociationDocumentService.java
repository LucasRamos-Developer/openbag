package com.openbag.modules.cooperative.service;

import com.openbag.enums.AssociationDocumentType;
import com.openbag.exception.BadRequestException;
import com.openbag.exception.ResourceNotFoundException;
import com.openbag.modules.cooperative.dto.AssociationDocumentDTO;
import com.openbag.modules.cooperative.entity.AssociationDocument;
import com.openbag.modules.cooperative.repository.AssociationDocumentRepository;
import com.openbag.modules.organization.service.AssociationService;
import com.openbag.modules.shared.service.FileStorageService;
import com.openbag.modules.user.entity.User;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDate;
import java.util.List;

/**
 * Atas, estatuto e prestações de contas da associação em PDF. O arquivo fica numa pasta restrita e só é entregue
 * ao gestor ou aos cooperados da associação.
 */
@Service
@Transactional
public class AssociationDocumentService {

    @Autowired
    private AssociationDocumentRepository documentRepository;

    @Autowired
    private AssociationService associationService;

    @Autowired
    private FileStorageService fileStorageService;

    @Autowired
    private MemberContext memberContext;

    /** Arquivo pronto para o download */
    public record DocumentFile(String fileName, byte[] content) {
    }

    @Transactional(readOnly = true)
    public List<AssociationDocumentDTO> list(Long organizationId) {
        return documentRepository.findByOrganizationIdOrderByDateDescCreatedAtDesc(organizationId).stream()
                .map(AssociationDocumentDTO::from)
                .toList();
    }

    public AssociationDocumentDTO upload(Long organizationId, MultipartFile file, String title,
                                         AssociationDocumentType type, LocalDate date, String description, User by) {
        if (title == null || title.isBlank()) {
            throw new BadRequestException("Dê um título ao documento");
        }
        if (title.length() > 150 || (description != null && description.length() > 1000)) {
            throw new BadRequestException("Título ou descrição muito longos");
        }
        AssociationDocument document = new AssociationDocument();
        document.setOrganization(associationService.findOperational(organizationId));
        document.setTitle(title.trim());
        document.setType(type != null ? type : AssociationDocumentType.OTHER);
        document.setDate(date);
        document.setDescription(description != null && !description.isBlank() ? description.trim() : null);
        document.setFilePath(fileStorageService.storeDocument(file, "associations/" + organizationId));
        String original = file.getOriginalFilename() != null ? StringUtils.cleanPath(file.getOriginalFilename()) : "";
        document.setFileName(original.isBlank() || original.contains("..") ? "documento.pdf"
                : original.substring(Math.max(0, original.length() - 200)));
        document.setFileSize(file.getSize());
        document.setUploadedBy(by);
        return AssociationDocumentDTO.from(documentRepository.save(document));
    }

    public void delete(Long organizationId, Long documentId) {
        AssociationDocument document = find(organizationId, documentId);
        fileStorageService.deleteFile(document.getFilePath());
        documentRepository.delete(document);
    }

    /** Download pelo gestor (a permissão sobre a associação é conferida no controller) */
    @Transactional(readOnly = true)
    public DocumentFile file(Long organizationId, Long documentId) {
        AssociationDocument document = find(organizationId, documentId);
        return new DocumentFile(document.getFileName(), fileStorageService.read(document.getFilePath()));
    }

    // ============= Cooperado =============

    @Transactional(readOnly = true)
    public List<AssociationDocumentDTO> forMember(User user) {
        return list(memberContext.current(user).getOrganization().getId());
    }

    /** Download pelo cooperado: só documentos da associação dele */
    @Transactional(readOnly = true)
    public DocumentFile fileForMember(User user, Long documentId) {
        return file(memberContext.current(user).getOrganization().getId(), documentId);
    }

    private AssociationDocument find(Long organizationId, Long documentId) {
        return documentRepository.findByIdAndOrganizationId(documentId, organizationId)
                .orElseThrow(() -> new ResourceNotFoundException("Documento não encontrado"));
    }
}
