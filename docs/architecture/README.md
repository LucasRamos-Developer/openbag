# Arquitetura do OpenBag

> Versão da documentação: **0.3.0**, atualizada em 2026-09-29. O que mudou está no [CHANGELOG](../../CHANGELOG.md).

Este documento explica como o sistema está organizado hoje: módulos do backend, tempo real, despacho de entregas, rotas, caixa e a estrutura do app Flutter. Para rodar o projeto, veja o [guia de desenvolvimento](../../README-DEVELOPER.md).

---

## Visão geral

```mermaid
flowchart LR
    subgraph App["App Flutter (web e mobile)"]
        V[Vitrine e loja<br/>cliente]
        R[Painel do restaurante]
        E[Painel do entregador]
        A[Painel da associação]
    end

    subgraph API["Backend Spring Boot (/api)"]
        REST[REST + JWT]
        WS[WebSocket STOMP<br/>/api/ws]
        JOBS[Jobs agendados<br/>despacho, rotas, prazos]
    end

    DB[(PostgreSQL<br/>+ PostGIS)]
    OSM[OpenStreetMap<br/>tiles e endereços]

    App -- HTTP --> REST
    App <-- eventos --> WS
    REST --> DB
    JOBS --> DB
    JOBS -- ofertas e status --> WS
    App -- mapas --> OSM
```

| Camada | Tecnologia |
|--------|------------|
| App | Flutter 3.16+ (web e mobile), Provider, GoRouter, `flutter_map`, `stomp_dart_client` |
| API | Java 25, Spring Boot 3.3, Spring Security + JWT, Spring Data JPA, SpringDoc |
| Tempo real | WebSocket com STOMP (broker simples do Spring) |
| Banco | PostgreSQL 15 com PostGIS 3 (caminho das rotas) |
| Infra local | Docker Compose: PostgreSQL com PostGIS, Redis, Elasticsearch e Kibana |

Hoje o Redis só tem a configuração e o Elasticsearch não é usado pelo código. Os dois continuam no `docker-compose.yml` para a busca e o cache que virão.

---

## Backend

O código fica em `backend/src/main/java/com/openbag` e é **organizado por módulo de domínio**. Cada módulo tem `controller`, `dto`, `entity`, `repository` e `service`.

```
com/openbag/
├── config/          # Segurança, OpenAPI, Redis, agendamento, dados iniciais
├── security/        # JWT (filtro e provider), UserDetails, PermissionEvaluator
├── enums/           # Status e tipos compartilhados (OrderStatus, CourierPolicy...)
├── exception/       # GlobalExceptionHandler
└── modules/
    ├── user/          # Cadastro, login, perfil, endereços
    ├── restaurant/    # Restaurante, loja (horários, pausa, aparência), página pública
    ├── menu/          # Seções e itens do cardápio do dono
    ├── product/       # Produtos, categorias, complementos, catálogo global
    ├── combo/         # Combos
    ├── order/         # Pedidos do cliente e gestão pela loja, tempo real
    ├── delivery/      # Entregadores, vínculos, despacho, rotas, caixa, ganhos
    ├── organization/  # Associações e cooperativas, membros, convites, tabela
    └── shared/        # Arquivos, health check, utilitários e entidades base
```

### Módulos e rotas principais

Todas as rotas ficam sob o prefixo `/api`. A lista completa está no Swagger: `http://localhost:8080/api/swagger-ui.html`.

| Módulo | Rotas base | O que faz |
|--------|------------|-----------|
| `user` | `/auth`, `/users` | Cadastro (cliente, restaurante, entregador, associação), login JWT, perfil e endereços |
| `restaurant` | `/restaurants`, `/public/restaurants` | Dados da loja, aparência (tema, logo, destaque), endereço, horários, abrir, fechar e pausar; página pública por `slug` |
| `menu` | `/restaurants/{id}/menu` | Seções (com ícone) e itens do cardápio, disponibilidade |
| `product` | `/products`, `/customizations`, `/public/categories`, `/global-products` | Produtos, grupos de complementos, categorias |
| `combo` | `/combos` | Combos da loja |
| `order` | `/orders`, `/restaurants/{id}/orders` | Checkout do cliente e ciclo do pedido na loja (aceitar, preparar, pronto, despachar, entregar) |
| `delivery` | `/me/courier`, `/me/courier/work`, `/public/couriers`, `/restaurants/{id}/delivery`, `/associations/{id}/partnerships`, `/associations/{id}/reports`, `/routes`, `/cash` | Perfil e veículos do entregador, turno e ofertas, configurações de entrega da loja, parcerias entre loja e associação (com tabela especial), relatórios da associação, rotas e caixa |
| `cooperative` | `/associations/{id}/fee-policy`, `/addon-plans`, `/invoices`, `/ledger`, `/finance/summary`, `/benefits`, `/polls`, `/documents`; `/me/association/invoices`, `/addons`, `/solidarity-fund`, `/benefits`, `/polls`, `/documents` | Gestão da associação: cobrança da mensalidade (fixa ou percentual com teto), adicionais, faturas com baixa manual, livro-caixa e caixinha solidária, convênios, enquetes e atas; e a área do cooperado |
| `organization` | `/associations`, `/me/association`, `/public/associations`, `/admin/associations` | Associações: cadastro, aprovação, membros, convites, tabela de entrega e o resumo da associação para o cooperado (`/me/association/report`) |
| `shared` | `/files`, `/health` | Upload e download de arquivos, health check |

