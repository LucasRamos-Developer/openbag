package com.openbag.platform.seed;

import com.openbag.enums.UserType;
import com.openbag.modules.user.entity.Permission;
import com.openbag.modules.user.entity.Role;
import com.openbag.modules.user.entity.User;
import com.openbag.modules.user.repository.PermissionRepository;
import com.openbag.modules.user.repository.RoleRepository;
import com.openbag.modules.user.repository.UserRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.*;

/**
 * Inicializa os dados básicos do sistema: Roles e Permissões
 * Executado automaticamente na inicialização da aplicação
 */
@Component
@Order(1)
@Slf4j
public class DataInitializer implements ApplicationRunner {

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private PermissionRepository permissionRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Value("${app.admin.email:}")
    private String adminEmail;

    @Value("${app.admin.password:}")
    private String adminPassword;

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        // Sempre faz upsert (as operações são idempotentes), para que permissões e roles
        // novas cheguem também a bancos já inicializados
        log.info("=== Iniciando DataInitializer ===");
        
        // Criar permissões
        Map<String, Permission> permissionsMap = createPermissions();
        
        // Criar roles e associar permissões
        createRoles(permissionsMap);

        // Garantir que exista um ADMIN (necessário, por exemplo, para aprovar associações)
        createDefaultAdmin();
        
        log.info("=== DataInitializer concluído com sucesso ===");
    }

    /**
     * Cria o usuário ADMIN inicial a partir de app.admin.email/app.admin.password,
     * somente se ainda não existir nenhum usuário com a role ADMIN
     */
    private void createDefaultAdmin() {
        if (userRepository.existsByRoleName(Role.RoleName.ADMIN.name())) {
            return;
        }

        if (adminEmail.isBlank() || adminPassword.isBlank()) {
            log.warn("Nenhum ADMIN cadastrado e app.admin.email/app.admin.password não configurados. ADMIN inicial não criado.");
            return;
        }

        if (userRepository.existsByEmail(adminEmail)) {
            log.warn("Email {} já está em uso por um usuário que não é ADMIN. ADMIN inicial não criado.", adminEmail);
            return;
        }

        User admin = new User();
        admin.setFullName("Administrador OpenBag");
        admin.setEmail(adminEmail);
        admin.setPhoneNumber("00000000000");
        admin.setPassword(passwordEncoder.encode(adminPassword));
        admin.setUserType(UserType.ADMIN);
        admin.setActive(true);
        roleRepository.findByName(Role.RoleName.ADMIN.name()).ifPresent(role -> admin.getRoles().add(role));
        userRepository.save(admin);

        log.info("ADMIN inicial criado: {}", adminEmail);
    }

    /**
     * Cria todas as permissões do sistema
     * @return Map com nome da permissão -> objeto Permission
     */
    private Map<String, Permission> createPermissions() {
        log.info("Criando permissões...");
        Map<String, Permission> permissionsMap = new HashMap<>();

        for (Permission.PermissionName permName : Permission.PermissionName.values()) {
            String name = permName.name();
            
            // Verifica se já existe
            Optional<Permission> existingPermission = permissionRepository.findByName(name);
            if (existingPermission.isPresent()) {
                log.debug("Permissão {} já existe, pulando criação", name);
                permissionsMap.put(name, existingPermission.get());
                continue;
            }

            // Cria nova permissão
            Permission permission = Permission.builder()
                    .name(name)
                    .description(permName.getDescription())
                    .category(permName.getCategory())
                    .build();

            permission = permissionRepository.save(permission);
            permissionsMap.put(name, permission);
            log.debug("Permissão criada: {} ({})", name, permName.getDescription());
        }

        log.info("Total de permissões: {}", permissionsMap.size());
        return permissionsMap;
    }

    /**
     * Cria todas as roles do sistema e associa suas permissões
     * @param permissionsMap Map com todas as permissões criadas
     */
    private void createRoles(Map<String, Permission> permissionsMap) {
        log.info("Criando roles e associando permissões...");

        // ADMIN - Todas as permissões
        createRoleWithPermissions(
                Role.RoleName.ADMIN.name(),
                Role.RoleName.ADMIN.getDisplayName(),
                new HashSet<>(permissionsMap.values())
        );

        // CUSTOMER - Permissões básicas de cliente
        createRoleWithPermissions(
                Role.RoleName.CUSTOMER.name(),
                Role.RoleName.CUSTOMER.getDisplayName(),
                getPermissions(permissionsMap,
                        "ORDER_CREATE",
                        "ORDER_VIEW",
                        "RESTAURANT_VIEW",
                        "PRODUCT_VIEW"
                )
        );

        // RESTAURANT_OWNER - Permissões de dono de restaurante
        createRoleWithPermissions(
                Role.RoleName.RESTAURANT_OWNER.name(),
                Role.RoleName.RESTAURANT_OWNER.getDisplayName(),
                getPermissions(permissionsMap,
                        "RESTAURANT_CREATE",
                        "RESTAURANT_VIEW",
                        "RESTAURANT_EDIT",
                        "RESTAURANT_DELETE",
                        "PRODUCT_CREATE",
                        "PRODUCT_EDIT",
                        "PRODUCT_DELETE",
                        "PRODUCT_VIEW",
                        "ORDER_VIEW",
                        "ORDER_ASSIGN_DELIVERY"
                )
        );

        // DELIVERY_PERSON - Permissões de entregador
        createRoleWithPermissions(
                Role.RoleName.DELIVERY_PERSON.name(),
                Role.RoleName.DELIVERY_PERSON.getDisplayName(),
                getPermissions(permissionsMap,
                        "DELIVERY_VIEW_ASSIGNED",
                        "DELIVERY_ACCEPT",
                        "DELIVERY_UPDATE_STATUS"
                )
        );

        // ASSOCIATION_MANAGER - Permissões de gerente de associação
        createRoleWithPermissions(
                Role.RoleName.ASSOCIATION_MANAGER.name(),
                Role.RoleName.ASSOCIATION_MANAGER.getDisplayName(),
                getPermissions(permissionsMap,
                        "ASSOCIATION_MANAGE_DELIVERY_PERSONS",
                        "ASSOCIATION_VIEW_STATS",
                        "ASSOCIATION_EDIT",
                        "ASSOCIATION_MANAGE_INVITES",
                        "DELIVERY_VIEW_ALL"
                )
        );

        log.info("Roles criadas com sucesso");
    }

    /**
     * Cria ou atualiza uma role com suas permissões
     */
    private void createRoleWithPermissions(String name, String description, Set<Permission> permissions) {
        Optional<Role> existingRole = roleRepository.findByName(name);

        if (existingRole.isPresent()) {
            // Atualiza permissões da role existente
            Role role = existingRole.get();
            role.setDescription(description);
            role.setPermissions(permissions);
            roleRepository.save(role);
            log.debug("Role {} atualizada com {} permissões", name, permissions.size());
        } else {
            // Cria nova role
            Role role = Role.builder()
                    .name(name)
                    .description(description)
                    .permissions(permissions)
                    .build();
            roleRepository.save(role);
            log.info("Role criada: {} com {} permissões", name, permissions.size());
        }
    }

    /**
     * Helper para obter um conjunto de permissões pelos nomes
     */
    private Set<Permission> getPermissions(Map<String, Permission> permissionsMap, String... names) {
        Set<Permission> permissions = new HashSet<>();
        for (String name : names) {
            Permission permission = permissionsMap.get(name);
            if (permission != null) {
                permissions.add(permission);
            } else {
                log.warn("Permissão não encontrada: {}", name);
            }
        }
        return permissions;
    }
}
