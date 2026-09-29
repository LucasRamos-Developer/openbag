package com.openbag.delivery.courier.dto;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.ArrayList;
import java.util.List;

@Data
public class CourierProfileUpdateRequest {

    @NotBlank(message = "Nome é obrigatório")
    @Size(max = 100, message = "Nome deve ter no máximo 100 caracteres")
    private String fullName;

    @NotBlank(message = "Telefone é obrigatório")
    @Size(max = 15, message = "Telefone deve ter no máximo 15 caracteres")
    private String phoneNumber;

    @Size(max = 500, message = "Bio deve ter no máximo 500 caracteres")
    private String bio;

    private Boolean showWorkHistory;

    @Valid
    @Size(max = 8, message = "Informe no máximo 8 links")
    private List<SocialLinkDTO> socialLinks = new ArrayList<>();
}
