package com.openbag.security;

import com.openbag.enums.UserType;
import com.openbag.modules.user.entity.User;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class CustomUserPrincipalTest {

    @Test
    void legacyUserTypeNeverGrantsAuthorities() {
        User user = new User();
        user.setUserType(UserType.ADMIN);

        var principal = new CustomUserDetailsService.CustomUserPrincipal(user);

        assertThat(principal.getAuthorities()).isEmpty();
    }
}
