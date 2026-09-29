package com.openbag.platform.web.idempotency;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.openbag.platform.seed.DemoDataInitializer;
import com.openbag.modules.user.repository.UserRepository;
import com.openbag.platform.security.CustomUserDetailsService.CustomUserPrincipal;
import com.openbag.platform.security.JwtTokenProvider;
import com.openbag.support.IntegrationTest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;

/** Pedido do balcão enviado de novo com a mesma chave: a loja nunca registra o mesmo pedido duas vezes */
class IdempotencyFilterTest extends IntegrationTest {

    @Autowired private MockMvc mvc;
    @Autowired private JwtTokenProvider tokens;
    @Autowired private UserRepository userRepository;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private ObjectMapper json;

    private String token;
    private Long restaurantId;
    private Long productId;

    @BeforeEach
    void setUp() {
        var demo = userRepository.findByEmail(DemoDataInitializer.DEMO_EMAIL).orElseThrow();
        var principal = new CustomUserPrincipal(demo);
        token = tokens.generateToken(new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities()));
        restaurantId = jdbc.queryForObject("SELECT id FROM restaurants WHERE slug = 'cantina-demo'", Long.class);
        productId = jdbc.queryForObject("SELECT id FROM products WHERE restaurant_id = ? AND deleted_at IS NULL "
                + "ORDER BY id LIMIT 1", Long.class, restaurantId);
    }

    @Test
    void sameKeyReturnsTheFirstOrderAndCreatesItOnce() throws Exception {
        String key = UUID.randomUUID().toString();
        int before = orders();

        MvcResult first = mvc.perform(storeOrder("Maria", key)).andReturn();
        MvcResult retry = mvc.perform(storeOrder("Maria", key)).andReturn();

        assertThat(first.getResponse().getStatus()).isEqualTo(201);
        assertThat(retry.getResponse().getStatus()).isEqualTo(201);
        assertThat(retry.getResponse().getHeader(IdempotencyFilter.REPLAYED_HEADER)).isEqualTo("true");
        assertThat(orderId(retry)).isEqualTo(orderId(first));
        assertThat(orders()).isEqualTo(before + 1);
    }

    @Test
    void sameKeyWithAnotherBodyIsRejected() throws Exception {
        String key = UUID.randomUUID().toString();
        mvc.perform(storeOrder("Maria", key)).andReturn();

        MvcResult other = mvc.perform(storeOrder("João", key)).andReturn();

        assertThat(other.getResponse().getStatus()).isEqualTo(422);
    }

    @Test
    void withoutKeyEachRequestIsANewOrder() throws Exception {
        int before = orders();

        mvc.perform(storeOrder("Maria", null)).andReturn();
        mvc.perform(storeOrder("Maria", null)).andReturn();

        assertThat(orders()).isEqualTo(before + 2);
    }

    @Test
    void invalidKeyIsRejected() throws Exception {
        assertThat(mvc.perform(storeOrder("Maria", "curta")).andReturn().getResponse().getStatus()).isEqualTo(400);
    }

    @Test
    void theSameKeyAtTheSameTimeCreatesOneOrder() throws Exception {
        String key = UUID.randomUUID().toString();
        int before = orders();
        ExecutorService pool = Executors.newFixedThreadPool(2);
        CountDownLatch start = new CountDownLatch(1);
        List<Future<Integer>> results = new ArrayList<>();
        for (int i = 0; i < 2; i++) {
            results.add(pool.submit(() -> {
                start.await();
                return mvc.perform(storeOrder("Maria", key)).andReturn().getResponse().getStatus();
            }));
        }
        start.countDown();
        List<Integer> statuses = new ArrayList<>();
        for (Future<Integer> result : results) {
            statuses.add(result.get());
        }
        pool.shutdown();

        // A segunda chega enquanto a primeira roda (409) ou depois dela (a mesma resposta)
        assertThat(statuses).contains(201).allMatch(status -> status == 201 || status == 409);
        assertThat(orders()).isEqualTo(before + 1);
    }

    private MockHttpServletRequestBuilder storeOrder(String customer, String key) throws Exception {
        Map<String, Object> body = Map.of(
                "channel", "COUNTER",
                "fulfillment", "PICKUP",
                "customerName", customer,
                "paymentMethod", "CASH",
                "items", List.of(Map.of("productId", productId, "quantity", 1)));
        MockHttpServletRequestBuilder request = post("/restaurants/{id}/orders", restaurantId)
                .header("Authorization", "Bearer " + token)
                .contentType(MediaType.APPLICATION_JSON)
                .content(json.writeValueAsString(body));
        return key != null ? request.header(IdempotencyFilter.HEADER, key) : request;
    }

    private Long orderId(MvcResult result) throws Exception {
        return json.readTree(result.getResponse().getContentAsString()).get("id").asLong();
    }

    private int orders() {
        return jdbc.queryForObject("SELECT count(*) FROM orders WHERE restaurant_id = ?", Integer.class, restaurantId);
    }
}
