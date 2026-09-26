package com.openbag.modules.restaurant.dto;

import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class OpenRequest {

    @NotNull(message = "Informe se a loja está aberta")
    private Boolean open;
}
