package com.openbag.config;

import com.openbag.modules.delivery.repository.RestaurantPartnershipRepository;
import com.openbag.modules.order.repository.OrderRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Preenche colunas novas em bancos que já existiam (o schema vem do ddl-auto, que cria a coluna vazia).
 * Cada passo só mexe em linhas ainda sem valor, então rodar de novo não muda nada.
 */
@Component
@Order(3)
@Slf4j
public class DataBackfill implements ApplicationRunner {

    @Autowired
    private RestaurantPartnershipRepository partnershipRepository;

    @Autowired
    private OrderRepository orderRepository;

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        // Parcerias anteriores ao aceite valiam direto
        int active = partnershipRepository.backfillActiveStatus();
        int ended = partnershipRepository.backfillEndedStatus();
        // Associação do entregador no pedido (relatórios da cooperativa e diferença assumida no caixa)
        int orders = orderRepository.backfillCourierOrganization();
        if (active + ended + orders > 0) {
            log.info("Backfill: {} parcerias ativas, {} encerradas, {} pedidos com associação", active, ended, orders);
        }
    }
}
