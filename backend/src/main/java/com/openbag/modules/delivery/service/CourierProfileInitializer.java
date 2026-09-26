package com.openbag.modules.delivery.service;

import com.openbag.modules.delivery.entity.DeliveryPerson;
import com.openbag.modules.delivery.repository.DeliveryPersonRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Completa perfis de entregadores criados antes do perfil público e dos veículos (slug e veículo em uso).
 * Idempotente: só toca em quem ainda não tem os dois.
 */
@Component
@Slf4j
public class CourierProfileInitializer implements ApplicationRunner {

    @Autowired
    private DeliveryPersonRepository deliveryPersonRepository;

    @Autowired
    private CourierProfileService profileService;

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        List<DeliveryPerson> pending = deliveryPersonRepository.findProfilesToInitialize();
        pending.forEach(profileService::initializeProfile);
        if (!pending.isEmpty()) {
            log.info("Perfis de entregador inicializados: {}", pending.size());
        }
    }
}
