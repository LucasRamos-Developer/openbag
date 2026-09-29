-- Dados de colunas criadas vazias pelo antigo ddl-auto=update (antes feito na subida, pela classe DataBackfill).
-- Só mexe em linhas ainda sem valor: num banco novo, não muda nada.

-- Parcerias anteriores ao aceite valiam direto
UPDATE restaurant_partnerships SET status = 'ACTIVE' WHERE status IS NULL AND ended_at IS NULL;
UPDATE restaurant_partnerships SET status = 'ENDED' WHERE status IS NULL AND ended_at IS NOT NULL;

-- Associação do entregador no pedido (relatórios da cooperativa e diferença assumida no caixa)
UPDATE orders o SET courier_organization_id = dp.organization_id
FROM delivery_persons dp
WHERE dp.id = o.delivery_person_id
  AND o.courier_organization_id IS NULL
  AND dp.organization_id IS NOT NULL;
