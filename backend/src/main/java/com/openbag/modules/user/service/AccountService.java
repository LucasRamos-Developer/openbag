package com.openbag.modules.user.service;

import com.openbag.enums.UserType;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.platform.web.exception.ResourceNotFoundException;
import com.openbag.modules.organization.dto.AccountRequest;
import com.openbag.modules.user.entity.User;
import com.openbag.modules.user.repository.RoleRepository;
import com.openbag.modules.user.repository.UserRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Criação de contas de usuário já com suas roles, usada pelos cadastros compostos
 * (associação + gestor, entregador + vínculo)
 */
@Service
@Slf4j
public class AccountService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    /**
     * Valida se email e telefone ainda estão livres
     * @throws BadRequestException se algum já estiver em uso
     */
    public void validateAvailable(AccountRequest account) {
        if (userRepository.existsByEmail(account.getEmail().trim())) {
            throw new BadRequestException("Email já está em uso");
        }
        if (userRepository.existsByPhoneNumber(account.getPhoneNumber().trim())) {
            throw new BadRequestException("Telefone já está em uso");
        }
    }

    /**
     * Cria o usuário com as roles informadas
     * @param account Dados da conta
     * @param userType Tipo legado (mantido para compatibilidade)
     * @param roleNames Roles do usuário (ex: "CUSTOMER", "DELIVERY_PERSON")
     */
    @Transactional
    public User createAccount(AccountRequest account, UserType userType, String... roleNames) {
        validateAvailable(account);

        User user = new User();
        user.setFullName(account.getFullName().trim());
        user.setEmail(account.getEmail().trim());
        user.setPhoneNumber(account.getPhoneNumber().trim());
        user.setPassword(passwordEncoder.encode(account.getPassword()));
        user.setUserType(userType);
        user.setActive(true);

        for (String roleName : roleNames) {
            user.getRoles().add(roleRepository.findByName(roleName)
                    .orElseThrow(() -> new ResourceNotFoundException("Role não encontrada: " + roleName)));
        }

        User saved = userRepository.save(user);
        log.info("Conta criada: usuário {} com roles {}", saved.getId(), String.join(", ", roleNames));
        return saved;
    }
}
