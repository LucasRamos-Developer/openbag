-- Migration V7: Criar tabelas de combos (pacotes promocionais)

-- Criar tabela combos
CREATE TABLE IF NOT EXISTS combos (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL COMMENT 'Nome do combo',
    description VARCHAR(1000) COMMENT 'Descrição do combo',
    price DECIMAL(10, 2) NOT NULL COMMENT 'Preço promocional do combo',
    image_url VARCHAR(500) COMMENT 'URL da imagem do combo',
    is_available BOOLEAN DEFAULT TRUE COMMENT 'Combo disponível para venda?',
    is_active BOOLEAN DEFAULT TRUE COMMENT 'Combo ativo?',
    restaurant_id BIGINT NOT NULL COMMENT 'Restaurante proprietário',
    category_id BIGINT COMMENT 'Categoria do combo',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_restaurant_id (restaurant_id),
    INDEX idx_category_id (category_id),
    INDEX idx_is_active (is_active),
    INDEX idx_is_available (is_available),
    
    CONSTRAINT fk_combo_restaurant 
        FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE,
    CONSTRAINT fk_combo_category 
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Combos promocionais (pacotes de produtos com desconto)';

-- Criar tabela combo_items (produtos incluídos no combo)
CREATE TABLE IF NOT EXISTS combo_items (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    quantity INT NOT NULL DEFAULT 1 COMMENT 'Quantidade do produto no combo',
    combo_id BIGINT NOT NULL COMMENT 'Combo ao qual o item pertence',
    product_id BIGINT NOT NULL COMMENT 'Produto incluído',
    unit_price_snapshot DECIMAL(10, 2) COMMENT 'Preço unitário do produto no momento da criação',
    
    INDEX idx_combo_id (combo_id),
    INDEX idx_product_id (product_id),
    
    CONSTRAINT fk_combo_item_combo 
        FOREIGN KEY (combo_id) REFERENCES combos(id) ON DELETE CASCADE,
    CONSTRAINT fk_combo_item_product 
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Produtos individuais incluídos em cada combo';
