package com.openbag.platform.util;

import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.List;

/**
 * CSV no formato que o Excel em português abre direto: separador ";", BOM do UTF-8 e quebra de linha CRLF.
 * Campos com separador, aspas ou quebra de linha vão entre aspas, com as aspas internas dobradas, e texto
 * que começa com "=", "+", "-" ou "@" ganha um apóstrofo na frente (evita injeção de fórmula).
 */
public final class CsvWriter {

    public static final String MEDIA_TYPE = "text/csv; charset=UTF-8";

    private static final char SEPARATOR = ';';
    private static final String BOM = "﻿";

    private final StringBuilder out = new StringBuilder(BOM);

    public CsvWriter row(Object... values) {
        return row(Arrays.asList(values));
    }

    public CsvWriter row(List<?> values) {
        for (int i = 0; i < values.size(); i++) {
            if (i > 0) out.append(SEPARATOR);
            out.append(escape(values.get(i)));
        }
        out.append("\r\n");
        return this;
    }

    public byte[] toBytes() {
        return out.toString().getBytes(StandardCharsets.UTF_8);
    }

    @Override
    public String toString() {
        return out.toString();
    }

    static String escape(Object value) {
        if (value == null) return "";
        String text = value.toString();
        // Texto digitado pelo usuário que começa como fórmula não pode virar fórmula no Excel
        if (!(value instanceof Number) && !text.isEmpty() && "=+-@\t\r".indexOf(text.charAt(0)) >= 0) {
            text = "'" + text;
        }
        boolean quote = text.indexOf(SEPARATOR) >= 0 || text.indexOf('"') >= 0
                || text.indexOf('\n') >= 0 || text.indexOf('\r') >= 0;
        return quote ? '"' + text.replace("\"", "\"\"") + '"' : text;
    }
}
