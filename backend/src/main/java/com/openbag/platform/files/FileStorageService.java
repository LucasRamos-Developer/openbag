package com.openbag.platform.files;

import com.openbag.platform.web.exception.BadRequestException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Map;
import java.util.UUID;
import java.util.regex.Pattern;

/**
 * Serviço para gerenciamento de upload e armazenamento de arquivos
 */
@Service
@Slf4j
public class FileStorageService {

    private final Path fileStorageLocation;

    /**
     * Imagens aceitas, pela extensão com que são salvas. O tipo é detectado pelos bytes do arquivo,
     * nunca pelo nome nem pelo Content-Type do navegador (um HTML com nome .png seria servido como página)
     */
    public static final Map<String, String> IMAGE_TYPES_BY_EXTENSION = Map.of(
            "jpg", "image/jpeg",
            "png", "image/png",
            "webp", "image/webp",
            "gif", "image/gif"
    );

    /** Pastas de imagens: letras minúsculas, números, hífen e sublinhado, com subpastas (ex: "restaurants/logos") */
    private static final Pattern FOLDER_PATTERN = Pattern.compile("[a-z0-9_-]+(/[a-z0-9_-]+)*");

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
        Path folderPath = imageFolder(folder);

        try {
            byte[] bytes = file.getBytes();
            String extension = detectImageExtension(bytes);
            if (extension == null) {
                throw new BadRequestException("Tipo de arquivo não permitido. Use: JPEG, PNG, WEBP ou GIF");
            }
            String fileName = UUID.randomUUID() + "." + extension;

            Files.createDirectories(folderPath);
            Files.write(folderPath.resolve(fileName), bytes);

            String relativePath = folder + "/" + fileName;
            log.info("Arquivo salvo: {}", relativePath);
            return relativePath;

        } catch (IOException ex) {
            log.error("Erro ao salvar imagem em {}", folder, ex);
            throw new RuntimeException("Erro ao armazenar a imagem", ex);
        }
    }

    /**
     * Extensão da imagem pelos primeiros bytes (assinatura do formato), ou null se não for uma imagem aceita
     */
    static String detectImageExtension(byte[] bytes) {
        if (startsWith(bytes, 0, 0xFF, 0xD8, 0xFF)) {
            return "jpg";
        }
        if (startsWith(bytes, 0, 0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A)) {
            return "png";
        }
        if (startsWith(bytes, 0, 'G', 'I', 'F', '8') && (startsWith(bytes, 4, '7', 'a') || startsWith(bytes, 4, '9', 'a'))) {
            return "gif";
        }
        if (startsWith(bytes, 0, 'R', 'I', 'F', 'F') && startsWith(bytes, 8, 'W', 'E', 'B', 'P')) {
            return "webp";
        }
        return null;
    }

    private static boolean startsWith(byte[] bytes, int offset, int... signature) {
        if (bytes.length < offset + signature.length) {
            return false;
        }
        for (int i = 0; i < signature.length; i++) {
            if ((bytes[offset + i] & 0xFF) != signature[i]) {
                return false;
            }
        }
        return true;
    }

    /** Pasta de destino de uma imagem, sempre dentro do diretório de upload e fora da pasta restrita */
    private Path imageFolder(String folder) {
        if (folder == null || !FOLDER_PATTERN.matcher(folder).matches() || isPrivate(folder)) {
            throw new BadRequestException("Pasta inválida");
        }
        Path folderPath = this.fileStorageLocation.resolve(folder).normalize();
        if (!folderPath.startsWith(this.fileStorageLocation)) {
            throw new BadRequestException("Pasta inválida");
        }
        return folderPath;
    }

    /** Tipo de uma imagem guardada pela extensão (salva por {@link #storeImage}), ou null se não for imagem */
    public static String imageContentType(String relativePath) {
        int dot = relativePath.lastIndexOf('.');
        if (dot < 0) {
            return null;
        }
        String extension = relativePath.substring(dot + 1).toLowerCase(java.util.Locale.ROOT);
        // Imagens enviadas antes da checagem pelos bytes podem ter a extensão .jpeg
        return IMAGE_TYPES_BY_EXTENSION.get(extension.equals("jpeg") ? "jpg" : extension);
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
            throw new com.openbag.platform.web.exception.ResourceNotFoundException("Arquivo não encontrado");
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

        // Validar tamanho
        if (file.getSize() > MAX_FILE_SIZE) {
            throw new BadRequestException(
                "Arquivo muito grande. Tamanho máximo: 5MB"
            );
        }
    }

    /**
     * Retorna o caminho completo do arquivo
     */
    public Path getFilePath(String relativePath) {
        Path path = this.fileStorageLocation.resolve(relativePath).normalize();
        // Impede path traversal ("../") para fora da pasta de uploads
        if (!path.startsWith(this.fileStorageLocation)) {
            throw new com.openbag.platform.web.exception.ResourceNotFoundException("Arquivo não encontrado");
        }
        return path;
    }
}
