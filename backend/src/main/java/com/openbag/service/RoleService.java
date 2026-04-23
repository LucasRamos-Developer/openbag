package com.openbag.service;

import com.openbag.entity.Permission;
import com.openbag.entity.Role;
import com.openbag.entity.User;
import com.openbag.exception.BadRequestException;
import com.openbag.exception.ResourceNotFoundException;
import com.openbag.repository.RoleRepository;
import com.openbag.repository.UserRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Set;

/**
 * Serviço para gerenciamento de Roles (papéis) dos usuários
 */
@Service
@Slf4j
public class RoleService {

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private UserRepository userRepository;

    /**
     * Adiciona uma role a um usuário
     * @param userId ID do usuário
     * @param roleName Nome da role
     * @throws ResourceNotFoundException se usuário ou role não existir
     * @throws BadRequestException se tentar adicionar role ADMIN sem ser admin
     */
    @Transactional
    public void addRoleToUser(Long userId, String roleName) {
        log.info("Adicionando role {} ao usuário {}", roleName, userId);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado"));

        Role role = roleRepository.findByName(roleName)
                .orElseThrow(() -> new ResourceNotFoundException("Role não encontrada: " + roleName));

        // Verifica se já possui a role
        if (user.getRoles().contains(role)) {
            log.debug("Usuário {} já possui a role {}", userId, roleName);
            return;
        }

        user.addRole(role);
        userRepository.save(user);

        log.info("Role {} adicionada ao usuário {} com sucesso", roleName, userId);
    }

    /**
     * Remove uma role de um usuário
     * @param userId ID do usuário
     * @param roleName Nome da role
     * @throws ResourceNotFoundException se usuário ou role não existir
     * @throws BadRequestException se tentar remover a última role do usuário
     */
    @Transactional
    public void removeRoleFromUser(Long userId, String roleName) {
        log.info("Removendo role {} do usuário {}", roleName, userId);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado"));

        Role role = roleRepository.findByName(roleName)
                .orElseThrow(() -> new ResourceNotFoundException("Role não encontrada: " + roleName));

        // Verifica se é a última role
        if (user.getRoles().size() <= 1) {
            throw new BadRequestException("Não é possível remover a última role do usuário");
        }

        user.removeRole(role);
        userRepository.save(user);

        log.info("Role {} removida do usuário {} com sucesso", roleName, userId);
    }

    /**
     * Retorna todas as roles de um usuário
     * @param userId ID do usuário
     * @return Lista de roles do usuário
     */
    public List<Role> getUserRoles(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado"));

        return user.getRoles().stream().toList();
    }

    /**
     * Retorna todas as permissões de um usuário (através das suas roles)
     * @param userId ID do usuário
     * @return Lista de permissões do usuário
     */
    public List<Permission> getUserPermissions(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado"));

        return user.getAllPermissions().stream().toList();
    }

    /**
     * Retorna todas as roles disponíveis no sistema
     * @return Lista de todas as roles
     */
    public List<Role> getAllRoles() {
        return roleRepository.findAll();
    }

    /**
     * Busca uma role pelo nome
     * @param name Nome da role
     * @return Role encontrada
     */
    public Role getRoleByName(String name) {
        return roleRepository.findByName(name)
                .orElseThrow(() -> new ResourceNotFoundException("Role não encontrada: " + name));
    }

    /**
     * Adiciona múltiplas roles a um usuário de uma vez
     * @param userId ID do usuário
     * @param roleNames Lista de nomes de roles
     */
    @Transactional
    public void addRolesToUser(Long userId, List<String> roleNames) {
        log.info("Adicionando roles {} ao usuário {}", roleNames, userId);

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado"));

        for (String roleName : roleNames) {
            Role role = roleRepository.findByName(roleName)
                    .orElseThrow(() -> new ResourceNotFoundException("Role não encontrada: " + roleName));

            if (!user.getRoles().contains(role)) {
                user.addRole(role);
            }
        }

        userRepository.save(user);
        log.info("Roles {} adicionadas ao usuário {} com sucesso", roleNames, userId);
    }

    /**
     * Substitui todas as roles de um usuário
     * @param userId ID do usuário
     * @param roleNames Lista de nomes de roles
     */
    @Transactional
    public void setUserRoles(Long userId, List<String> roleNames) {
        log.info("Substituindo roles do usuário {} por {}", userId, roleNames);

        if (roleNames == null || roleNames.isEmpty()) {
            throw new BadRequestException("Usuário deve ter pelo menos uma role");
        }

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário não encontrado"));

        // Remove todas as roles atuais
        Set<Role> currentRoles = Set.copyOf(user.getRoles());
        for (Role role : currentRoles) {
            user.removeRole(role);
        }

        // Adiciona as novas roles
        for (String roleName : roleNames) {
            Role role = roleRepository.findByName(roleName)
                    .orElseThrow(() -> new ResourceNotFoundException("Role não encontrada: " + roleName));
            user.addRole(role);
        }

        userRepository.save(user);
        log.info("Roles do usuário {} substituídas com sucesso", userId);
    }
}
