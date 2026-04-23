-- Migration para adicionar coordenadas geográficas e remover campos obsoletos de horário

-- Adicionar colunas de latitude e longitude
ALTER TABLE restaurants
ADD COLUMN IF NOT EXISTS latitude DECIMAL(10, 7);

ALTER TABLE restaurants
ADD COLUMN IF NOT EXISTS longitude DECIMAL(10, 7);

-- Remover colunas obsoletas de horário (usar apenas a tabela opening_hours)
ALTER TABLE restaurants
DROP COLUMN IF EXISTS opening_time;

ALTER TABLE restaurants
DROP COLUMN IF EXISTS closing_time;

-- Comentários nas colunas
COMMENT ON COLUMN restaurants.latitude IS 'Latitude do restaurante (coordenada geográfica)';
COMMENT ON COLUMN restaurants.longitude IS 'Longitude do restaurante (coordenada geográfica)';

-- Criar índice para otimizar buscas geográficas
CREATE INDEX IF NOT EXISTS idx_restaurants_coordinates ON restaurants(latitude, longitude);