### Papéis

`UserType`: `CUSTOMER`, `RESTAURANT_OWNER`, `DELIVERY_PERSON`, `ORGANIZATION` e `ADMIN`. Um mesmo usuário pode ter mais de um painel, e o app mostra um seletor de perfil no menu. As permissões por recurso (por exemplo, "é dono deste restaurante") ficam no `CustomPermissionEvaluator`.

---

## Ciclo do pedido

```mermaid
stateDiagram-v2
    [*] --> PENDING: cliente faz o pedido
    PENDING --> CONFIRMED: loja aceita (manual ou automático)
    PENDING --> CANCELLED: loja recusa ou o prazo expira
    CONFIRMED --> PREPARING
    PREPARING --> READY_FOR_PICKUP
    READY_FOR_PICKUP --> OUT_FOR_DELIVERY: entregador retira
    OUT_FOR_DELIVERY --> DELIVERED
    DELIVERED --> [*]
```

- **Preço calculado no servidor:** o `OrderCalculator` recalcula itens e complementos, e o valor enviado pelo app não é usado.
- **Código do dia:** cada pedido recebe um `#0001` que reinicia a cada dia.
- **Aceite:** cada loja configura o aceite como `MANUAL` (com prazo, `acceptDeadline`) ou `AUTO`. Um job cancela os pedidos que passam do prazo.
- **Pagamento:** na entrega (`Order.PaymentMethod`: dinheiro com troco, cartão, Pix ou vale-refeição).
- **Horário:** `Restaurant.isOpenNow` usa o fuso `America/Sao_Paulo`.

---

## Tempo real (WebSocket/STOMP)

Endpoint: `/api/ws`. O `StompAuthInterceptor` valida o JWT no `CONNECT` e verifica se o usuário pode assinar cada tópico.

| Tópico | Quem assina | Conteúdo |
|--------|-------------|----------|
| `/topic/restaurants/{id}/orders` | Gestor de pedidos e tela da cozinha | Pedido criado ou alterado |
| `/topic/orders/{id}` | Cliente dono do pedido | Mudanças de status |
| `/topic/couriers/{id}` | O próprio entregador | Ofertas, atribuições, rotas |

Os eventos só saem **depois do commit** da transação (`OrderEventPublisher` e `CourierNotifier`). Assim, ninguém recebe um estado que acabou desfeito.

---

## Despacho de entregas

O despacho fica em `modules/delivery/dispatch`.

### Com quem a loja trabalha

Cada loja escolhe uma política (`CourierPolicy`):

| Política | Significado |
|----------|-------------|
| `OPEN` | Qualquer entregador online perto da loja |
| `PARTNERS_ONLY` | Só entregadores de associações parceiras da loja |
| `FIXED_ONLY` | Só entregadores fixos da loja, com os livres como reserva se a loja quiser (`fallbackToOpen`) |

### Tipos de entregador

- **Livre:** fica online e envia a localização. A oferta vai para quem tem a melhor nota no `CourierSelector`, que combina **distância** e **justiça** (quem ganhou menos no dia tem prioridade). Os pesos ficam em `app.delivery.weight-*`. A oferta expira depois de `offer-timeout-s` (30 s) e passa ao próximo. O raio de busca é `search-radius-km` (6 km).
- **Fixo:** o vínculo com a loja é aprovado pelo dono. O entregador faz check-in a até `checkin-radius-m` (300 m) da loja e, durante o turno, só atende aquela loja.
- **Equipe própria (`StaffCourier`):** entregadores da loja que não usam o app. A loja atribui o pedido diretamente.

### Atribuição direta e troca

A loja pode escolher o entregador sem que ele precise aceitar uma oferta. As regras de troca ficam no `ReassignPolicy`:
- entregador fixo ou da equipe própria: pode ser trocado a qualquer momento antes da retirada;
- entregador livre: só pode ser trocado se não aparecer em `Restaurant.courierNoShowMinutes` (padrão de 10 min) e não estiver a menos de 200 m da loja.

### Valor da entrega

