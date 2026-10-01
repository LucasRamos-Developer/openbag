-- PIN de entrega (0.5.0, item 5): pedidos do app ganham um código de 4 dígitos que o cliente mostra ao entregador.
-- A loja decide se exige o código. A posição do entregador na hora da entrega fica registrada.

ALTER TABLE orders
    ADD COLUMN delivery_pin varchar(4),
    ADD COLUMN delivery_pin_attempts integer NOT NULL DEFAULT 0 CHECK (delivery_pin_attempts >= 0),
    ADD COLUMN delivered_latitude double precision,
    ADD COLUMN delivered_longitude double precision;

ALTER TABLE restaurants
    ADD COLUMN require_delivery_pin boolean;
