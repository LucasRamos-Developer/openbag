package com.openbag.modules.shared.exception;

/**
 * Mantida por compatibilidade: estende a exceção de {@code com.openbag.exception}
 * para ser tratada pelo GlobalExceptionHandler (antes virava erro 500)
 */
public class ResourceNotFoundException extends com.openbag.exception.ResourceNotFoundException {
    public ResourceNotFoundException(String message) {
        super(message);
    }
}
