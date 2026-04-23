-- Migration V6: Criar tabelas de customizações de produtos

-- Criar tabela customization_groups (grupos de customização)
CREATE TABLE IF NOT EXISTS customization_groups (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL COMMENT 'Nome do grupo (ex: Tamanho, Adicionais, Sabor)',
    is_required BOOLEAN DEFAULT FALSE COMMENT 'Customização obrigatória?',
    min_selections INT DEFAULT 0 COMMENT 'Mínimo de opções selecionáveis',
    max_selections INT DEFAULT 1 COMMENT 'Máximo de opções selecionáveis',
    product_id BIGINT NOT NULL COMMENT 'Produto ao qual o grupo pertence',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_product_id (product_id),
    
    CONSTRAINT fk_customization_group_product 
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Grupos de customizações para produtos (ex: Tamanho, Adicionais)';

-- Criar tabela customization_options (opções individuais de cada grupo)
CREATE TABLE IF NOT EXISTS customization_options (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL COMMENT 'Nome da opção (ex: Pequeno, Médio, Grande)',
    price_modifier DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT 'Preço adicional ou desconto',
    is_available BOOLEAN DEFAULT TRUE COMMENT 'Opção disponível para seleção?',
    display_order INT DEFAULT 0 COMMENT 'Ordem de exibição',
    customization_group_id BIGINT NOT NULL COMMENT 'Grupo ao qual a opção pertence',
    
    INDEX idx_customization_group_id (customization_group_id),
    INDEX idx_display_order (display_order),
    
    CONSTRAINT fk_customization_option_group 
        FOREIGN KEY (customization_group_id) REFERENCES customization_groups(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Opções individuais de customização (ex: Pequeno +R$0, Médio +R$2, Grande +R$4)';

-- Criar tabela order_item_customizations (customizações aplicadas a itens do pedido)
CREATE TABLE IF NOT EXISTS order_item_customizations (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    order_item_id BIGINT NOT NULL COMMENT 'Item do pedido customizado',
    customization_option_id BIGINT NOT NULL COMMENT 'Opção de customização selecionada',
    price_at_purchase DECIMAL(10, 2) NOT NULL COMMENT 'Preço da customização no momento da compra',
    option_name VARCHAR(100) NOT NULL COMMENT 'Nome da opção (snapshot)',
    group_name VARCHAR(100) NOT NULL COMMENT 'Nome do grupo (snapshot)',
    
    INDEX idx_order_item_id (order_item_id),
    INDEX idx_customization_option_id (customization_option_id),
    
    CONSTRAINT fk_order_item_customization_order_item 
        FOREIGN KEY (order_item_id) REFERENCES order_items(id) ON DELETE CASCADE,
    CONSTRAINT fk_order_item_customization_option 
        FOREIGN KEY (customization_option_id) REFERENCES customization_options(id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Customizações aplicadas a itens específicos de pedidos (histórico imutável)';
