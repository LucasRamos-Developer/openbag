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

    // Throttling do ping de localização: no máximo um a cada tantos segundos por entregador
    @Value("${app.delivery.location-min-interval-s:10}")
    private int locationMinIntervalSeconds;

    // Salto maior que esta velocidade, em menos de um minuto, é GPS ruim e fica de fora
    @Value("${app.delivery.location-max-speed-kmh:150}")
    private double locationMaxSpeedKmh;

    @Value("${app.delivery.weight-distance:0.5}")
    private double weightDistance;

    @Value("${app.delivery.weight-fairness:0.5}")
    private double weightFairness;
}
