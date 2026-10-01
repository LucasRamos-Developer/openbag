package com.openbag.platform.web.exception;

/**
 * PIN de entrega errado. A tentativa precisa ficar gravada mesmo com o erro, então quem lança marca a transação
 * com {@code noRollbackFor} desta exceção. Responde 400, como as outras {@link BadRequestException}.
 */
public class WrongDeliveryPinException extends BadRequestException {
    public WrongDeliveryPinException(String message) {
        super(message);
    }
}
