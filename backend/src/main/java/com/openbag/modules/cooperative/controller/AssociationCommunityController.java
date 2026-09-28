package com.openbag.modules.cooperative.controller;

import com.openbag.annotation.IsAssociationManager;
import com.openbag.enums.AssociationDocumentType;
import com.openbag.modules.cooperative.dto.*;
import com.openbag.modules.cooperative.service.AssociationDocumentService;
import com.openbag.modules.cooperative.service.BenefitService;
import com.openbag.modules.cooperative.service.PollService;
import com.openbag.modules.user.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.util.List;

/**
 * Convênios, enquetes e documentos (atas) que a associação deixa disponíveis para os cooperados
 */
@RestController
@RequestMapping("/associations/{id}")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Association Community", description = "Convênios, enquetes e atas da associação")
public class AssociationCommunityController {

    @Autowired
    private BenefitService benefitService;

    @Autowired
    private PollService pollService;

    @Autowired
    private AssociationDocumentService documentService;

    @Autowired
    private UserService userService;

    // ============= Convênios =============

    @GetMapping("/benefits")
    @IsAssociationManager
    @Operation(summary = "Convênios da associação")
    public ResponseEntity<List<BenefitDTO>> listBenefits(@PathVariable Long id) {
        return ResponseEntity.ok(benefitService.list(id));
    }

    @PostMapping("/benefits")
    @IsAssociationManager
    @Operation(summary = "Cadastrar convênio")
    public ResponseEntity<BenefitDTO> createBenefit(@PathVariable Long id, @Valid @RequestBody BenefitRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(benefitService.create(id, request));
    }

    @PutMapping("/benefits/{benefitId}")
    @IsAssociationManager
    @Operation(summary = "Alterar convênio")
    public ResponseEntity<BenefitDTO> updateBenefit(@PathVariable Long id, @PathVariable Long benefitId,
                                                    @Valid @RequestBody BenefitRequest request) {
        return ResponseEntity.ok(benefitService.update(id, benefitId, request));
    }

    @PostMapping(value = "/benefits/{benefitId}/logo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @IsAssociationManager
    @Operation(summary = "Logo do parceiro")
    public ResponseEntity<BenefitDTO> updateBenefitLogo(@PathVariable Long id, @PathVariable Long benefitId,
                                                        @RequestParam("file") MultipartFile file) {
        return ResponseEntity.ok(benefitService.updateLogo(id, benefitId, file));
    }

    @DeleteMapping("/benefits/{benefitId}")
    @IsAssociationManager
    @Operation(summary = "Apagar convênio")
    public ResponseEntity<Void> deleteBenefit(@PathVariable Long id, @PathVariable Long benefitId) {
        benefitService.delete(id, benefitId);
        return ResponseEntity.noContent().build();
    }

    // ============= Enquetes =============

    @GetMapping("/polls")
    @IsAssociationManager
    @Operation(summary = "Enquetes", description = "Rascunhos, abertas e encerradas, com o resultado")
    public ResponseEntity<List<PollDTO>> listPolls(@PathVariable Long id) {
        return ResponseEntity.ok(pollService.list(id));
    }

    @PostMapping("/polls")
    @IsAssociationManager
    @Operation(summary = "Criar enquete (rascunho)")
    public ResponseEntity<PollDTO> createPoll(@PathVariable Long id, @Valid @RequestBody PollRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(pollService.create(id, request, userService.getCurrentUser()));
    }

    @PutMapping("/polls/{pollId}")
    @IsAssociationManager
    @Operation(summary = "Alterar rascunho de enquete")
    public ResponseEntity<PollDTO> updatePoll(@PathVariable Long id, @PathVariable Long pollId,
                                              @Valid @RequestBody PollRequest request) {
        return ResponseEntity.ok(pollService.update(id, pollId, request));
    }

    @PostMapping("/polls/{pollId}/{action:open|close}")
    @IsAssociationManager
    @Operation(summary = "Abrir ou encerrar a votação")
    public ResponseEntity<PollDTO> pollAction(@PathVariable Long id, @PathVariable Long pollId,
                                              @PathVariable String action) {
        return ResponseEntity.ok(action.equals("open") ? pollService.open(id, pollId) : pollService.close(id, pollId));
    }

    @DeleteMapping("/polls/{pollId}")
    @IsAssociationManager
    @Operation(summary = "Apagar rascunho de enquete")
    public ResponseEntity<Void> deletePoll(@PathVariable Long id, @PathVariable Long pollId) {
        pollService.delete(id, pollId);
        return ResponseEntity.noContent().build();
    }

    // ============= Documentos =============

    @GetMapping("/documents")
    @IsAssociationManager
    @Operation(summary = "Atas e documentos")
    public ResponseEntity<List<AssociationDocumentDTO>> listDocuments(@PathVariable Long id) {
        return ResponseEntity.ok(documentService.list(id));
    }

    @PostMapping(value = "/documents", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @IsAssociationManager
    @Operation(summary = "Enviar ata ou documento (PDF até 10 MB)")
    public ResponseEntity<AssociationDocumentDTO> uploadDocument(@PathVariable Long id,
            @RequestParam("file") MultipartFile file,
            @RequestParam("title") String title,
            @RequestParam(value = "type", required = false) AssociationDocumentType type,
            @RequestParam(value = "date", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(value = "description", required = false) String description) {
        return ResponseEntity.status(HttpStatus.CREATED).body(
                documentService.upload(id, file, title, type, date, description, userService.getCurrentUser()));
    }

    @GetMapping("/documents/{documentId}/file")
    @IsAssociationManager
    @Operation(summary = "Baixar documento")
    public ResponseEntity<byte[]> downloadDocument(@PathVariable Long id, @PathVariable Long documentId) {
        return pdf(documentService.file(id, documentId));
    }

    @DeleteMapping("/documents/{documentId}")
    @IsAssociationManager
    @Operation(summary = "Apagar documento")
    public ResponseEntity<Void> deleteDocument(@PathVariable Long id, @PathVariable Long documentId) {
        documentService.delete(id, documentId);
        return ResponseEntity.noContent().build();
    }

    static ResponseEntity<byte[]> pdf(AssociationDocumentService.DocumentFile file) {
        return ResponseEntity.ok()
                .contentType(MediaType.APPLICATION_PDF)
                .header(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.attachment()
                        .filename(file.fileName(), StandardCharsets.UTF_8).build().toString())
                .body(file.content());
    }
}
