package com.openbag.modules.shared.exception;

/**
 * Mantida por compatibilidade: estende a exceção de {@code com.openbag.exception}
 * para ser tratada pelo GlobalExceptionHandler (antes virava erro 500)
 */
public class BadRequestException extends com.openbag.exception.BadRequestException {
    public BadRequestException(String message) {
        super(message);
    }
}
