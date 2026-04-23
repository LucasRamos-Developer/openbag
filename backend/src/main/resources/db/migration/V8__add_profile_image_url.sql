-- Migration para adicionar campo de imagem de perfil em users

-- Adicionar coluna profile_image_url na tabela users
ALTER TABLE users
ADD COLUMN IF NOT EXISTS profile_image_url VARCHAR(500);

-- Comentário na coluna
COMMENT ON COLUMN users.profile_image_url IS 'URL da imagem de perfil do usuário';
