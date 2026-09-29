package com.openbag.delivery.courier.entity;

import com.openbag.enums.SocialPlatform;
import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Rede social ou link que o entregador escolhe mostrar no perfil público
 */
@Embeddable
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CourierSocialLink {

    @Enumerated(EnumType.STRING)
    @Column(name = "platform", length = 20, nullable = false)
    private SocialPlatform platform;

    @Column(name = "url", length = 255, nullable = false)
    private String url;
}
