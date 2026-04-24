-- Migration para adicionar slug único aos restaurantes

-- Adicionar coluna slug
ALTER TABLE restaurants
ADD COLUMN IF NOT EXISTS slug VARCHAR(100);

-- Criar índice único para slug
CREATE UNIQUE INDEX IF NOT EXISTS idx_restaurants_slug ON restaurants(slug);

-- Comentário na coluna
COMMENT ON COLUMN restaurants.slug IS 'Slug único do restaurante para URLs amigáveis (ex: pizzaria-da-maria)';
