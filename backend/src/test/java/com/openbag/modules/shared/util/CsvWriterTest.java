package com.openbag.modules.shared.util;

import org.junit.jupiter.api.Test;

import java.nio.charset.StandardCharsets;

import static org.assertj.core.api.Assertions.assertThat;

class CsvWriterTest {

    @Test
    void writesExcelFriendlyCsvWithBomSemicolonAndCrlf() {
        String csv = new CsvWriter().row("Nome", "Entregas").row("Ana", 12).toString();

        assertThat(csv).isEqualTo("﻿Nome;Entregas\r\nAna;12\r\n");
    }

    @Test
    void quotesFieldsWithSeparatorQuotesOrLineBreaks() {
        assertThat(CsvWriter.escape("Moto; Honda")).isEqualTo("\"Moto; Honda\"");
        assertThat(CsvWriter.escape("Zé \"Rápido\"")).isEqualTo("\"Zé \"\"Rápido\"\"\"");
        assertThat(CsvWriter.escape("linha 1\nlinha 2")).isEqualTo("\"linha 1\nlinha 2\"");
        assertThat(CsvWriter.escape(null)).isEmpty();
    }

    @Test
    void neutralizesFormulasTypedByUsersButKeepsNumbers() {
        assertThat(CsvWriter.escape("=HYPERLINK(\"x\")")).startsWith("\"'=HYPERLINK");
        assertThat(CsvWriter.escape("+5511999999999")).isEqualTo("'+5511999999999");
        assertThat(CsvWriter.escape(-3)).isEqualTo("-3");
    }

    @Test
    void encodesAsUtf8() {
        byte[] bytes = new CsvWriter().row("Situação").toBytes();

        assertThat(new String(bytes, StandardCharsets.UTF_8)).contains("Situação");
    }
}
