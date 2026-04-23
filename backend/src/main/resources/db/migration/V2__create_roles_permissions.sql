-- Migration para criar tabelas de Roles e Permissions
-- Versão: 2.0
-- Data: 2026-04-23

-- ============================================
-- 1. Criar tabelas principais
-- ============================================

-- Tabela de Roles
CREATE TABLE IF NOT EXISTS roles (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_role_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de Permissions
CREATE TABLE IF NOT EXISTS permissions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255),
    category VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_permission_name (name),
    INDEX idx_permission_category (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 2. Criar tabelas de relacionamento (Join Tables)
-- ============================================

-- Tabela de relacionamento User-Role (Many-to-Many)
CREATE TABLE IF NOT EXISTS user_roles (
    user_id BIGINT NOT NULL,
    role_id BIGINT NOT NULL,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_user_roles_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_user_roles_role FOREIGN KEY (role_id) 
        REFERENCES roles(id) ON DELETE CASCADE,
    INDEX idx_user_roles_user_id (user_id),
    INDEX idx_user_roles_role_id (role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tabela de relacionamento Role-Permission (Many-to-Many)
CREATE TABLE IF NOT EXISTS role_permissions (
    role_id BIGINT NOT NULL,
    permission_id BIGINT NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    CONSTRAINT fk_role_permissions_role FOREIGN KEY (role_id) 
        REFERENCES roles(id) ON DELETE CASCADE,
    CONSTRAINT fk_role_permissions_permission FOREIGN KEY (permission_id) 
        REFERENCES permissions(id) ON DELETE CASCADE,
    INDEX idx_role_permissions_role_id (role_id),
    INDEX idx_role_permissions_permission_id (permission_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- 3. Migração de dados existentes
-- ============================================

-- NOTA: A migração de dados de user_type para roles será feita em um processo separado
-- após a criação das roles pelo DataInitializer, pois as roles precisam existir primeiro.

-- Este script pode ser executado manualmente após a inicialização:
-- 
-- INSERT INTO user_roles (user_id, role_id)
-- SELECT u.id, r.id
-- FROM users u
-- CROSS JOIN roles r
-- WHERE u.user_type = 'ADMIN' AND r.name = 'ADMIN'
--    OR u.user_type = 'CUSTOMER' AND r.name = 'CUSTOMER'
--    OR u.user_type = 'RESTAURANT_OWNER' AND r.name = 'RESTAURANT_OWNER'
--    OR u.user_type = 'DELIVERY_PERSON' AND r.name = 'DELIVERY_PERSON'
--    OR u.user_type = 'ORGANIZATION' AND r.name = 'ASSOCIATION_MANAGER'
-- ON DUPLICATE KEY UPDATE user_id=user_id;

-- ============================================
-- 4. Comentários nas tabelas (documentação)
-- ============================================

ALTER TABLE roles COMMENT = 'Tabela de roles (papéis) do sistema';
ALTER TABLE permissions COMMENT = 'Tabela de permissões granulares';
ALTER TABLE user_roles COMMENT = 'Relacionamento Many-to-Many entre usuários e roles';
ALTER TABLE role_permissions COMMENT = 'Relacionamento Many-to-Many entre roles e permissões';
