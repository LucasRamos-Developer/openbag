package com.openbag.modules.shared.service;

import com.openbag.modules.shared.exception.BadRequestException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

/**
 * Serviço para gerenciamento de upload e armazenamento de arquivos
 */
@Service
@Slf4j
public class FileStorageService {

    private final Path fileStorageLocation;

    private static final List<String> ALLOWED_IMAGE_TYPES = Arrays.asList(
            "image/jpeg", "image/jpg", "image/png", "image/webp", "image/gif"
    );

    private static final long MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB

    public FileStorageService(@Value("${app.upload.dir:uploads}") String uploadDir) {
        this.fileStorageLocation = Paths.get(uploadDir).toAbsolutePath().normalize();
        
        try {
            Files.createDirectories(this.fileStorageLocation);
            log.info("Diretório de upload criado/verificado: {}", this.fileStorageLocation);
        } catch (Exception ex) {
            throw new RuntimeException("Não foi possível criar o diretório de upload", ex);
        }
    }

    /**
     * Armazena um arquivo de imagem
     * @param file arquivo a ser armazenado
     * @param folder pasta de destino (ex: "products", "restaurants", "users")
     * @return URL/caminho relativo do arquivo armazenado
     */
    public String storeImage(MultipartFile file, String folder) {
        validateImageFile(file);

        String originalFilename = StringUtils.cleanPath(file.getOriginalFilename());
        String fileExtension = getFileExtension(originalFilename);
        String fileName = UUID.randomUUID().toString() + fileExtension;

        try {
            // Criar pasta específica se não existir
            Path folderPath = this.fileStorageLocation.resolve(folder);
            Files.createDirectories(folderPath);

            // Copiar arquivo
            Path targetLocation = folderPath.resolve(fileName);
            Files.copy(file.getInputStream(), targetLocation, StandardCopyOption.REPLACE_EXISTING);

            // Retornar caminho relativo
            String relativePath = folder + "/" + fileName;
            log.info("Arquivo salvo: {}", relativePath);
            return relativePath;

        } catch (IOException ex) {
            log.error("Erro ao salvar arquivo: {}", originalFilename, ex);
            throw new RuntimeException("Erro ao armazenar arquivo: " + originalFilename, ex);
        }
    }

    /**
     * Deleta um arquivo
     * @param filePath caminho relativo do arquivo
     * @return true se deletado com sucesso
     */
    public boolean deleteFile(String filePath) {
        if (filePath == null || filePath.isEmpty()) {
            return false;
        }

        try {
            Path file = this.fileStorageLocation.resolve(filePath).normalize();
            Files.deleteIfExists(file);
            log.info("Arquivo deletado: {}", filePath);
            return true;
        } catch (IOException ex) {
            log.error("Erro ao deletar arquivo: {}", filePath, ex);
            return false;
        }
    }

    /**
     * Valida se o arquivo é uma imagem válida
     */
    private void validateImageFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BadRequestException("Arquivo não pode ser vazio");
        }

        // Validar tipo de conteúdo
        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_IMAGE_TYPES.contains(contentType.toLowerCase())) {
            throw new BadRequestException(
                "Tipo de arquivo não permitido. Use: JPEG, PNG, WEBP ou GIF"
            );
        }

        // Validar tamanho
        if (file.getSize() > MAX_FILE_SIZE) {
            throw new BadRequestException(
                "Arquivo muito grande. Tamanho máximo: 5MB"
            );
        }

        // Validar nome do arquivo
        String filename = file.getOriginalFilename();
        if (filename == null || filename.contains("..")) {
            throw new BadRequestException("Nome de arquivo inválido");
        }
    }

    /**
     * Extrai extensão do arquivo
     */
    private String getFileExtension(String filename) {
        int lastIndexOf = filename.lastIndexOf(".");
        if (lastIndexOf == -1) {
            return "";
        }
        return filename.substring(lastIndexOf);
    }

    /**
     * Retorna o caminho completo do arquivo
     */
    public Path getFilePath(String relativePath) {
        return this.fileStorageLocation.resolve(relativePath).normalize();
    }
}
