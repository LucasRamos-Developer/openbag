# API REST do OpenBag

> Descreve a versão 0.4.0. A lista completa e sempre atualizada fica no **Swagger**: `http://localhost:8080/api/swagger-ui.html`. O Swagger só existe em desenvolvimento e fica desligado no perfil `prod`.

Todas as rotas ficam sob o prefixo **`/api`**. Os exemplos abaixo omitem esse prefixo.

---

## Autenticação

O login devolve um **JWT** (`accessToken`, válido por 24 horas), que vai no cabeçalho de cada requisição:

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "demo@openbag.local", "password": "demo1234"}'

curl http://localhost:8080/api/orders/mine -H "Authorization: Bearer <accessToken>"
```

A conta `demo@openbag.local` só existe com `OPENBAG_DEMO_ENABLED=true` (veja o [guia de desenvolvimento](../../README-DEVELOPER.md#conta-de-demonstração)).

- O token carrega só o id do usuário. Os papéis e as permissões são lidos do banco a cada requisição, e uma conta desativada perde o acesso na hora.
- **Papéis:** `CUSTOMER`, `RESTAURANT_OWNER`, `DELIVERY_PERSON`, `ASSOCIATION_MANAGER` e `ADMIN`. Um usuário pode ter vários.
- **Dono do recurso:** além do papel, cada rota confere o dono (`@IsRestaurantOwner`, `@IsAssociationManager` e consultas limitadas ao usuário). O ADMIN passa em todas.
- O cadastro público (`POST /auth/register`) sempre cria um **cliente**. Loja, associação e entregador têm cadastros próprios.

---

## Cabeçalhos especiais

| Cabeçalho | Direção | Uso |
|---|---|---|
| `Authorization: Bearer <token>` | envio | Autenticação |
| `Idempotency-Key: <uuid>` | envio | A mesma ação enviada de novo com a mesma chave recebe a resposta da primeira vez, sem repetir a ação. Vale para qualquer POST, PUT, PATCH ou DELETE de um usuário logado (menos uploads). O app manda a chave ao fazer pedido, no pedido do balcão, no acerto de caixa, na baixa de fatura, no livro-caixa e no aceite de oferta. |
| `Idempotency-Replayed: true` | resposta | A resposta é a repetição da primeira |
| `Retry-After: <segundos>` | resposta | Quanto esperar: em um 429 (limite de requisições) ou em um 409 de "ação ainda em andamento" |

---

## Rotas por área

As tabelas mostram as rotas principais de cada área. Todas as rotas estão no Swagger.

### Cadastro e conta

| Rota | O que faz |
|---|---|
| `POST /auth/login` | Login (limite: 10 por minuto por IP e 10 a cada 15 minutos por email) |
| `POST /auth/register` | Cadastro de cliente |
| `POST /auth/register/restaurant` | Cadastro de loja, em JSON ou multipart com logo e banner ([detalhes](../../backend/docs/onboarding-restaurante.md)) |
| `POST /auth/register/association` e `/auth/register/delivery-person` | Cadastro de associação e de entregador |
| `GET /auth/check-email` | Email disponível? |
| `GET /auth/me` | Usuário logado, com papéis e permissões |
| `GET`, `PUT`, `DELETE /users/profile` | Perfil (nome e telefone) e desativação da conta |
| `/users/addresses` | Endereços salvos |

### Vitrine (sem login)

| Rota | O que faz |
|---|---|
| `GET /public/restaurants` | Lojas ativas (também `/search`, `/nearby` e `/category/{id}`) |
| `GET /public/restaurants/{idOrSlug}` e `/menu` | Página e cardápio da loja |
| `GET /public/restaurants/{idOrSlug}/delivery-quote` | Taxa de entrega para um endereço |
| `GET /public/categories` | Categorias |
| `GET /public/couriers/{slug}` | Perfil público do entregador (placa QR) |
| `GET /public/associations` e `/invites/{code}` | Associações ativas e validação de convite |

### Cliente

| Rota | O que faz |
|---|---|
| `POST /orders` | Fazer pedido. O servidor recalcula os preços e a taxa. Aceita `Idempotency-Key`. |
| `POST /orders/delivery-quote` | Taxa de entrega no checkout |
| `GET /orders/mine` e `GET /orders/{id}` | Meus pedidos e acompanhamento |
| `POST /orders/{id}/cancel` | Cancelar (só antes de a loja aceitar) |
| `POST /orders/{id}/review` | Avaliar a loja e o entregador |

### Loja (dono do restaurante)

| Rota | O que faz |
|---|---|
| `GET /restaurants/mine` e `/restaurants/{id}/store` | Minhas lojas e a situação de cada uma |
| `PUT /restaurants/{id}/settings`, `/profile`, `/address`, `/appearance` e `/opening-hours` | Configurações, dados, endereço, tema e horários |
| `POST` e `DELETE /restaurants/{id}/pause`, `PUT /restaurants/{id}/open` | Pausar, abrir e fechar |
| `/restaurants/{id}/menu/**` | Cardápio: seções, itens, complementos, combos, fotos e disponibilidade |
| `GET /restaurants/{id}/orders/board` e `GET /restaurants/{id}/orders` | Pedidos ativos e histórico do dia |
| `POST /restaurants/{id}/orders` | Pedido do balcão, do telefone ou do WhatsApp (entra já aceito). Aceita `Idempotency-Key`. |
| `POST /restaurants/{id}/orders/{orderId}/accept`, `reject`, `start`, `ready`, `dispatch` e `deliver` | Etapas do pedido |
| `/restaurants/{id}/delivery/**` | Regras de entrega, parcerias, entregadores fixos, equipe própria e atribuição do entregador |
| `/restaurants/{id}/routes/**` | Rotas: juntar, separar, chamar o entregador agora e atribuir |
| `GET /restaurants/{id}/cash` e `POST /restaurants/{id}/cash/settlements` | Caixa do período e acerto com um entregador. O acerto aceita `Idempotency-Key`. |
| `/restaurants/{id}/reviews` | Avaliações e respostas |

### Entregador

| Rota | O que faz |
|---|---|
| `/me/courier` | Perfil, foto, veículos, ganhos e histórico |
| `/me/courier/restaurants` | Vínculos de entregador fixo |
| `GET /me/courier/work` | Situação: turno, oferta pendente e entregas em andamento |
| `POST /me/courier/work/online` e `/offline`, `/checkin/{restaurantId}` e `/checkout` | Turno livre ou fixo |
| `PUT /me/courier/work/location` | Posição (o servidor aceita no máximo uma a cada 10 s) |
| `POST /me/courier/work/offers/{id}/accept` e `/decline` | Responder a oferta. Repetir o aceite devolve a mesma entrega. |
| `POST /me/courier/work/orders/{id}/pickup` e `/deliver` | Retirada e entrega |
| `GET /me/courier/earnings?from=&to=` | Ganhos de hoje, da semana e do mês (com km) e do período, com km, tempo e médias (`stats`). Só o próprio entregador. Traz também o resultado estimado (`cost`) com os custos do veículo. |
| `PUT /me/courier/vehicles/{id}/costs` | Custos do veículo: consumo, preço do combustível, manutenção e depreciação por km (todos opcionais; vazio apaga) |
| `POST /me/courier/work/orders/{id}/incidents` | Relatar uma ocorrência (`type`, `note`) na entrega em andamento. A loja vê no pedido; o cliente não. |
| `/me/association/**` | Área do cooperado: vínculo, resumo, faturas, adicionais, caixinha, convênios, enquetes e documentos |

### Associação ou cooperativa (gestor)

| Rota | O que faz |
|---|---|
| `GET /associations/me`, `GET` e `PUT /associations/{id}`, `PUT /associations/{id}/delivery-rate` | Dados e tabela de entrega |
| `/associations/{id}/members/**` e `/invites/**` | Associados (com exportação em CSV) e convites |
| `/associations/{id}/partnerships/**` e `/reports` | Lojas parceiras, tabela especial e relatórios |
| `/associations/{id}/fee-policy`, `/addon-plans`, `/invoices/**`, `/ledger` e `/finance/summary` | Mensalidade, adicionais, faturas (baixa, dispensa e reabertura), livro-caixa e painel financeiro |
| `/associations/{id}/benefits`, `/polls` e `/documents` | Convênios, enquetes e atas |

### Administração

| Rota | O que faz |
|---|---|
| `/admin/overview`, `/admin/restaurants`, `/admin/couriers`, `/admin/users` e `/admin/orders` | Painel da plataforma (só leitura) |
| `/admin/associations/**` | Aprovar, recusar e suspender associações |

### Arquivos e saúde

| Rota | O que faz |
|---|---|
| `GET /files/**` | Imagens enviadas (lojas, itens, entregadores, associações e convênios). Só serve imagens, com o tipo fixo. |
| `GET /health` | Health check |

> **Rotas antigas.** `/products`, `/combos`, `/customizations`, `/global-products` e o CRUD de `/restaurants` vêm do MVP. O app não usa essas rotas, e as escritas são só de ADMIN. O cardápio da loja fica em `/restaurants/{id}/menu`. Decidir se elas saem está anotado em [Fora desta versão](../roadmap/0.4.0-seguranca.md#fora-desta-versão).

---

## Tempo real (WebSocket/STOMP)

- **Endpoint:** `/api/ws`. O JWT vai no cabeçalho `Authorization` do frame `CONNECT`, e a sessão é fechada quando o token vence.
- **Tópicos:**
  - `/topic/restaurants/{id}/orders`: pedidos da loja, para o dono;
  - `/topic/orders/{id}`: acompanhamento do pedido, para o cliente;
  - `/topic/couriers/{id}`: ofertas e entregas, para o entregador.
- Cada `SUBSCRIBE` é autorizado, e os clientes não enviam mensagens. Detalhes na [arquitetura](../architecture/README.md#tempo-real-websocketstomp).

---

## Erros

O corpo de erro é sempre JSON:

```json
{
  "status": 400,
  "message": "Informe o motivo para o cliente",
  "timestamp": "2026-09-29T14:30:00",
  "path": "uri=/api/restaurants/1/orders/10/reject"
}
```

Erros de validação trazem também `fieldErrors`, com a mensagem de cada campo.

| Código | Quando |
|---|---|
| `400` | Dados inválidos ou ação não permitida no estado atual (ex.: pedido já cancelado) |
| `401` e `403` | Sem login ou sem permissão |
| `404` | Recurso não existe ou não é seu |
| `405` | Método não aceito pela rota |
| `409` | Conflito: outra pessoa mudou o registro no mesmo instante, uma restrição do banco foi violada ou a mesma ação ainda está em andamento (com `Retry-After`). Atualize e tente de novo. |
| `413` | Envio acima de 10 MB. Uma imagem acima de 5 MB recebe 400. |
| `422` | `Idempotency-Key` já usada com outro corpo |
| `429` | Limite de requisições atingido, com `Retry-After` ([limites](../../README-DEVELOPER.md#limite-de-requisições-rate-limiting)) |
| `500` | Erro inesperado, sem detalhes internos na resposta |

---

## Coleção do Postman

`backend/docs/postman-collection.json` cobre só o cadastro de restaurante. Para o resto, use o Swagger.
