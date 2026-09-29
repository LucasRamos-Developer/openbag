# Changelog

Todas as mudanças relevantes do OpenBag ficam registradas aqui.

O formato segue o [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/) e as versões seguem o [Versionamento Semântico (SemVer)](https://semver.org/lang/pt-BR/).

**Versão atual: 0.3.0**

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

### Segurança

- **Segredos de produção obrigatórios.** O novo perfil `prod` (padrão da imagem Docker) não tem valores padrão para o segredo do JWT, o banco e as origens do app. O `SecretsValidator` impede o backend de subir com o segredo de desenvolvimento, com a senha `admin123` ou com a conta de demonstração ligada. Nos outros perfis, ele só avisa no log.
- **O cadastro público sempre cria um cliente.** Antes, o `userType` enviado no corpo era gravado e, sem roles, virava a permissão do usuário. Isso permitia criar uma conta ADMIN. O tipo legado não concede mais permissão nenhuma.
- **Uploads só de imagens de verdade.** O tipo é detectado pelos bytes do arquivo (JPEG, PNG, WEBP ou GIF), e a extensão salva vem desse tipo, e não do nome enviado. A pasta de destino fica presa ao diretório de upload. A rota `/files` só serve imagens, com o tipo fixo e uma política que não roda scripts. Antes, um HTML enviado como `.png` ou com a extensão `.html` era servido como página.
- A rota genérica `POST /files/upload/{folder}`, que qualquer usuário logado podia usar, saiu. Cada imagem continua sendo enviada pela rota do próprio recurso.
- **CORS e WebSocket só das origens configuradas** (`OPENBAG_CORS_ORIGINS`), em vez de qualquer origem. O CORS passou a aceitar `PATCH`.
- Uma conta desativada perde o acesso na hora, na API e no WebSocket, mesmo com um token ainda válido.
- **Limite de requisições (rate limiting)** no login (por IP e por email), nos cadastros, na consulta de email, nas cotações de entrega, nos pedidos e nos envios de arquivo. Passou do limite, a resposta é 429 com `Retry-After`, e o app mostra quanto esperar. Os contadores ficam no Redis (Bucket4j) e valem para todas as instâncias. Sem Redis, cada instância conta sozinha. Os limites mudam por configuração (veja o README-DEVELOPER).

### Adicionado

- **Idempotência** pelo cabeçalho `Idempotency-Key`: a mesma ação enviada de novo com a mesma chave recebe a resposta da primeira vez, e não é aplicada de novo.
  - Vale para qualquer POST, PUT, PATCH ou DELETE de um usuário logado.
  - Com a mesma chave e outro corpo, o servidor responde 422. Se a primeira ainda estiver rodando, responde 409 com `Retry-After`.
  - As chaves ficam guardadas por 24 horas (V4).
  - O app manda a chave ao finalizar o pedido, no pedido do balcão, no acerto de caixa, na baixa de fatura, no lançamento do livro-caixa e no aceite de oferta. Leituras e envios com chave são tentados de novo sozinhos quando a rede falha. A chave só muda quando o servidor responde: se a rede cair no meio do checkout, tocar de novo devolve o mesmo pedido, sem criar outro.
  - Aceitar de novo uma oferta já aceita pelo mesmo entregador devolve a entrega dele, em vez de "oferta não disponível".
- **Roadmap da 0.4.0 (Segurança e integridade dos dados)** em [docs/roadmap/0.4.0-seguranca.md](docs/roadmap/0.4.0-seguranca.md). O documento compara cada item com o código atual e lista os casos encontrados: brechas no cadastro, no upload e nos segredos padrão, ações simultâneas que corrompem pedidos e faturas, e a falta de idempotência, limites de requisição e migrações versionadas.

### Alterado

- **Migrações versionadas com Flyway.** O esquema vem de `db/migration`, e o Hibernate só confere se as entidades batem com o banco (`ddl-auto=validate`). A V1 foi gerada das entidades e tem os mesmos nomes de chaves, únicos e checks que o `ddl-auto=update` criava, então um banco que já existia entra com *baseline* na V1 sem diferença. Os preenchimentos que rodavam em toda subida (`DataBackfill`) viraram a V2. Saíram o `schema.sql` (a V1 cria a extensão PostGIS) e os scripts MySQL antigos, que nunca rodavam.
  - **Banco local antigo:** se o backend acusar `Schema-validation: missing column`, o banco está atrás do código. Suba uma vez com `--spring.jpa.hibernate.ddl-auto=update` e volte ao normal (veja o README-DEVELOPER).
- **Restrições no banco (V3):**
  - trava otimista (`version`) em pedidos, entregadores, ofertas, rotas e faturas;
  - uma oferta pendente por pedido e por entregador;
  - um turno, um vínculo com associação e um vínculo fixo abertos por entregador;
  - uma parceria aberta por loja e associação;
  - número do pedido único no dia;
  - status e loja obrigatórios no pedido;
  - um só tipo de entregador por entrega;
  - valores em dinheiro nunca negativos.
  - Conflito de trava e violação de restrição respondem **409** com uma mensagem para atualizar a tela, e não mais 500.
- **Testes de integração** com Testcontainers, contra a mesma imagem Postgres + PostGIS do docker-compose. O primeiro (`FlywayMigrationTest`) falha se uma entidade mudar sem migração.

### Corrigido

- **Ações simultâneas que corrompiam pedidos e dinheiro.** Cada caso tem um teste com duas threads contra o banco de verdade (`ConcurrentActionsTest`), que falhava antes da correção:
  - O ping de localização do entregador, a cada 20 segundos, podia desfazer o aceite de uma oferta. O entregador voltava a "online" com um pedido em mãos e recebia outro. Agora a posição é gravada à parte.
  - A loja marcando "pronto" durante o aceite apagava o entregador do pedido, e o pedido era oferecido a outro. Todas as etapas da loja passaram a travar o pedido.
  - O cancelamento do cliente e o aceite da loja no mesmo instante valiam os dois. Agora só um vale.
  - Dois cliques na baixa de uma fatura lançavam a mensalidade e a caixinha duas vezes. Dois auxílios ao mesmo tempo podiam deixar a caixinha negativa.
  - O aceite de oferta travava o entregador antes do pedido, e a atribuição pela loja fazia o contrário. Isso podia dar deadlock (500 no app). A ordem agora é única: pedido e depois entregador, e vários pedidos sempre em ordem de id.
- A expiração de pedidos sem resposta e a geração mensal de faturas rodavam numa transação só: um erro desfazia todos. Agora é uma transação por pedido e por associação. O despacho em segundo plano tenta de novo quando encontra um conflito.
- Uma enxurrada de endereços diferentes no checkout prendia as threads do servidor na fila da geocodificação (1 consulta por segundo, com a thread dormindo na vez). Agora cada consulta reserva uma vaga e desiste se ela passar de 3 segundos: o endereço fica sem coordenadas e a taxa usa o valor "a partir de".
- A resposta da foto de perfil e o `GET /users/profile` entravam num laço entre papéis e permissões e quebravam no meio do JSON.
- Método não permitido e rota inexistente respondiam 500. Agora respondem 405 e 404.

---

## [0.3.0] - 2026-09-29

### Adicionado

- **SEO sem mudar a arquitetura** (o app continua Flutter web):
  - `web/index.html` com idioma, título, descrição, Open Graph, cor do tema e texto em `<noscript>`.
  - A vitrine e a página da loja trocam o título, a descrição e o canônico (widget `PageMeta`). A loja publica os dados estruturados do schema.org `Restaurant`, com endereço, horários, nota (só com avaliações) e cardápio.
  - `tools/seo/build_seo.py`, rodado no deploy, gera o `robots.txt` e o `sitemap.xml` com as lojas ativas e deixa absolutas as URLs do Open Graph.
  - A prévia de links no WhatsApp e no Facebook mostra a imagem padrão do OpenBag. A prévia por loja precisaria de HTML gerado no servidor ou na hospedagem.
- **Vitrine por proximidade**: a ordenação "Mais perto" usa o GPS do navegador e, se ele for negado, o ponto do último endereço de entrega (guardado no aparelho ao fazer um pedido ou, com login, o do último pedido). O card mostra a distância em linha reta, e a vitrine diz de onde ela foi medida. A opção só some quando o GPS foi bloqueado de vez e não há endereço. A posição fica só no aparelho; nada é enviado ao servidor. Distâncias abaixo de 1 km aparecem em metros.
- **Roadmap da 0.6.0 (Operação do dia a dia)** em [docs/roadmap/0.6.0-operacao.md](docs/roadmap/0.6.0-operacao.md). O documento compara as sugestões de produto por papel com o código atual e lista oito itens para antes do piloto, cada um com o estado atual, o código relacionado, o que falta e quando fica pronto.
- **Gestão da associação** no painel da cooperativa:
  - **Financeiro**, com cinco abas:
    - Resumo: saldo da caixinha, arrecadado, gasto, a receber e gráfico de entradas e saídas por mês.
    - Faturas do mês: prévia do mês em andamento, geração das que faltam, baixa manual por Pix ou dinheiro, dispensa e desfazer.
    - Livro-caixa com lançamentos manuais.
    - Caixinha solidária.
    - Cobrança.
  - **Cobrança do cooperado**: valor fixo ou percentual dos ganhos do mês até um teto (depois do teto, só os adicionais). As faturas do mês anterior são geradas sozinhas no dia 1.
  - **Adicionais**, como o seguro de vida de +10% na mensalidade. A associação propõe, e o cooperado aceita ou recusa no painel dele.
  - **Caixinha solidária**:
    - contribuição mensal escolhida pelo cooperado (entra na fatura);
    - contribuições avulsas;
    - auxílios, que nunca deixam o saldo negativo.
    - O cooperado vê o saldo e os auxílios sem o nome de quem recebeu.
  - **Convênios** com oficinas, escolas de idiomas e outros parceiros, com botões de ligar, mapa e site.
  - **Assembleia**:
    - enquetes com voto secreto, um voto por cooperado ativo e encerramento automático;
    - atas e documentos em PDF, que só os cooperados e o gestor baixam.
  - **Associados**: veículos na ficha, filtros por veículo e por mensalidade (em aberto ou em dia), valor em aberto na lista e exportação em CSV que abre direto no Excel.
- **Área do cooperado** em `/entregador/associacao`: resumo com o que pede ação (adicional proposto, fatura em aberto, enquete para votar), faturas, convênios, enquetes e documentos. O cartão "Minha associação" saiu do Perfil e veio para cá.
- **Taxa de entrega repassada ao cliente**:
  - A loja escolhe entre a taxa fixa (como antes) e repassar ao cliente.
  - Repassando, o cliente paga pela distância, sempre pela maior tabela entre as associações que podem levar o pedido, e o entregador recebe o valor inteiro.
  - A vitrine, a página da loja e o carrinho mostram "a partir de"; no checkout aparece o valor exato para o endereço.
  - O endereço digitado é localizado no mapa (Nominatim do OpenStreetMap, `OPENBAG_GEOCODING_URL`).
- **Contraproposta** na negociação da tabela entre loja e associação. O convite da associação pode já trazer uma tabela proposta; o outro lado aceita, recusa ou manda outra proposta, e a vez passa.
- **Celular com telas próprias**:
  - formulários em tela cheia, com a ação principal fixa no rodapé;
  - ações e filtros num menu de baixo para cima;
  - totais numa faixa só;
  - botão flutuante para a ação principal;
  - sub-abas em pílulas roláveis.
  - Componentes novos em `core/ui`: `showAppAdaptive`, `showAppActionSheet`, `AppListTileCard`, `AppDropdownChip`, `AppMonthSelector`, `AppDateField`, `AppLoadView`, `AppStatStrip` e `AppKeyValueList`.
- **Painel do super admin** em `/admin`. É somente leitura e tem Visão geral, Restaurantes, Associações, Entregadores, Usuários e Pedidos. A busca e a paginação usam as rotas `GET /admin/overview|restaurants|couriers|users|orders`. A moderação de associações continua na aba Associações.
- **Conta de demonstração** com todos os perfis, inclusive ADMIN: `demo@openbag.local` / `demo1234`. Ela vem com a loja Cantina Demo (com cardápio), a Cooperativa Demo aprovada (com tabela de entrega) e o perfil de entregador vinculado. Só é criada com `OPENBAG_DEMO_ENABLED=true`, nunca em produção.
- **Rodapé da área do cliente**, com a proposta do projeto, os links para clientes e parceiros, o contato e a versão. O carrinho flutua sobre a página e o rodapé reserva o espaço dele, então nada fica escondido. A barra do topo ficou sem o logo, que agora aparece só no rodapé.
- **Card da vitrine com todas as informações**:
  - endereço no lugar da categoria;
  - botão que abre o app de mapas do aparelho (Android: app padrão, iPhone: Mapas, web: Google Maps);
  - situação com horário ("Aberto · fecha às 23:00", "Fechado · abre amanhã às 11:00");
  - prazo, taxa e pedido mínimo.
- O card da vitrine usa as cores de cada loja no logo e na imagem de fundo. Sem foto, aparece o mesmo fundo do banner da página da loja (cor da marca com bolinhas, componente `AppBrandBackdrop`).
- A lista pública de restaurantes passa a enviar `address`, `pausedUntil`, `closesAt`, `nextOpenAt`, `themePreset`, `brandColor` e `primaryColor`.
- **Busca e ordenação na vitrine**: a busca procura por nome, categoria, bairro ou cidade, sem diferenciar acentos. Há cinco ordenações: recomendados, melhor avaliados, entrega mais rápida, menor taxa e menor pedido mínimo; nelas, as lojas abertas vêm primeiro. O título "Restaurantes" ganhou o estilo com sublinhado (`AppSectionTitle`), sem o ícone.
- Script de capturas de tela em `tools/screenshots/`.
- **Rotas pelas ruas no mapa**: o painel de rotas desenha o caminho real da loja até as entregas.
  - O backend consulta um servidor OSRM (`OPENBAG_OSRM_URL`) com cache em memória e envia o `path` em cada cartão de `GET /restaurants/{id}/routes`.
  - Sem resposta do roteador, o mapa volta à linha reta.
  - O padrão é o servidor público de demonstração do OSRM, só para desenvolvimento.
- **Cardápio em acordeão**: as seções da página da loja podem ser recolhidas pelo título ou pela seta. Na busca, todas ficam abertas, e o chip de uma seção recolhida abre a seção antes de rolar até ela. O ícone grande ao lado do título saiu, e o título usa o mesmo estilo com sublinhado da vitrine, na cor da loja. Os chips continuam com ícone.

- **Avaliações do pedido**: depois da entrega, o cliente avalia a loja (obrigatório) e o entregador do app (opcional), com comentário, em até 7 dias. Cada pedido é avaliado uma vez.
  - As médias da loja e do entregador são recalculadas a cada avaliação e aparecem na vitrine, no perfil público `/e/:slug` e na aba Perfil do entregador.
  - A aba Avaliações do painel da loja mostra a média, a distribuição por nota e os comentários, e a loja pode responder. A nota do entregador não aparece para a loja.
  - Rotas: `POST /orders/{id}/review`, `GET /restaurants/{id}/reviews`, `GET /restaurants/{id}/reviews/summary` e `POST /restaurants/{id}/reviews/{reviewId}/reply`.
- **Entregador no mapa**: depois da retirada, o cliente acompanha o entregador em `/pedidos/:id`, em tempo real (mensagem `COURIER_LOCATION` no tópico do pedido). Numa rota, o mapa só aparece quando é a vez do pedido, então o cliente nunca vê o entregador indo para outra entrega. A equipe própria da loja não usa o app e não aparece no mapa.
- **Diferença assumida no Caixa**: um card mostra quanto a loja pagou da diferença entre a taxa cobrada do cliente e a tabela da associação, com o total, os valores por associação e o detalhe de cada pedido (km, taxa cobrada, valor da tabela e diferença). O entregador sempre recebe o valor cheio da tabela.
- **Painel da cooperativa: lojas parceiras** em `/associacao/lojas`.
  - A loja ou a associação pede a parceria, e o outro lado aceita ou recusa. Se um lado pede quando o outro já tinha convidado, a parceria começa na hora. Os dois lados podem encerrar.
  - A associação convida lojas pela busca pelo nome e vê os pedidos das lojas, as parceiras, os convites enviados e o histórico.
  - Se a associação encerra a última parceria de uma loja que recebe pedidos só de parceiras, a loja passa a receber de qualquer entregador e vê um aviso.
  - Rotas: `GET|POST /associations/{id}/partnerships`, `POST /associations/{id}/partnerships/{pid}/accept|decline|end` e, na loja, `POST /restaurants/{id}/delivery/partners/{pid}/accept|decline|end`.
- **Tabela especial por loja (acordo)**: numa parceria ativa, a loja ou a associação propõe uma tabela própria (base até X km + R$/km), e ela só vale depois do aceite do outro lado. Voltar à tabela padrão também precisa do aceite.
  - O despacho usa a tabela que vale na loja em qualquer política (qualquer entregador, só parceiras ou fixos). A regra de assumir a diferença continua valendo, e o entregador sempre recebe 100%.
  - Rotas: `POST .../rate-proposal` e `POST .../rate-accept|rate-decline|rate-cancel`, nos dois lados.
- **Relatórios da cooperativa** em `/associacao/relatorios`: entregas, total pago aos cooperados, km, lojas atendidas e diferença assumida pelas lojas, com o gráfico por dia e as listas por cooperado e por loja (`GET /associations/{id}/reports`, até 92 dias).
- **Minha associação**, na aba Ganhos do entregador: o total da associação no período, a parte dele e as lojas atendidas, sem os ganhos dos colegas (`GET /me/association/report`).
- A Visão geral da associação mostra as lojas parceiras e avisa sobre os pedidos de parceria. Os menus da associação (Lojas parceiras) e da loja (Entregadores) ganham um selo com o que espera resposta.
- O pedido guarda a associação do entregador no momento da entrega (`courierOrganization`). Na subida, os pedidos antigos recebem a associação atual do entregador, e as parcerias antigas passam a ativas.

### Alterado

- **Entrada do cliente revisada** (fluxo do cliente fora da fase de testes):
  - Quem abre o endereço principal (`/`) vai direto para a vitrine, sem passar pelo login. A abertura também ficou mais rápida (a marca aparece por no mínimo 0,8 s, e não mais 3 s).
  - O cadastro ganhou o mesmo visual do login (componente `AuthCard`, com "Voltar" para a loja). Depois de criar a conta, o cliente já entra e volta para onde estava, como o checkout, sem digitar a senha de novo.
  - O cadastro mostra a mensagem do servidor, como "Email já está em uso", em vez de um erro genérico.
  - "Esqueceu a senha?" agora explica como recuperar o acesso pelo contato do projeto. Antes o botão não fazia nada.
  - O telefone do restaurante no acompanhamento do pedido aparece formatado e liga ao toque.
  - O botão de rodapé do carrinho e do checkout acompanha a largura do conteúdo no desktop (componente `StorefrontBottomAction`).
  - Os campos de telefone usam o `PhoneFormatter`, que não guarda estado entre os campos, no lugar da máscara global compartilhada.
- **O caminho pelas ruas de cada rota fica salvo no banco.** Ele é gravado na própria rota (`delivery_routes.street_path`, uma `LineString` do PostGIS), junto com as paradas usadas no cálculo. O painel só pede um caminho novo ao OSRM quando as paradas mudam, e o caminho não se perde quando o backend reinicia. O pedido sozinho, sem rota, continua só no cache em memória.
  - O banco agora precisa do **PostGIS**: o `docker-compose.yml` monta a imagem `database/Dockerfile` (a `postgres:15` oficial com o pacote do PostGIS), e o backend cria a extensão na subida (`schema.sql`). A base continua a mesma da `postgres:15`, então o volume atual continua valendo, sem diferença de collation. Para trocar a imagem: `docker compose up -d --build postgres`.
- **Mapa com estilo próprio**, claro e próximo das cores do Google Maps, sem relevo e com a vegetação discreta. O estilo fica em `frontend/assets/map/openbag_style.json`, no formato do MapLibre. O mapa é desenhado pelo MapLibre (`maplibre_gl`) com os dados do OpenFreeMap, sem chave e sem limite de uso. O componente `AppMap` (`core/ui`) substitui o `flutter_map` nos mapas de rotas e da página da loja. Uma base raster pode entrar no lugar com `--dart-define=MAP_TILE_URL=...`.
- **A parceria com uma associação agora precisa do aceite dela.** `POST /restaurants/{id}/delivery/partners` passou a enviar um pedido, não mais a criar a parceria direto. As parcerias que já existiam continuam ativas.
- No painel da associação, a seção Entregas passou a se chamar **Tabela de entrega**.
- Os campos da tabela de entrega viraram o componente `DeliveryRateFields`, usado na tabela da associação e na proposta de tabela especial. Os períodos do Caixa viraram o `ReportPeriod`, também usado nos relatórios da associação.
- **Botões maiores e padronizados**: `small` 36px, `medium` 44px (padrão) e `large` 52px. O tema também aplica 44px aos botões do Material. As ações do painel do restaurante (cabeçalho de pedidos, cardápio, loja, rotas e caixa) passaram para o tamanho padrão.

### Corrigido

- O app web pedia `favicon.png` e os ícones do `manifest.json`, que não existiam (erro 404). Agora eles são gerados com a sacola do logo (`tools/brand/generate_web_icons.py`). O título da aba era "Open Food - Delivery Open Source".
- Um link direto para uma página que exige login, como `/pedidos/12`, podia perder o destino e cair na tela inicial do perfil quando a sessão salva demorava a ser restaurada. Agora a abertura guarda o destino (`/?next=`) e volta para ele.
- A tela de cadastro tinha o botão "Criar conta" saindo do card no celular.
- A diferença assumida no Caixa agrupava as entregas pela associação atual do entregador. Agora usa a associação dele no dia da entrega.
- No perfil público do entregador, a nota aparecia com ponto ("4.0") e "1 avaliações" no plural.
- O botão `large` tinha fonte menor que a do `medium`.
- A versão exibida no app era `1.0.0`; agora é `0.2.0`.
- No card da vitrine, a moldura redonda deixava as pontas do logo (quadrado arredondado) para fora; agora ela tem o mesmo formato do logo.

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
| 0.2.0 | Operação do restaurante, associações e personalização | Lançada |
| 0.3.0 | Entregador, cooperativa e cliente | **Atual** |
| 0.4.0 | Segurança e integridade dos dados | Em andamento |
| 0.5.0 | Auditoria de dados | Planejada |
| 0.6.0 | Operação do dia a dia | Planejada |
| 1.0.0 | Primeira versão estável (piloto real) | Planejada |

### 0.3.0: Entregador, cooperativa e cliente
- ~~Concluir as telas do entregador~~: avaliações, rastreio no mapa e diferença assumida no Caixa (concluído).
- ~~Painel da cooperativa: parcerias com lojas, acordos e relatórios para os cooperados~~: parcerias com aceite, tabela especial por loja e relatórios para o gestor e para cada cooperado (concluído).
- ~~Gestão da associação~~: mensalidade (fixa ou percentual com teto), seguro e outros adicionais, faturas com baixa manual, caixinha solidária, painel financeiro, convênios, enquetes, atas e exportação dos associados (concluído).
- ~~Taxa repassada ao cliente~~: "a partir de" na vitrine, valor por distância no checkout e contraproposta na tabela entre loja e associação (concluído).
- ~~Fluxo do cliente fora da fase de testes, com coleta de avaliações~~: jornada revisada de ponta a ponta no desktop e no celular, com cadastro no meio da compra (concluído).
- ~~Visibilidade: página da loja otimizada para buscadores (SEO) e vitrine ordenada por avaliações e proximidade, sem posição paga~~ (concluído).

### 0.4.0: Segurança e integridade dos dados
O detalhe de cada item, com o estado atual no código e o que falta, está em [docs/roadmap/0.4.0-seguranca.md](docs/roadmap/0.4.0-seguranca.md). A ordem é "críticos primeiro": brechas graves, migrações versionadas, race conditions, idempotência, rate limiting, throttling e revisão de segurança.
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

### 0.6.0: Operação do dia a dia
O detalhe de cada item, com o código em que ele se apoia e o que falta, está em [docs/roadmap/0.6.0-operacao.md](docs/roadmap/0.6.0-operacao.md).
- Pedido feito no balcão ou por telefone, que entra no mesmo fluxo dos pedidos online.
- Ocorrências ligadas ao pedido: pedido não pronto, cliente não localizado, endereço incorreto e outras.
- "Cheguei na loja" e "Cheguei no cliente", tempos de cada pedido e espera média por loja no relatório da cooperativa.
- Km, tempo em operação e médias (R$ por km e R$ por hora) na aba Ganhos do entregador.
- Custo estimado do veículo (combustível, manutenção e depreciação) e resultado estimado.
- Comunicados da cooperativa para os cooperados.
- Composição do valor na oferta e lembrete de pausa.
- PIN de entrega, que a loja pode exigir.

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
