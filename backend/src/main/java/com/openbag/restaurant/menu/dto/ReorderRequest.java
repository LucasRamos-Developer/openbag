package com.openbag.restaurant.menu.dto;

import jakarta.validation.constraints.NotEmpty;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * Nova ordem: os ids na posição em que devem aparecer
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class ReorderRequest {

    @NotEmpty(message = "Informe a nova ordem")
    private List<Long> ids;
}
