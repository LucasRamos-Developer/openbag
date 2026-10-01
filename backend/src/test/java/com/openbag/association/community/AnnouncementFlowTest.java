package com.openbag.association.community;

import com.openbag.account.entity.User;
import com.openbag.account.repository.UserRepository;
import com.openbag.association.community.dto.AnnouncementDTO;
import com.openbag.association.community.dto.AnnouncementRequest;
import com.openbag.association.community.entity.AnnouncementType;
import com.openbag.association.community.service.AnnouncementService;
import com.openbag.platform.security.CustomUserDetailsService.CustomUserPrincipal;
import com.openbag.platform.security.JwtTokenProvider;
import com.openbag.platform.seed.DemoDataInitializer;
import com.openbag.platform.web.exception.BadRequestException;
import com.openbag.support.IntegrationTest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Critério de pronto do item 4 da 0.5.0: o gestor publica uma reunião e o cooperado a vê, não lida, na área dele.
 * A conta demo é gestora da Cooperativa Demo e cooperada dela.
 */
class AnnouncementFlowTest extends IntegrationTest {

    @Autowired private AnnouncementService announcementService;
    @Autowired private UserRepository userRepository;
    @Autowired private JdbcTemplate jdbc;
    @Autowired private MockMvc mvc;
    @Autowired private JwtTokenProvider tokens;

    private User demo;
    private Long organizationId;

    @BeforeEach
    void setUp() {
        demo = userRepository.findByEmail(DemoDataInitializer.DEMO_EMAIL).orElseThrow();
        organizationId = jdbc.queryForObject("SELECT m.organization_id FROM association_memberships m "
                + "JOIN delivery_persons d ON d.id = m.delivery_person_id WHERE d.user_id = ? "
                + "AND m.status IN ('ACTIVE', 'SUSPENDED')", Long.class, demo.getId());
    }

    private AnnouncementDTO meeting(String title) {
        return announcementService.publish(organizationId, new AnnouncementRequest(AnnouncementType.MEETING, title,
                "Pauta: tabela de entrega e caixinha.", LocalDateTime.now().plusDays(5)), demo);
    }

    private AnnouncementDTO forMember(Long id) {
        return announcementService.forMember(demo).stream().filter(a -> a.id().equals(id)).findFirst().orElse(null);
    }

    @Test
    void theMemberSeesTheMeetingUnreadAndTheManagerCountsTheRead() {
        AnnouncementDTO published = meeting("Assembleia de outubro");
        assertThat(published.readCount()).isZero();
        assertThat(published.memberCount()).isPositive();

        AnnouncementDTO seen = forMember(published.id());
        assertThat(seen).isNotNull();
        assertThat(seen.read()).isFalse();
        assertThat(seen.eventAt()).isNotNull();
        assertThat(seen.readCount()).as("o cooperado não vê quantos leram").isNull();

        announcementService.markRead(demo, published.id());
        announcementService.markRead(demo, published.id());

        assertThat(forMember(published.id()).read()).isTrue();
        assertThat(announcementService.list(organizationId)).filteredOn(a -> a.id().equals(published.id()))
                .singleElement().extracting(AnnouncementDTO::readCount).isEqualTo(1L);
    }

    @Test
    void anArchivedAnnouncementLeavesTheMemberArea() {
        AnnouncementDTO published = meeting("Reunião cancelada");

        announcementService.archive(organizationId, published.id(), true);
        assertThat(forMember(published.id())).isNull();

        announcementService.archive(organizationId, published.id(), false);
        assertThat(forMember(published.id())).isNotNull();
    }

    @Test
    void aMeetingNeedsADateAndANoticeDropsIt() {
        assertThatThrownBy(() -> announcementService.publish(organizationId,
                new AnnouncementRequest(AnnouncementType.MEETING, "Reunião", "Sem data", null), demo))
                .isInstanceOf(BadRequestException.class);

        AnnouncementDTO notice = announcementService.publish(organizationId, new AnnouncementRequest(
                AnnouncementType.NOTICE, "Chuva forte", "Cuidado nas ruas alagadas.", LocalDateTime.now()), demo);
        assertThat(notice.eventAt()).isNull();
    }

    @Test
    void theRoutesAnswerForTheManagerAndForTheMember() throws Exception {
        AnnouncementDTO published = meeting("Treino de direção defensiva");
        var principal = new CustomUserPrincipal(demo);
        String token = "Bearer " + tokens.generateToken(
                new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities()));

        mvc.perform(get("/associations/" + organizationId + "/announcements").header("Authorization", token))
                .andExpect(status().isOk());
        mvc.perform(get("/me/association/announcements").header("Authorization", token))
                .andExpect(status().isOk());
        mvc.perform(post("/me/association/announcements/" + published.id() + "/read").header("Authorization", token))
                .andExpect(status().isOk());
        assertThat(jdbc.queryForObject("SELECT count(*) FROM association_announcement_reads WHERE announcement_id = ?",
                Integer.class, published.id())).isEqualTo(1);
        assertThat(List.of(published.type())).containsExactly(AnnouncementType.MEETING);
    }
}
