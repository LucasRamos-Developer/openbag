package com.openbag.delivery.courier.dto;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;

import java.math.BigDecimal;

/**
 * Custos do veículo, todos opcionais (vazio apaga). Combustível só vale para moto e carro.
 *
 * @param fuelConsumptionKmPerLiter consumo (km por litro)
 * @param fuelPricePerLiter         preço do combustível (R$ por litro)
 * @param maintenancePerKm          manutenção por km (óleo, pneus, relação...)
 * @param depreciationPerKm         depreciação por km (quanto o veículo perde de valor)
 */
public record VehicleCostsRequest(
        @DecimalMin(value = "0", inclusive = false, message = "O consumo deve ser maior que zero")
        @DecimalMax(value = "200", message = "Confira o consumo: até 200 km por litro") BigDecimal fuelConsumptionKmPerLiter,
        @DecimalMin(value = "0", message = "O preço não pode ser negativo")
        @DecimalMax(value = "50", message = "Confira o preço do combustível") BigDecimal fuelPricePerLiter,
        @DecimalMin(value = "0", message = "A manutenção não pode ser negativa")
        @DecimalMax(value = "50", message = "Confira a manutenção por km") BigDecimal maintenancePerKm,
        @DecimalMin(value = "0", message = "A depreciação não pode ser negativa")
        @DecimalMax(value = "50", message = "Confira a depreciação por km") BigDecimal depreciationPerKm) {
}
