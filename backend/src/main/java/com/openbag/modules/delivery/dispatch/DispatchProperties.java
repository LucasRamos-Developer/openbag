package com.openbag.modules.delivery.dispatch;

import lombok.Getter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/**
 * Parâmetros do despacho de entregas (application.properties, prefixo app.delivery)
 */
@Component
@Getter
public class DispatchProperties {

    @Value("${app.delivery.offer-timeout-s:30}")
    private int offerTimeoutSeconds;

    @Value("${app.delivery.search-radius-km:6}")
    private double searchRadiusKm;

    @Value("${app.delivery.checkin-radius-m:300}")
    private double checkinRadiusMeters;

    // Entregador online sem enviar localização há mais tempo que isso não recebe ofertas
    @Value("${app.delivery.location-stale-s:120}")
    private int locationStaleSeconds;

    // Turno livre sem sinal há mais tempo que isso é encerrado automaticamente
    @Value("${app.delivery.shift-timeout-min:15}")
    private int shiftTimeoutMinutes;

    @Value("${app.delivery.weight-distance:0.5}")
    private double weightDistance;

    @Value("${app.delivery.weight-fairness:0.5}")
    private double weightFairness;
}
