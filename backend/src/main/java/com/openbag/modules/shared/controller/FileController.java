package com.openbag.modules.shared.controller;

import com.openbag.modules.shared.service.FileStorageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.util.AntPathMatcher;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.HandlerMapping;
import org.springframework.web.multipart.MultipartFile;

import jakarta.servlet.http.HttpServletRequest;
import java.io.IOException;
import java.net.MalformedURLException;
import java.nio.file.Path;
import java.time.Duration;
import java.util.HashMap;
import java.util.Map;

/**
 * Controller para gerenciamento de uploads e downloads de arquivos
 */
@RestController
@RequestMapping("/files")
@Tag(name = "Files", description = "API de gerenciamento de arquivos")
@Slf4j
public class FileController {

    @Autowired
    private FileStorageService fileStorageService;

    @PostMapping("/upload/{folder}")
    @SecurityRequirement(name = "bearerAuth")
    @Operation(summary = "Upload de imagem", description = "Faz upload de uma imagem para uma pasta específica")
    public ResponseEntity<?> uploadFile(
            @PathVariable String folder,
            @RequestParam("file") MultipartFile file) {
        
        log.info("Recebendo upload de arquivo para pasta: {}", folder);
        if (FileStorageService.isPrivate(folder)) {
            throw new com.openbag.modules.shared.exception.BadRequestException("Pasta inválida");
        }
        
        String filePath = fileStorageService.storeImage(file, folder);
        
        Map<String, String> response = new HashMap<>();
        response.put("fileName", filePath);
        response.put("fileUrl", "/api/files/" + filePath);
        response.put("message", "Arquivo enviado com sucesso");
        
        return ResponseEntity.ok(response);
    }

    @GetMapping("/**")
    @Operation(summary = "Download de arquivo",
            description = "Serve um arquivo armazenado, inclusive em subpastas (ex: /files/restaurants/logos/x.png)")
    public ResponseEntity<Resource> downloadFile(HttpServletRequest request) {
        String filePath = relativePathOf(request);
        if (FileStorageService.isPrivate(filePath)) {
            // Documentos restritos só saem pelas rotas que conferem quem pode ver
            throw new com.openbag.exception.ResourceNotFoundException("Arquivo não encontrado");
        }
        Path path = fileStorageService.getFilePath(filePath);

        Resource resource;
        try {
            resource = new UrlResource(path.toUri());
            if (!resource.exists() || !resource.isReadable()) {
                return ResponseEntity.notFound().build();
            }
        } catch (MalformedURLException ex) {
            log.error("Erro ao carregar arquivo: {}", filePath, ex);
            return ResponseEntity.notFound().build();
        }

        // Tentar determinar o tipo de conteúdo do arquivo
        String contentType = null;
        try {
            contentType = request.getServletContext().getMimeType(resource.getFile().getAbsolutePath());
        } catch (IOException ex) {
            log.info("Não foi possível determinar o tipo do arquivo.");
        }

        // Fallback para o tipo de conteúdo padrão
        if (contentType == null) {
            contentType = "application/octet-stream";
        }

        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(contentType))
                // Nomes são UUIDs: o conteúdo de uma URL nunca muda
                .cacheControl(CacheControl.maxAge(Duration.ofDays(30)).cachePublic())
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + path.getFileName() + "\"")
                .body(resource);
    }

    @DeleteMapping("/**")
    @SecurityRequirement(name = "bearerAuth")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Deletar arquivo",
            description = "Somente ADMIN. Donos removem imagens pelos endpoints do próprio restaurante ou item.")
    public ResponseEntity<?> deleteFile(HttpServletRequest request) {
        boolean deleted = fileStorageService.deleteFile(relativePathOf(request));

        if (deleted) {
            Map<String, String> response = new HashMap<>();
            response.put("message", "Arquivo deletado com sucesso");
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.notFound().build();
        }
    }

    /**
     * Caminho do arquivo depois de /files/ (ex: "restaurants/logos/x.png")
     */
    private String relativePathOf(HttpServletRequest request) {
        String path = (String) request.getAttribute(HandlerMapping.PATH_WITHIN_HANDLER_MAPPING_ATTRIBUTE);
        String pattern = (String) request.getAttribute(HandlerMapping.BEST_MATCHING_PATTERN_ATTRIBUTE);
        return new AntPathMatcher().extractPathWithinPattern(pattern, path);
    }
}