A **tabela da associação** define um valor base até X km e um valor por km extra. O entregador recebe 100% desse valor. O cálculo fica no `DeliveryRateCalculator`.

---

## Rotas

```mermaid
flowchart LR
    P[Pedidos da loja<br/>em preparo ou prontos] --> RP[RoutePlanner<br/>algoritmo puro]
    RP --> DR[DeliveryRoute<br/>grupo de pedidos]
    DR -->|leadMinutes antes<br/>de ficar pronto| OF[Oferta no pedido líder]
    OF --> C[Entregador]
```

- O `RoutePlanner` é um algoritmo puro, sem banco nem Spring, e por isso é fácil de testar. Ele agrupa pedidos da mesma direção ou bairro quando isso economiza distância.
- O `RoutePlanningService` roda a cada 10 s (`app.delivery.route-planning-ms`) e grava os grupos como `DeliveryRoute`.
- O entregador é chamado `leadMinutes` antes de o último pedido do grupo ficar pronto. Nenhum pedido sai antes de `dispatchReleasedAt`.
- A loja vê e ajusta as rotas em `/restaurante/rotas`: junta, separa e escolhe o entregador.
- O caminho pelas ruas vem do OSRM (`StreetRoutingService`) e fica salvo na rota (`street_path`, uma `LineString` do PostGIS), junto com as paradas usadas no cálculo (`street_path_key`). O painel só pede um caminho novo quando as paradas mudam. Sem resposta do OSRM, o mapa desenha linha reta.

**Duas regras fixas, travadas por testes:**
1. **O ganho do entregador nunca cai por causa da rota.** A oferta de rota paga a soma do valor cheio de cada entrega (teste `routeOfferPaysTheFullTableValueOfEveryDelivery`).
2. **O cliente nunca sabe que o pedido está esperando outro.** Ele recebe `OrderDTO.forCustomer`, sem o tipo de entregador nem os prazos internos, e o histórico usa mensagens neutras.

---

## Caixa

Em `/restaurante/caixa` (`CashReportService` e `CourierSettlement`):
- nas entregas pagas em dinheiro, o dinheiro fica com o entregador;
- o saldo de cada entregador é **dinheiro recebido − ganhos das entregas**;
- a loja registra o acerto, e o acerto fica no histórico.

---

## Jobs agendados

O agendamento é ativado por `@EnableScheduling` no `AppConfig`.

| Job | Intervalo padrão | Propriedade |
|-----|------------------|-------------|
| Expirar pedidos sem aceite | 30 s | `app.orders.expiration-check-ms` |
| Expirar ofertas e passar ao próximo | 5 s | `app.delivery.offer-check-ms` |
| Tentar de novo pedidos sem entregador | 15 s | `app.delivery.retry-ms` |
| Encerrar turnos livres sem sinal | 60 s | `app.delivery.stale-shift-check-ms` |
| Planejar rotas | 10 s | `app.delivery.route-planning-ms` |

> Os jobs rodam em cada instância do backend. Para rodar mais de uma instância, será preciso uma trava distribuída. Isso faz parte da etapa de segurança e integridade (0.4.0).

---

## Dados

- O esquema vem das migrações do Flyway (`backend/src/main/resources/db/migration`). O Hibernate só confere se as entidades batem com o banco (`ddl-auto=validate`).
- Toda mudança de entidade vira uma migração nova, inclusive valores novos de enum (o `CHECK` da coluna é recriado).
- Bancos criados antes do Flyway entram com *baseline* na V1, que tem o mesmo esquema e os mesmos nomes de restrições do antigo `ddl-auto=update`.
- O banco precisa do PostGIS: a V1 cria a extensão.

### Ações simultâneas

O mesmo pedido pode ser mexido ao mesmo tempo pela loja, pelo entregador, pelo cliente e pelos jobs. As regras abaixo evitam que uma ação desfaça a outra:

- **Quem muda um pedido trava o pedido** (`OrderRepository.findByIdForUpdate`): etapas da loja, cancelamento do cliente, aceite do entregador, retirada, entrega e jobs.
- **Ordem das travas: pedido antes do entregador.** Quem trava mais de um pedido usa `findAllByIdForUpdate`, que trava em ordem de id. Com o líder de uma rota travado, não se trava outro pedido: pede-se o despacho da rota por evento (`DispatchRequestedEvent`).
- **Trava otimista** (`@Version`) em `Order`, `DeliveryPerson`, `DeliveryOffer`, `DeliveryRoute` e `MemberInvoice`: uma gravação feita a partir de uma leitura antiga falha em vez de sobrescrever.
- **A posição do entregador é gravada à parte** (`DeliveryPersonRepository.updateLocation`), sem salvar a entidade inteira, e o `DeliveryPerson` usa `@DynamicUpdate`.
- **Conflito vira 409.** No trabalho de fundo (eventos do despacho, jobs e planejador de rotas), `DispatchService.withRetry` tenta de novo até 3 vezes.
- **O banco confere as regras de "um aberto por vez"**: uma oferta pendente por pedido e por entregador, um turno aberto e um vínculo aberto por entregador. São restrições de exclusão adiadas para o commit, porque o Hibernate insere o registro novo antes de atualizar o antigo.
- **As mudanças de status passam por `OrderStatus.canTransitionTo`.**
- O teste `ConcurrentActionsTest` reproduz cada corrida com duas threads contra o banco de verdade.

