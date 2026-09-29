package com.openbag.association.finance.dto;

import java.util.List;

/** Para quem propor o adicional: os cooperados escolhidos ou, vazio, todos os ativos */
public record ProposeAddonRequest(List<Long> membershipIds) {
}
