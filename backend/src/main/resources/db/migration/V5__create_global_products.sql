-- Migration V5: Criar tabela de produtos globais e adicionar suporte a vinculação em produtos

-- Criar tabela global_products (catálogo global gerenciado por ADMIN)
CREATE TABLE IF NOT EXISTS global_products (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    barcode VARCHAR(50) NOT NULL UNIQUE COMMENT 'Código de barras do produto',
    name VARCHAR(200) NOT NULL COMMENT 'Nome do produto global',
    brand VARCHAR(100) COMMENT 'Marca do produto',
    description VARCHAR(1000) COMMENT 'Descrição detalhada',
    default_image_url VARCHAR(500) COMMENT 'URL da imagem padrão',
    category_id BIGINT COMMENT 'Categoria do produto',
    is_active BOOLEAN DEFAULT TRUE COMMENT 'Produto ativo no catálogo global',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_barcode (barcode),
    INDEX idx_name (name),
    INDEX idx_brand (brand),
    INDEX idx_category_id (category_id),
    INDEX idx_is_active (is_active),
    
    CONSTRAINT fk_global_product_category 
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Catálogo global de produtos industrializados compartilhado entre restaurantes';

-- Adicionar campos em products para suportar vinculação com produtos globais
ALTER TABLE products 
ADD COLUMN product_type VARCHAR(20) DEFAULT 'CUSTOM' COMMENT 'Tipo: GLOBAL_LINKED ou CUSTOM',
ADD COLUMN global_product_id BIGINT COMMENT 'Referência ao produto global vinculado',
ADD INDEX idx_product_type (product_type),
ADD INDEX idx_global_product_id (global_product_id),
ADD CONSTRAINT fk_product_global_product 
    FOREIGN KEY (global_product_id) REFERENCES global_products(id) ON DELETE SET NULL;

-- Comentário na tabela products
ALTER TABLE products 
COMMENT='Produtos do cardápio de cada restaurante (customizados ou vinculados a produtos globais)';