### Idempotência

- **Chave de idempotência.** Uma escrita com o cabeçalho `Idempotency-Key` fica registrada em `idempotency_keys` (`IdempotencyFilter`, na cadeia do Spring Security, depois do JWT). Repetida com a mesma chave e o mesmo corpo, ela recebe a resposta guardada, e a ação não roda de novo.
- **Quando a chave é liberada.** Erro do servidor, 409 e 429 liberam a chave, para que a ação possa ser tentada de novo.
- **No app.** Cada ação que cria algo ou mexe com dinheiro usa um `IdempotencyKey`, e o `ApiClient` tenta de novo sozinho quando a rede falha. Uma ação nova desse tipo deve seguir o mesmo padrão.

---

## Frontend (Flutter)

```
frontend/lib/
├── main.dart            # Rotas (GoRouter) e providers
├── core/ui/             # Design system: componentes App*, temas e tokens
├── models/              # Modelos por domínio (order, menu, delivery, routes, cash...)
├── services/            # Chamadas à API e ao WebSocket
├── screens/             # Telas por área: restaurant_panel, courier, association...
├── widgets/             # Widgets reutilizáveis por domínio (menu, order, delivery...)
└── utils/               # Formatadores, mapas, localização
```

### Rotas do app

| Rota | Tela | Status |
|------|------|--------|
| `/home` | Vitrine de restaurantes (a raiz `/` leva o visitante para cá) | Pronto |
| `/r/:slug` | Página da loja com o tema dela | Pronto |
| `/cart`, `/checkout` | Carrinho e checkout | Pronto |
| `/pedidos`, `/pedidos/:id` | Meus pedidos, acompanhamento e avaliação | Pronto |
| `/restaurante/*` | Painel do restaurante (pedidos, cardápio, entregadores, rotas, caixa, avaliações, loja) | Pronto |
| `/restaurante/cozinha` | Tela da cozinha | Pronto |
| `/entregador/*` | Painel do entregador | Pronto |
| `/e/:slug` | Perfil público do entregador (placa QR) | Pronto |
| `/associacao/*` | Painel da associação ou cooperativa (membros, convites, lojas parceiras, tabela, relatórios) | Pronto |
| `/admin/associacoes` | Moderação de associações | Pronto |

### Padrões

- **Componentes reutilizáveis:** tudo que se repete vira componente em `core/ui` (prefixo `App*`) ou em `widgets/<domínio>`. Veja o [README do design system](../../frontend/lib/core/ui/README.md) e a vitrine de componentes em `/ui-showcase`.
- **Painéis:** usam o `AppPanelScaffold`, com menu lateral e uma rota por aba (`panelRoutes`). A situação da loja ou do turno aparece no menu.
- **Vitrine do cliente:** usa uma barra superior de vidro (`StorefrontScaffold`). O conteúdo tem no máximo 1200 px de largura.
- **Temas da loja:** 8 presets (`AppThemePreset`) ou a cor da marca. A página da loja aplica o tema com o `RestaurantThemeScope`.
- **Tempo real:** o app assina os tópicos STOMP da tabela acima e atualiza a tela sem recarregar.

As capturas de tela de cada área estão em [`layout/`](../../layout/).

---

## Próximas etapas

O roadmap completo, versão por versão, está no [CHANGELOG](../../CHANGELOG.md#roadmap). Os pontos que afetam a arquitetura são:

- **0.4.0 Segurança e integridade:** travas contra race conditions (`@Version`, restrições no banco), rate limiting, throttling de localização e de WebSocket, idempotência nas ações que mexem com dinheiro e com status, migrações versionadas e trava distribuída para os jobs.
- **0.5.0 Auditoria de dados:** trilha de auditoria com o valor anterior e o novo, histórico que não pode ser alterado para caixa e ganhos, e LGPD.
- **0.6.0 Operação do dia a dia:** pedido criado pela loja (sem conta de cliente) no mesmo fluxo do `POST /orders`, ocorrências e novos carimbos de chegada no `Order`, custos do veículo e métricas calculadas em `CourierEarningsService`. O detalhe está em [docs/roadmap/0.6.0-operacao.md](../roadmap/0.6.0-operacao.md).
