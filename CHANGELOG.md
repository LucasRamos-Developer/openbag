# Changelog

Todas as mudanças relevantes do OpenBag ficam registradas aqui.

O formato segue o [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e as versões seguem o [Versionamento Semântico (SemVer)](https://semver.org/lang/pt-BR/).

**Versão atual: 0.2.0**

---

## Como versionamos

A versão tem o formato `MAIOR.MENOR.CORREÇÃO` (por exemplo, `0.2.0`).

### Enquanto estivermos em `0.x`

O projeto ainda está em desenvolvimento e a API pode mudar.

| Parte | Quando muda | Exemplo |
|-------|-------------|---------|
| `MENOR` | Cada etapa do [roadmap](#roadmap) entregue. Pode mudar a API ou o banco. | `0.2.0` → `0.3.0` |
| `CORREÇÃO` | Correções que não mudam o comportamento esperado. | `0.2.0` → `0.2.1` |

### A partir da `1.0.0`

| Parte | Quando muda |
|-------|-------------|
| `MAIOR` | Algo deixa de ser compatível: contrato da API REST, mensagens do WebSocket ou formato dos dados. |
| `MENOR` | Funcionalidade nova que não quebra quem já usa. |
| `CORREÇÃO` | Correção de erro, sem funcionalidade nova. |

Versões de teste usam sufixo: `0.3.0-beta.1`, `0.3.0-rc.1`.

### Onde a versão aparece

Ao fechar uma versão, atualize os quatro lugares juntos:

1. Este arquivo: mova os itens de **Não lançado** para a nova versão, com a data.
2. `backend/pom.xml`: `<version>0.2.0</version>`.
3. `frontend/pubspec.yaml`: `version: 0.2.0+N` (o `+N` é o número do build e só sobe).
4. A tag do git depois do merge na `main`: `git tag v0.2.0 && git push origin v0.2.0`.

A documentação (README, arquitetura e site) indica no topo a versão que descreve.

---

## [Não lançado]

### Adicionado

- **Painel do super admin** em `/admin`. É somente leitura e tem Visão geral, Restaurantes, Associações, Entregadores, Usuários e Pedidos. A busca e a paginação usam as rotas `GET /admin/overview|restaurants|couriers|users|orders`. A moderação de associações continua na aba Associações.
- **Conta de demonstração** com todos os perfis, inclusive ADMIN: `demo@openbag.local` / `demo1234`. Ela vem com a loja Cantina Demo (com cardápio), a Cooperativa Demo aprovada (com tabela de entrega) e o perfil de entregador vinculado. Só é criada com `OPENBAG_DEMO_ENABLED=true`, nunca em produção.
- **Rodapé da área do cliente**, com a proposta do projeto, os links para clientes e parceiros, o contato e a versão. O carrinho flutua sobre a página e o rodapé reserva o espaço dele, então nada fica escondido.
- **Card da vitrine com todas as informações**:
  - endereço no lugar da categoria;
  - botão que abre o app de mapas do aparelho (Android: app padrão, iPhone: Mapas, web: Google Maps);
  - situação com horário ("Aberto · fecha às 23:00", "Fechado · abre amanhã às 11:00");
  - prazo, taxa e pedido mínimo.
- A lista pública de restaurantes passa a enviar `address`, `pausedUntil`, `closesAt` e `nextOpenAt`.
- Script de capturas de tela em `tools/screenshots/`.
- **Rotas pelas ruas no mapa**: o painel de rotas desenha o caminho real da loja até as entregas.
  - O backend consulta um servidor OSRM (`OPENBAG_OSRM_URL`) com cache em memória e envia o `path` em cada cartão de `GET /restaurants/{id}/routes`.
  - Sem resposta do roteador, o mapa volta à linha reta.
  - O padrão é o servidor público de demonstração do OSRM, só para desenvolvimento.
- **Cardápio em acordeão**: as seções da página da loja podem ser recolhidas pelo título ou pela seta. Na busca, todas ficam abertas, e o chip de uma seção recolhida abre a seção antes de rolar até ela. O ícone grande ao lado do título saiu; os chips continuam com ícone.

### Alterado

- **Mapa com estilo próprio**, claro e próximo das cores do Google Maps, sem relevo e com a vegetação discreta. O estilo fica em `frontend/assets/map/openbag_style.json`, no formato do MapLibre. O mapa é desenhado pelo MapLibre (`maplibre_gl`) com os dados do OpenFreeMap, sem chave e sem limite de uso. O componente `AppMap` (`core/ui`) substitui o `flutter_map` nos mapas de rotas e da página da loja. Uma base raster pode entrar no lugar com `--dart-define=MAP_TILE_URL=...`.
- **Botões maiores e padronizados**: `small` 36px, `medium` 44px (padrão) e `large` 52px. O tema também aplica 44px aos botões do Material. As ações do painel do restaurante (cabeçalho de pedidos, cardápio, loja, rotas e caixa) passaram para o tamanho padrão.

### Corrigido

- O botão `large` tinha fonte menor que a do `medium`.
- A versão exibida no app era `1.0.0`; agora é `0.2.0`.

---

## [0.2.0] - 2026-09-27

Primeira versão com a operação completa do restaurante, as associações de entregadores e a nova proposta do projeto.

### Adicionado

**Restaurante: operação**
- Painel `/restaurante` com menu lateral, uma rota por aba e a situação da loja no menu.
- Pedidos em tempo real (WebSocket/STOMP), aceite manual com prazo ou automático, e alerta sonoro.
- Tela da cozinha (`/restaurante/cozinha`) e impressão de comanda em PDF de 80 mm.
- Cardápio com seções e ícones, itens, complementos e combos.
- Loja em abas: Geral, Aparência, Endereço, Horários e Pedidos e entrega. Também é possível abrir, fechar ou pausar a loja por 15, 30 ou 60 minutos.
- Tela de avaliações, por enquanto só com o resumo (a coleta entra no roadmap).

**Restaurante: personalização da página**
- 8 temas prontos (5 claros e 3 escuros) e a opção de usar a cor da marca.
- Imagem de destaque, logo e slogan, com prévia ao vivo antes de salvar.

**Entregas**
- Tabela de entrega da associação: um valor base até X km mais um valor por km extra.
- A loja escolhe com quem trabalha: qualquer entregador, só parceiros ou só entregadores fixos.
- Entregador fixo com vínculo aprovado pela loja e check-in no turno.
- Modo livre: a oferta vai para o entregador mais próximo, dando preferência a quem ganhou menos no dia. Se ele não aceitar a tempo, a oferta passa para o próximo.
- Equipe própria da loja, para entregadores que não usam o app.
- A loja pode atribuir o entregador direto e trocá-lo seguindo regras claras.
- Rotas: pedidos do mesmo bairro ou direção saem juntos, e o entregador é chamado perto de os pedidos ficarem prontos. **Agrupar nunca reduz o ganho: o entregador recebe o valor cheio de cada entrega.**
- Caixa (`/restaurante/caixa`): acerto com cada entregador (dinheiro recebido − ganhos).

**Associações e cooperativas**
- Cadastro de associação, que só passa a valer depois da aprovação do administrador.
- Painel do gestor: membros (aprovar, suspender, reativar, remover), convites por código, perfil e tabela de entrega.
- Tela de moderação para o administrador.

**Entregador (em desenvolvimento)**
- Painel `/entregador` com as abas Trabalhar, Ganhos, Lojas, Veículos, Perfil e Placa.
- Ficar online, receber ofertas em tempo real, retirar e entregar.
- Ganhos do dia e histórico, vários veículos (um ativo), perfil público em `/e/:slug` e placa com QR code.

**Cliente (em testes)**
- Vitrine de restaurantes, página da loja em `/r/:slug`, carrinho com complementos, checkout com pagamento na entrega e acompanhamento do pedido em `/pedidos`.

**Base do frontend**
- Design system em `frontend/lib/core/ui` (componentes, tokens de cor por tema e fonte Plus Jakarta Sans).
- Capturas de tela de referência em [`layout/`](layout/).

### Alterado
- Documentação reescrita com a nova proposta: dar visibilidade a pequenos negócios e, quando possível, apoiar cooperativas de entregadores.
- Nova documentação de arquitetura em [`docs/architecture/`](docs/architecture/README.md).
- Versões do backend e do frontend alinhadas em `0.2.0`.
- O `Dockerfile` do backend passou a encontrar o `.jar` independentemente da versão.

### Corrigido
- O cadastro de restaurante ficava sem categorias porque o app chamava uma rota inexistente. Agora ele usa `GET /public/categories`.

---

## [0.1.0] - 2026-04-27

Primeira versão (MVP).

### Adicionado
- Cadastro e login de clientes e restaurantes com JWT.
- Onboarding do restaurante (dados, endereço, categorias e aparência inicial).
- Produtos, carrinho e pedidos básicos.
- Mapas com OpenStreetMap.
- Backend organizado em módulos (`modules/*`) e ambiente com Docker Compose (PostgreSQL, Redis e Elasticsearch).

---

## Roadmap

Cada etapa vira uma versão `MENOR`. A ordem pode mudar; o que valer fica registrado aqui.

| Versão | Etapa | Status |
|--------|-------|--------|
| 0.1.0 | MVP | Lançada |
| 0.2.0 | Operação do restaurante, associações e personalização | **Atual** |
| 0.3.0 | Entregador, cooperativa e cliente | Em andamento |
| 0.4.0 | Segurança e integridade dos dados | Planejada |
| 0.5.0 | Auditoria de dados | Planejada |
| 1.0.0 | Primeira versão estável (piloto real) | Planejada |

### 0.3.0: Entregador, cooperativa e cliente
- Concluir as telas do entregador.
- Painel da cooperativa: parcerias com lojas, acordos e relatórios para os cooperados.
- Fluxo do cliente fora da fase de testes, com coleta de avaliações.
- Visibilidade: página da loja otimizada para buscadores (SEO) e vitrine ordenada por avaliações e proximidade, sem posição paga.

### 0.4.0: Segurança e integridade dos dados
- **Race conditions:** dois entregadores aceitando a mesma oferta, pedido mudando de status ao mesmo tempo no painel e na cozinha, acerto de caixa em paralelo. Usar travas otimistas (`@Version`) e restrições no banco, com testes de concorrência.
- **Rate limiting:** limite por IP e por usuário no login, no cadastro, na criação de pedidos e no envio de arquivos.
- **Throttling:** controlar a frequência de atualizações de localização do entregador, de mensagens do WebSocket e dos jobs agendados.
- **Idempotência:** chave de idempotência em `POST /orders`, no aceite de oferta, no acerto de caixa e nas re-tentativas do app, para que a mesma ação nunca seja aplicada duas vezes.
- **Integridade:** migrações versionadas no lugar de `ddl-auto=update`, restrições de banco (chaves, únicos, checks) e validação de valores recalculados no servidor.
- **Revisão de segurança:** permissões por papel em todas as rotas, OWASP Top 10, segredos fora do código e dependências atualizadas.

### 0.5.0: Auditoria de dados
- Trilha de auditoria: quem mudou o quê e quando, com o valor anterior e o novo, para pedidos, cardápio e preços, caixa, ganhos e vínculos.
- Histórico que não pode ser alterado para acertos de caixa e ganhos do entregador.
- Relatórios exportáveis para a loja e para a cooperativa.
- LGPD: exportação e exclusão de dados pessoais e política de retenção.

### 1.0.0: Primeira versão estável
- Piloto com uma cidade e uma cooperativa.
- API REST e mensagens do WebSocket estáveis e documentadas.
- App web publicado.

### Ideias sem versão definida
- Apps nativos para Android e iOS.
- Pagamento online.
- Vários idiomas.
- Federação de cooperativas e governança compartilhada.

[Não lançado]: https://github.com/LucasRamos-Developer/openbag/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/LucasRamos-Developer/openbag/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/LucasRamos-Developer/openbag/releases/tag/v0.1.0
