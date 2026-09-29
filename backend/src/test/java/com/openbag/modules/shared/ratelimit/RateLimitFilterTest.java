package com.openbag.modules.shared.ratelimit;

import com.openbag.support.IntegrationTest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

/** Tentativas de senha em sequência recebem 429 com o tempo de espera, por IP e por conta */
class RateLimitFilterTest extends IntegrationTest {

    @Autowired private MockMvc mvc;

    @Test
    void theEleventhLoginFromTheSameIpInAMinuteIsRefused() throws Exception {
        String ip = "10.1.0.1";
        for (int i = 0; i < 10; i++) {
            assertThat(login(ip, UUID.randomUUID() + "@x.test").getResponse().getStatus()).isEqualTo(401);
        }

        MvcResult refused = login(ip, UUID.randomUUID() + "@x.test");

        assertThat(refused.getResponse().getStatus()).isEqualTo(429);
        assertThat(Long.parseLong(refused.getResponse().getHeader("Retry-After"))).isBetween(1L, 60L);
        assertThat(refused.getResponse().getContentAsString()).contains("Muitas tentativas");
        // Outro IP continua entrando
        assertThat(login("10.1.0.2", UUID.randomUUID() + "@x.test").getResponse().getStatus()).isEqualTo(401);
    }

    @Test
    void oneAccountIsProtectedEvenFromManyIps() throws Exception {
        String email = UUID.randomUUID() + "@x.test";
        for (int i = 0; i < 10; i++) {
            login("10.2.0." + i, email);
        }

        assertThat(login("10.2.1.1", email).getResponse().getStatus()).isEqualTo(429);
    }

    private MvcResult login(String ip, String email) throws Exception {
        return mvc.perform(post("/auth/login")
                        .with(request -> {
                            request.setRemoteAddr(ip);
                            return request;
                        })
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"email\":\"" + email + "\",\"password\":\"errada123\"}"))
                .andReturn();
    }
}
