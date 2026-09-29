package com.openbag.delivery.courier.dto;

import com.openbag.enums.SocialPlatform;
import com.openbag.delivery.courier.entity.CourierSocialLink;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SocialLinkDTO {

    @NotNull(message = "Rede social é obrigatória")
    private SocialPlatform platform;

    @NotBlank(message = "Link é obrigatório")
    @Size(max = 255, message = "Link deve ter no máximo 255 caracteres")
    private String url;

    public static SocialLinkDTO from(CourierSocialLink link) {
        return new SocialLinkDTO(link.getPlatform(), link.getUrl());
    }
}
