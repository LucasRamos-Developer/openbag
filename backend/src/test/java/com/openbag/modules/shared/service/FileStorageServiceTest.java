package com.openbag.modules.shared.service;

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
    void privateFolderIsRecognizedEvenWithTricks() {
        assertThat(FileStorageService.isPrivate("private/x.pdf")).isTrue();
        assertThat(FileStorageService.isPrivate("restaurants/../private/x.pdf")).isTrue();
        assertThat(FileStorageService.isPrivate("associations/logo.png")).isFalse();
    }
}
