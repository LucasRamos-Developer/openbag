package com.openbag.platform.files;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.mock.web.MockMultipartFile;

import java.nio.charset.StandardCharsets;
import java.nio.file.Path;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class FileStorageServiceTest {

    @TempDir
    Path uploads;

    @Test
    void documentsAreStoredInThePrivateFolderAndMustBeRealPdfs() {
        FileStorageService service = new FileStorageService(uploads.toString());
        byte[] pdf = "%PDF-1.4 ata".getBytes(StandardCharsets.US_ASCII);

        String path = service.storeDocument(new MockMultipartFile("file", "ata.pdf", "application/pdf", pdf), "associations/12");

        assertThat(path).startsWith("private/associations/12/").endsWith(".pdf");
        assertThat(FileStorageService.isPrivate(path)).isTrue();
        assertThat(service.read(path)).isEqualTo(pdf);
        assertThatThrownBy(() -> service.storeDocument(new MockMultipartFile("file", "ata.pdf", "application/pdf",
                "<html>".getBytes(StandardCharsets.US_ASCII)), "associations/12"))
                .hasMessageContaining("PDF");
    }

    @Test
    void imagesAreRecognizedByTheirBytesAndSavedWithTheDetectedExtension() {
        FileStorageService service = new FileStorageService(uploads.toString());
        byte[] png = {(byte) 0x89, 'P', 'N', 'G', 0x0D, 0x0A, 0x1A, 0x0A, 0, 0};

        // O nome e o Content-Type enviados não importam: vale o conteúdo
        String path = service.storeImage(new MockMultipartFile("file", "logo.html", "text/html", png), "restaurants/logos");

        assertThat(path).startsWith("restaurants/logos/").endsWith(".png");
        assertThat(FileStorageService.imageContentType(path)).isEqualTo("image/png");
    }

    @Test
    void htmlOrSvgDisguisedAsImageIsRejected() {
        FileStorageService service = new FileStorageService(uploads.toString());
        byte[] html = "<html><script>alert(1)</script></html>".getBytes(StandardCharsets.US_ASCII);
        byte[] svg = "<svg xmlns=\"http://www.w3.org/2000/svg\"/>".getBytes(StandardCharsets.US_ASCII);

        assertThatThrownBy(() -> service.storeImage(new MockMultipartFile("file", "x.png", "image/png", html), "products"))
                .hasMessageContaining("não permitido");
        assertThatThrownBy(() -> service.storeImage(new MockMultipartFile("file", "x.svg", "image/png", svg), "products"))
                .hasMessageContaining("não permitido");
    }

    @Test
    void imageFoldersMustStayInsideTheUploadsAndOutOfThePrivateFolder() {
        FileStorageService service = new FileStorageService(uploads.toString());
        byte[] jpeg = {(byte) 0xFF, (byte) 0xD8, (byte) 0xFF, 0};

        for (String folder : new String[]{"../etc", "products/../../x", "private", "private/associations", "/tmp", "Products", ""}) {
            assertThatThrownBy(() -> service.storeImage(new MockMultipartFile("file", "x.jpg", "image/jpeg", jpeg), folder))
                    .as(folder)
                    .hasMessageContaining("Pasta inválida");
        }
    }

    @Test
    void onlyImageExtensionsHaveAContentTypeToBeServed() {
        assertThat(FileStorageService.imageContentType("products/a.jpg")).isEqualTo("image/jpeg");
        assertThat(FileStorageService.imageContentType("products/a.JPEG")).isEqualTo("image/jpeg");
        assertThat(FileStorageService.imageContentType("products/a.webp")).isEqualTo("image/webp");
        assertThat(FileStorageService.imageContentType("products/a.html")).isNull();
        assertThat(FileStorageService.imageContentType("products/a.svg")).isNull();
        assertThat(FileStorageService.imageContentType("products/a")).isNull();
    }

    @Test
    void privateFolderIsRecognizedEvenWithTricks() {
        assertThat(FileStorageService.isPrivate("private/x.pdf")).isTrue();
        assertThat(FileStorageService.isPrivate("restaurants/../private/x.pdf")).isTrue();
        assertThat(FileStorageService.isPrivate("associations/logo.png")).isFalse();
    }
}
