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

    /** Pasta de arquivos restritos (ex: atas da associação): nunca servida pela rota pública /files */
    public static final String PRIVATE_FOLDER = "private";

    private static final long MAX_DOCUMENT_SIZE = 10 * 1024 * 1024; // 10MB

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
     * Armazena um documento PDF numa pasta restrita (ex: atas das reuniões). Ele só é entregue pelas rotas que
     * conferem quem pode ver; a rota pública /files não serve a pasta {@link #PRIVATE_FOLDER}.
     *
     * @return caminho relativo, começando por "private/"
     */
    public String storeDocument(MultipartFile file, String folder) {
        if (file == null || file.isEmpty()) {
            throw new BadRequestException("Arquivo não pode ser vazio");
        }
        if (file.getSize() > MAX_DOCUMENT_SIZE) {
            throw new BadRequestException("Arquivo muito grande. Tamanho máximo: 10MB");
        }
        try {
            return storeDocument(file.getBytes(), folder);
        } catch (IOException ex) {
            throw new RuntimeException("Erro ao ler o documento", ex);
        }
    }

    /** Mesmo que {@link #storeDocument(MultipartFile, String)}, a partir do conteúdo do PDF */
    public String storeDocument(byte[] bytes, String folder) {
        // Confere o conteúdo, não só o tipo informado pelo navegador
        if (bytes.length < 5 || !new String(bytes, 0, 5, java.nio.charset.StandardCharsets.US_ASCII).equals("%PDF-")) {
            throw new BadRequestException("Envie o documento em PDF");
        }
        try {
            String relativeFolder = PRIVATE_FOLDER + "/" + folder;
            Path folderPath = this.fileStorageLocation.resolve(relativeFolder);
            Files.createDirectories(folderPath);
            String fileName = UUID.randomUUID() + ".pdf";
            Files.write(folderPath.resolve(fileName), bytes);
            log.info("Documento salvo: {}/{}", relativeFolder, fileName);
            return relativeFolder + "/" + fileName;
        } catch (IOException ex) {
            throw new RuntimeException("Erro ao armazenar o documento", ex);
        }
    }

    /** Conteúdo de um arquivo guardado (para as rotas que conferem a permissão antes de entregar) */
    public byte[] read(String relativePath) {
        try {
            return Files.readAllBytes(getFilePath(relativePath));
        } catch (IOException ex) {
            throw new com.openbag.exception.ResourceNotFoundException("Arquivo não encontrado");
        }
    }

    public static boolean isPrivate(String relativePath) {
        return relativePath != null && Paths.get(relativePath).normalize().startsWith(PRIVATE_FOLDER);
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
            Path file = getFilePath(filePath);
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
        Path path = this.fileStorageLocation.resolve(relativePath).normalize();
        // Impede path traversal ("../") para fora da pasta de uploads
        if (!path.startsWith(this.fileStorageLocation)) {
            throw new com.openbag.exception.ResourceNotFoundException("Arquivo não encontrado");
        }
        return path;
    }
}
