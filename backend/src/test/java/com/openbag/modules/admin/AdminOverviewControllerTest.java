package com.openbag.modules.admin;

import com.openbag.modules.admin.controller.AdminOverviewController;
import org.junit.jupiter.api.Test;
import org.springframework.security.access.prepost.PreAuthorize;

import static org.assertj.core.api.Assertions.assertThat;

class AdminOverviewControllerTest {

    @Test
    void wholeControllerIsRestrictedToAdmin() {
        PreAuthorize rule = AdminOverviewController.class.getAnnotation(PreAuthorize.class);

        assertThat(rule).isNotNull();
        assertThat(rule.value()).isEqualTo("hasRole('ADMIN')");
    }

    @Test
    void controllerOnlyReads() {
        // Painel admin é somente leitura: nenhum método pode alterar dados
        for (var method : AdminOverviewController.class.getDeclaredMethods()) {
            assertThat(method.isAnnotationPresent(org.springframework.web.bind.annotation.PostMapping.class)
                    || method.isAnnotationPresent(org.springframework.web.bind.annotation.PutMapping.class)
                    || method.isAnnotationPresent(org.springframework.web.bind.annotation.PatchMapping.class)
                    || method.isAnnotationPresent(org.springframework.web.bind.annotation.DeleteMapping.class))
                    .as(method.getName()).isFalse();
        }
    }
}
