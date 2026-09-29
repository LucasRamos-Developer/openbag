package com.openbag.platform.files;

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

import jakarta.servlet.http.HttpServletRequest;
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

    /**
     * Serve as imagens enviadas. Uploads só acontecem pelas rotas de cada recurso (logo da loja, foto do
     * item, foto do entregador...), que conferem o dono e validam a imagem.
     */
    @GetMapping("/**")
    @Operation(summary = "Download de imagem",
            description = "Serve uma imagem armazenada, inclusive em subpastas (ex: /files/restaurants/logos/x.png)")
    public ResponseEntity<Resource> downloadFile(HttpServletRequest request) {
        String filePath = relativePathOf(request);
        if (FileStorageService.isPrivate(filePath)) {
            // Documentos restritos só saem pelas rotas que conferem quem pode ver
            throw new com.openbag.platform.web.exception.ResourceNotFoundException("Arquivo não encontrado");
        }
        // Só imagens, com o tipo fixo pela extensão: nada enviado é servido como HTML, SVG ou script
        // (o Spring Security já manda X-Content-Type-Options: nosniff em todas as respostas)
        String contentType = FileStorageService.imageContentType(filePath);
        if (contentType == null) {
            throw new com.openbag.platform.web.exception.ResourceNotFoundException("Arquivo não encontrado");
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

        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(contentType))
                // Mesmo aberta direto no navegador, a resposta não roda scripts nem carrega nada
                .header("Content-Security-Policy", "default-src 'none'; img-src 'self'; sandbox")
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
