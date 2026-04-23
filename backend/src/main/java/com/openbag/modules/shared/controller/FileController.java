package com.openbag.modules.shared.controller;

import com.openbag.modules.shared.service.FileStorageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import jakarta.servlet.http.HttpServletRequest;
import java.io.IOException;
import java.net.MalformedURLException;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;

/**
 * Controller para gerenciamento de uploads e downloads de arquivos
 */
@RestController
@RequestMapping("/api/files")
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
        
        String filePath = fileStorageService.storeImage(file, folder);
        
        Map<String, String> response = new HashMap<>();
        response.put("fileName", filePath);
        response.put("fileUrl", "/api/files/" + filePath);
        response.put("message", "Arquivo enviado com sucesso");
        
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{folder}/{fileName:.+}")
    @Operation(summary = "Download de arquivo", description = "Faz download de um arquivo armazenado")
    public ResponseEntity<Resource> downloadFile(
            @PathVariable String folder,
            @PathVariable String fileName,
            HttpServletRequest request) {
        
        String filePath = folder + "/" + fileName;
        Path path = fileStorageService.getFilePath(filePath);
        
        Resource resource;
        try {
            resource = new UrlResource(path.toUri());
            if (!resource.exists()) {
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
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=\"" + fileName + "\"")
                .body(resource);
    }

    @DeleteMapping("/{folder}/{fileName:.+}")
    @SecurityRequirement(name = "bearerAuth")
    @Operation(summary = "Deletar arquivo", description = "Remove um arquivo armazenado")
    public ResponseEntity<?> deleteFile(
            @PathVariable String folder,
            @PathVariable String fileName) {
        
        String filePath = folder + "/" + fileName;
        boolean deleted = fileStorageService.deleteFile(filePath);
        
        if (deleted) {
            Map<String, String> response = new HashMap<>();
            response.put("message", "Arquivo deletado com sucesso");
            return ResponseEntity.ok(response);
        } else {
            return ResponseEntity.notFound().build();
        }
    }
}
