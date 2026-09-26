package com.openbag.modules.shared.util;

/**
 * Normalização e validação de documentos brasileiros (CPF e CNPJ, inclusive alfanumérico) pelos dígitos verificadores
 */
public final class BrazilianDocuments {

    private BrazilianDocuments() {
    }

    public static String digitsOnly(String value) {
        return value == null ? null : value.replaceAll("\\D", "");
    }

    public static boolean isValidCpf(String value) {
        String cpf = digitsOnly(value);
        if (cpf == null || cpf.length() != 11 || cpf.chars().distinct().count() == 1) {
            return false;
        }
        return checkDigit(cpf, 9, 10) == cpf.charAt(9) - '0'
                && checkDigit(cpf, 10, 11) == cpf.charAt(10) - '0';
    }

    /**
     * Normaliza o CNPJ: remove a pontuação e converte para maiúsculas (o CNPJ pode ser alfanumérico)
     */
    public static String normalizeCnpj(String value) {
        return value == null ? null : value.replaceAll("[^A-Za-z0-9]", "").toUpperCase();
    }

    /**
     * Valida CNPJ numérico ou alfanumérico: 12 caracteres alfanuméricos + 2 dígitos verificadores.
     * Cada caractere vale (código ASCII - 48), então dígitos mantêm seu valor e letras vão de 17 (A) a 42 (Z).
     */
    public static boolean isValidCnpj(String value) {
        String cnpj = normalizeCnpj(value);
        if (cnpj == null || !cnpj.matches("[A-Z0-9]{12}[0-9]{2}") || cnpj.chars().distinct().count() == 1) {
            return false;
        }
        int[] firstWeights = {5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2};
        int[] secondWeights = {6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2};
        return cnpjCheckDigit(cnpj, firstWeights) == cnpj.charAt(12) - '0'
                && cnpjCheckDigit(cnpj, secondWeights) == cnpj.charAt(13) - '0';
    }

    private static int checkDigit(String digits, int length, int startWeight) {
        int sum = 0;
        for (int i = 0; i < length; i++) {
            sum += (digits.charAt(i) - '0') * (startWeight - i);
        }
        int rest = (sum * 10) % 11;
        return rest == 10 ? 0 : rest;
    }

    private static int cnpjCheckDigit(String digits, int[] weights) {
        int sum = 0;
        for (int i = 0; i < weights.length; i++) {
            sum += (digits.charAt(i) - '0') * weights[i];
        }
        int rest = sum % 11;
        return rest < 2 ? 0 : 11 - rest;
    }
}
