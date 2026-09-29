package com.openbag.platform.util;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

import java.util.Arrays;
import java.util.List;

/**
 * Lista curta de textos gravada numa coluna só, separada por "|" (o separador não é aceito nos valores)
 */
@Converter
public class StringListConverter implements AttributeConverter<List<String>, String> {

    public static final String SEPARATOR = "|";

    @Override
    public String convertToDatabaseColumn(List<String> values) {
        return values == null || values.isEmpty() ? null : String.join(SEPARATOR, values);
    }

    @Override
    public List<String> convertToEntityAttribute(String column) {
        if (column == null || column.isBlank()) {
            return List.of();
        }
        return Arrays.stream(column.split("\\" + SEPARATOR)).filter(s -> !s.isBlank()).toList();
    }
}
