package com.openbag.modules.user.repository;

import com.openbag.modules.user.entity.Role;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface RoleRepository extends JpaRepository<Role, Long> {

    /**
     * Busca uma role pelo nome
     * @param name Nome da role
     * @return Optional com a role se encontrada
     */
    Optional<Role> findByName(String name);

    /**
     * Busca múltiplas roles pelos nomes
     * @param names Lista de nomes de roles
     * @return Lista de roles encontradas
     */
    List<Role> findByNameIn(List<String> names);

    /**
     * Verifica se uma role existe pelo nome
     * @param name Nome da role
     * @return true se a role existe
     */
    boolean existsByName(String name);

    /**
     * Busca todas as roles de um usuário
     * @param userId ID do usuário
     * @return Lista de roles do usuário
     */
    @Query("SELECT r FROM Role r JOIN r.users u WHERE u.id = :userId")
    List<Role> findByUserId(@Param("userId") Long userId);
}
