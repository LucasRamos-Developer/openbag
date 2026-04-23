package com.openbag.service;

import com.openbag.entity.Permission;
import com.openbag.entity.Role;
import com.openbag.exception.ResourceNotFoundException;
import com.openbag.repository.PermissionRepository;
import com.openbag.repository.RoleRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Serviço para gerenciamento de Permissões
 */
@Service
@Slf4j
public class PermissionService {

    @Autowired
    private PermissionRepository permissionRepository;

    @Autowired
    private RoleRepository roleRepository;

    /**
     * Retorna todas as permissões de uma role específica
     * @param roleName Nome da role
     * @return Lista de permissões da role
     */
    public List<Permission> getPermissionsByRole(String roleName) {
        Role role = roleRepository.findByName(roleName)
                .orElseThrow(() -> new ResourceNotFoundException("Role não encontrada: " + roleName));

        return role.getPermissions().stream().toList();
    }

    /**
     * Verifica se um usuário tem uma permissão específica
     * @param userId ID do usuário
     * @param permissionName Nome da permissão
     * @return true se o usuário possui a permissão
     */
    public boolean userHasPermission(Long userId, String permissionName) {
        List<Permission> permissions = permissionRepository.findPermissionsByUserId(userId);
        return permissions.stream()
                .anyMatch(p -> p.getName().equalsIgnoreCase(permissionName));
    }

    /**
     * Retorna os nomes de todas as permissões de um usuário
     * @param userId ID do usuário
     * @return Lista de nomes de permissões
     */
    public List<String> getPermissionNamesForUser(Long userId) {
        List<Permission> permissions = permissionRepository.findPermissionsByUserId(userId);
        return permissions.stream()
                .map(Permission::getName)
                .collect(Collectors.toList());
    }

    /**
     * Retorna todas as permissões disponíveis no sistema
     * @return Lista de todas as permissões
     */
    public List<Permission> getAllPermissions() {
        return permissionRepository.findAll();
    }

    /**
     * Retorna permissões agrupadas por categoria
     * @param category Categoria das permissões
     * @return Lista de permissões da categoria
     */
    public List<Permission> getPermissionsByCategory(String category) {
        return permissionRepository.findByCategory(category);
    }

    /**
     * Busca uma permissão pelo nome
     * @param name Nome da permissão
     * @return Permissão encontrada
     */
    public Permission getPermissionByName(String name) {
        return permissionRepository.findByName(name)
                .orElseThrow(() -> new ResourceNotFoundException("Permissão não encontrada: " + name));
    }
}
