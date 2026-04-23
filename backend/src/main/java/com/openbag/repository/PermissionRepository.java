package com.openbag.repository;

import com.openbag.entity.Permission;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PermissionRepository extends JpaRepository<Permission, Long> {

    /**
     * Busca uma permissão pelo nome
     * @param name Nome da permissão
     * @return Optional com a permissão se encontrada
     */
    Optional<Permission> findByName(String name);

    /**
     * Busca permissões por categoria
     * @param category Categoria da permissão
     * @return Lista de permissões da categoria
     */
    List<Permission> findByCategory(String category);

    /**
     * Busca múltiplas permissões pelos nomes
     * @param names Lista de nomes de permissões
     * @return Lista de permissões encontradas
     */
    List<Permission> findByNameIn(List<String> names);

    /**
     * Verifica se uma permissão existe pelo nome
     * @param name Nome da permissão
     * @return true se a permissão existe
     */
    boolean existsByName(String name);

    /**
     * Busca todas as permissões de um usuário (através das suas roles)
     * @param userId ID do usuário
     * @return Lista de permissões do usuário
     */
    @Query("SELECT DISTINCT p FROM Permission p " +
           "JOIN p.roles r " +
           "JOIN r.users u " +
           "WHERE u.id = :userId")
    List<Permission> findPermissionsByUserId(@Param("userId") Long userId);

    /**
     * Busca permissões de uma role específica
     * @param roleId ID da role
     * @return Lista de permissões da role
     */
    @Query("SELECT p FROM Permission p JOIN p.roles r WHERE r.id = :roleId")
    List<Permission> findPermissionsByRoleId(@Param("roleId") Long roleId);
}
