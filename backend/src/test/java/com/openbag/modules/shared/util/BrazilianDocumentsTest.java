package com.openbag.modules.shared.util;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class BrazilianDocumentsTest {

    @Test
    void validatesCpfCheckDigits() {
        assertThat(BrazilianDocuments.isValidCpf("529.982.247-25")).isTrue();
        assertThat(BrazilianDocuments.isValidCpf("52998224725")).isTrue();
        assertThat(BrazilianDocuments.isValidCpf("529.982.247-26")).isFalse();
        assertThat(BrazilianDocuments.isValidCpf("111.111.111-11")).isFalse();
        assertThat(BrazilianDocuments.isValidCpf("1234")).isFalse();
        assertThat(BrazilianDocuments.isValidCpf(null)).isFalse();
    }

    @Test
    void validatesNumericCnpj() {
        assertThat(BrazilianDocuments.isValidCnpj("11.222.333/0001-81")).isTrue();
        assertThat(BrazilianDocuments.isValidCnpj("11444777000161")).isTrue();
        assertThat(BrazilianDocuments.isValidCnpj("11.222.333/0001-80")).isFalse();
        assertThat(BrazilianDocuments.isValidCnpj("00.000.000/0000-00")).isFalse();
    }

    @Test
    void validatesAlphanumericCnpj() {
        // Exemplo oficial da Receita Federal para o CNPJ alfanumérico
        assertThat(BrazilianDocuments.isValidCnpj("12.ABC.345/01DE-35")).isTrue();
        assertThat(BrazilianDocuments.isValidCnpj("12.abc.345/01de-35")).isTrue();
        assertThat(BrazilianDocuments.isValidCnpj("12.ABC.345/01DE-36")).isFalse();
        // Os dígitos verificadores precisam ser numéricos
        assertThat(BrazilianDocuments.isValidCnpj("12.ABC.345/01DE-3A")).isFalse();
    }

    @Test
    void normalizesCnpjToUppercaseWithoutPunctuation() {
        assertThat(BrazilianDocuments.normalizeCnpj("12.abc.345/01de-35")).isEqualTo("12ABC34501DE35");
        assertThat(BrazilianDocuments.normalizeCnpj("11.222.333/0001-81")).isEqualTo("11222333000181");
    }
}
