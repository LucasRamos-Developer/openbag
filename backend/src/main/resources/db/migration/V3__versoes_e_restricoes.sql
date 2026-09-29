-- Integridade contra ações simultâneas (0.4.0, item 3).

-- ============= Trava otimista (@Version) =============
-- Duas gravações feitas a partir da mesma leitura não se sobrescrevem: a segunda falha e o usuário recebe 409.

ALTER TABLE orders ADD COLUMN version bigint NOT NULL DEFAULT 0;
ALTER TABLE delivery_persons ADD COLUMN version bigint NOT NULL DEFAULT 0;
ALTER TABLE delivery_offers ADD COLUMN version bigint NOT NULL DEFAULT 0;
ALTER TABLE delivery_routes ADD COLUMN version bigint NOT NULL DEFAULT 0;
ALTER TABLE member_invoices ADD COLUMN version bigint NOT NULL DEFAULT 0;

-- ============= "Um aberto por vez" =============
-- Regras que antes só o código garantia. São exclusões adiadas para o fim da transação (e não índices únicos)
-- porque o Hibernate grava o registro novo antes de atualizar o antigo: encerrar um turno e abrir outro na
-- mesma transação é válido e só é conferido no commit.

-- Uma oferta pendente por pedido e uma por entregador
ALTER TABLE delivery_offers ADD CONSTRAINT ex_delivery_offers_pending_order
    EXCLUDE USING btree (order_id WITH =) WHERE (status = 'PENDING') DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE delivery_offers ADD CONSTRAINT ex_delivery_offers_pending_courier
    EXCLUDE USING btree (delivery_person_id WITH =) WHERE (status = 'PENDING') DEFERRABLE INITIALLY DEFERRED;

-- Um turno aberto por entregador
ALTER TABLE courier_shifts ADD CONSTRAINT ex_courier_shifts_open
    EXCLUDE USING btree (delivery_person_id WITH =) WHERE (ended_at IS NULL) DEFERRABLE INITIALLY DEFERRED;

-- Um vínculo aberto (pendente, ativo ou suspenso) do entregador com uma associação
ALTER TABLE association_memberships ADD CONSTRAINT ex_association_memberships_open
    EXCLUDE USING btree (delivery_person_id WITH =) WHERE (status IN ('PENDING', 'ACTIVE', 'SUSPENDED'))
    DEFERRABLE INITIALLY DEFERRED;

-- Uma parceria aberta por loja e associação (status nulo: parceria anterior ao aceite, vale até ser encerrada)
ALTER TABLE restaurant_partnerships ADD CONSTRAINT ex_restaurant_partnerships_open
    EXCLUDE USING btree (restaurant_id WITH =, organization_id WITH =)
    WHERE (status IN ('PENDING', 'ACTIVE') OR (status IS NULL AND ended_at IS NULL)) DEFERRABLE INITIALLY DEFERRED;

-- Um vínculo aberto de entregador fixo por loja
ALTER TABLE restaurant_courier_links ADD CONSTRAINT ex_restaurant_courier_links_open
    EXCLUDE USING btree (restaurant_id WITH =, delivery_person_id WITH =) WHERE (status IN ('PENDING', 'ACTIVE'))
    DEFERRABLE INITIALLY DEFERRED;

-- Um adicional proposto ou ativo por cooperado e plano
ALTER TABLE member_addons ADD CONSTRAINT ex_member_addons_open
    EXCLUDE USING btree (membership_id WITH =, plan_id WITH =) WHERE (status IN ('PROPOSED', 'ACTIVE'))
    DEFERRABLE INITIALLY DEFERRED;

-- Número do pedido no dia, por loja (a trava da loja na criação já garante; aqui fica a última barreira)
CREATE UNIQUE INDEX ux_orders_daily_number ON orders (restaurant_id, (CAST(order_date AS date)), daily_number)
    WHERE daily_number IS NOT NULL;

-- ============= Pedido =============

ALTER TABLE orders ALTER COLUMN status SET NOT NULL;
ALTER TABLE orders ALTER COLUMN restaurant_id SET NOT NULL;

-- Quem leva a entrega é um entregador do app ou da equipe própria, nunca os dois
ALTER TABLE orders ADD CONSTRAINT ck_orders_one_courier
    CHECK (delivery_person_id IS NULL OR staff_courier_id IS NULL);
ALTER TABLE delivery_routes ADD CONSTRAINT ck_delivery_routes_one_courier
    CHECK (delivery_person_id IS NULL OR staff_courier_id IS NULL);
ALTER TABLE courier_settlements ADD CONSTRAINT ck_courier_settlements_one_courier
    CHECK (delivery_person_id IS NULL OR staff_courier_id IS NULL);

-- ============= Valores =============
-- Nenhum valor em dinheiro é negativo (o saldo do acerto de caixa e o ajuste dos complementos podem ser).

ALTER TABLE orders ADD CONSTRAINT ck_orders_amounts CHECK (
    subtotal >= 0 AND total_amount >= 0
    AND (delivery_fee IS NULL OR delivery_fee >= 0)
    AND (courier_fee IS NULL OR courier_fee >= 0)
    AND (restaurant_delivery_subsidy IS NULL OR restaurant_delivery_subsidy >= 0)
    AND (change_for IS NULL OR change_for >= 0));
ALTER TABLE order_items ADD CONSTRAINT ck_order_items_amounts CHECK (
    quantity > 0 AND unit_price >= 0 AND (subtotal IS NULL OR subtotal >= 0)
    AND (total_price IS NULL OR total_price >= 0));
ALTER TABLE products ADD CONSTRAINT ck_products_price CHECK (
    price >= 0 AND (promotional_price IS NULL OR promotional_price >= 0));
ALTER TABLE combos ADD CONSTRAINT ck_combos_price CHECK (price >= 0);
ALTER TABLE delivery_offers ADD CONSTRAINT ck_delivery_offers_fee CHECK (courier_fee >= 0);
ALTER TABLE staff_couriers ADD CONSTRAINT ck_staff_couriers_fee CHECK (fee_per_delivery IS NULL OR fee_per_delivery >= 0);
ALTER TABLE restaurants ADD CONSTRAINT ck_restaurants_amounts CHECK (
    (delivery_fee IS NULL OR delivery_fee >= 0) AND (minimum_order IS NULL OR minimum_order >= 0));
ALTER TABLE member_invoices ADD CONSTRAINT ck_member_invoices_total CHECK (total >= 0);
ALTER TABLE member_invoice_lines ADD CONSTRAINT ck_member_invoice_lines_amount CHECK (amount >= 0);
ALTER TABLE ledger_entries ADD CONSTRAINT ck_ledger_entries_amount CHECK (amount > 0);
