# 🛠️ OpenBag - Documentação para Desenvolvedores

Documentação técnica completa para desenvolvedores que desejam contribuir com o projeto OpenBag.

> Versão da documentação: **0.4.0**, atualizada em 2026-09-29. Veja o [CHANGELOG](CHANGELOG.md) e a [arquitetura](docs/architecture/README.md).

## 📋 Índice

- [Pré-requisitos](#-pré-requisitos)
- [Configuração do Ambiente](#-configuração-do-ambiente)
- [Estrutura do Projeto](#-estrutura-do-projeto)
- [Backend (Java Spring Boot)](#-backend-java-spring-boot)
- [Frontend (Flutter)](#-frontend-flutter)
- [Banco de Dados](#-banco-de-dados)
- [Docker & Docker Compose](#-docker--docker-compose)
- [Variáveis de Ambiente](#-variáveis-de-ambiente)
- [API Documentation](#-api-documentation)
- [Workflow de Desenvolvimento](#-workflow-de-desenvolvimento)
- [Testes](#-testes)
- [Troubleshooting](#-troubleshooting)

---

## 🔧 Pré-requisitos

### Obrigatórios

- **Java Development Kit (JDK) 25+**
  ```bash
  # Verificar versão instalada
  java -version
  
  # Instalar no Ubuntu/Debian
  sudo apt install openjdk-25-jdk
  
  # Instalar no macOS (via Homebrew)
  brew install openjdk@25
  ```

  Se você só tiver o JDK 21, dá para compilar e rodar localmente com `-Djava.version=21` (por exemplo, `mvn spring-boot:run -Djava.version=21`).

- **Apache Maven 3.6+**
  ```bash
  # Verificar versão instalada
  mvn -version
  
  # Instalar no Ubuntu/Debian
  sudo apt install maven
  
  # Instalar no macOS
  brew install maven
  ```

- **Flutter SDK 3.16+**
  ```bash
  # Verificar versão instalada
  flutter --version
  
  # Instalar: https://docs.flutter.dev/get-started/install
  ```

- **Docker & Docker Compose**
  ```bash
  # Verificar versão instalada
  docker --version
  docker compose version
  
  # Instalar: https://docs.docker.com/get-docker/
  ```

### Opcionais (para desenvolvimento local sem Docker)

- **PostgreSQL 15+** com a extensão **PostGIS 3** (ex.: pacote `postgresql-15-postgis-3`)
- **Redis 7+**
- **Elasticsearch 8.11+**

---

## 🚀 Configuração do Ambiente

### Opção 1: Usando Docker (Recomendado)

A maneira mais rápida de rodar o projeto completo com todos os serviços:

```bash
# 1. Clonar o repositório
git clone https://github.com/LucasRamos-Developer/openbag.git
cd openbag

# 2. Senhas do Postgres e do Redis (opcional em desenvolvimento: sem o .env valem as de dev)
cp .env.example .env

# 3. Subir todos os serviços (PostgreSQL, Redis, Elasticsearch, Kibana)
docker compose up -d

# 4. Rodar o backend localmente (conectando aos serviços Docker)
cd backend
mvn spring-boot:run -Dspring-boot.run.profiles=docker

# 5. Rodar o frontend (em outro terminal)
cd frontend
flutter pub get
flutter run -d chrome  # Para web
# ou
flutter run            # Para mobile (requer emulador/device)
```

**Portas utilizadas** (os serviços do Docker só aparecem em `127.0.0.1`, não na rede local):
- `8080` - Backend API
- `5432` - PostgreSQL
- `6379` - Redis (com senha)
- `9200` - Elasticsearch (ainda sem uso no código)
- `5601` - Kibana

### Opção 2: Backend no Docker (Full Stack)

Para rodar o backend também no Docker (útil para testar o Dockerfile):

```bash
# Subir todos os serviços incluindo o backend
docker compose --profile backend up -d

# Ver logs do backend
docker logs -f open-bag-app
```

### Opção 3: Desenvolvimento Local (sem Docker)

Para desenvolvimento sem Docker, você precisa instalar PostgreSQL (com PostGIS), Redis e Elasticsearch localmente. Sem o PostGIS, o backend não sobe: a primeira migração roda `CREATE EXTENSION IF NOT EXISTS postgis`.

```bash
# 1. Criar banco de dados PostgreSQL
createdb openbag

# 2. Configurar variáveis de ambiente
export SPRING_PROFILES_ACTIVE=local
export SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5432/openbag
export SPRING_DATASOURCE_USERNAME=seu_usuario
export SPRING_DATASOURCE_PASSWORD=sua_senha

# 3. Rodar backend
cd backend
mvn spring-boot:run

# 4. Rodar frontend
cd frontend
flutter run -d chrome
```

---

## 📁 Estrutura do Projeto

### Backend (`/backend`)

O backend é organizado **por módulo de domínio**. Cada módulo tem `controller`, `dto`, `entity`, `repository` e `service`. Os detalhes estão na [documentação de arquitetura](docs/architecture/README.md).

```
backend/
├── src/
│   ├── main/
│   │   ├── java/com/openbag/
│   │   │   ├── platform/           # Infraestrutura: config, security, web, realtime, files, geo, util, seed
│   │   │   ├── account/            # Cadastro, login, perfil
│   │   │   ├── restaurant/         # store, catalog, menu, combo, cash
│   │   │   ├── order/              # core (pedidos do app e do balcão), realtime (WebSocket), review, incident
│   │   │   ├── delivery/           # courier, dispatch, route, link
│   │   │   ├── association/        # core, finance, community, member, partnership
│   │   │   └── admin/              # Painel da plataforma
│   │   └── resources/
│   │       ├── application.properties           # Config padrão (desenvolvimento)
│   │       ├── application-local.properties     # Config local (com SQL e DEBUG no log)
│   │       ├── application-docker.properties    # Config Docker
│   │       ├── application-prod.properties      # Produção: segredos obrigatórios por variável
│   │       └── db/migration/                    # Migrações do Flyway (V1, V2...)
│   └── test/                       # Unitários e de integração (Testcontainers)
├── docs/                           # Documentação de APIs
├── Dockerfile
└── pom.xml                         # Versão do backend (ver CHANGELOG)
```

### Frontend (`/frontend`)

```
frontend/
├── lib/
│   ├── main.dart                   # Rotas (GoRouter) e providers
│   ├── constants/                  # Constantes (URLs, chaves, etc)
│   ├── core/ui/                    # Design system: componentes App*, temas e tokens
│   ├── models/                     # Modelos por domínio (order, menu, delivery, routes, cash...)
│   ├── screens/
│   │   ├── home/, restaurant/      # Vitrine e página da loja (cliente)
│   │   ├── cart/, checkout/, orders/
│   │   ├── restaurant_panel/       # Painel do restaurante (/restaurante)
│   │   ├── kitchen/                # Tela da cozinha
│   │   ├── courier/                # Painel do entregador (/entregador)
│   │   ├── association/            # Painel da associação (/associacao)
│   │   ├── admin/                  # Painel do super admin (/admin, somente leitura)
│   │   ├── auth/, onboarding/, profile/
│   ├── services/                   # Chamadas à API e ao WebSocket
│   ├── widgets/                    # Widgets reutilizáveis por domínio
│   └── utils/                      # Formatadores, mapas, localização
├── assets/                         # Imagens e fontes (Plus Jakarta Sans)
├── web/                            # Arquivos da versão web
└── pubspec.yaml                    # Versão do app (ver CHANGELOG)
```

Tudo que se repete vira componente em `core/ui` ou em `widgets/<domínio>`. Veja o [README do design system](frontend/lib/core/ui/README.md).

### Documentação (`/docs`)

```
docs/
├── index.html                      # Site (GitHub Pages)
├── assets/screens/                 # Telas usadas no site
├── architecture/README.md          # Arquitetura do sistema
├── api/README.md                   # Índice de APIs
└── guides/openstreetmap.md         # OpenStreetMap
```

As capturas de tela de referência ficam em [`layout/`](layout/) e o histórico de versões em [`CHANGELOG.md`](CHANGELOG.md).

---

## ☕ Backend (Java Spring Boot)

### Tecnologias

- **Spring Boot 3.5** (Java 25)
- **Spring Security** + JWT Authentication
- **Spring Data JPA** (Hibernate) e **Flyway** (migrações)
- **PostgreSQL** com **PostGIS**
- **WebSocket + STOMP** (pedidos e ofertas em tempo real)
- **Redis** + **Bucket4j** (limite de requisições) e **ShedLock** (jobs em uma instância só)
- **Elasticsearch** (no Docker Compose; ainda sem uso no código)
- **SpringDoc OpenAPI** (API Documentation)
- **Testcontainers** (testes de integração com Postgres + PostGIS e Redis)

### Build & Run

```bash
cd backend

# Compilar
mvn clean compile

# Rodar testes
mvn test

# Criar package (.jar)
mvn clean package

# Rodar aplicação (profile local)
mvn spring-boot:run

# Rodar com profile específico
mvn spring-boot:run -Dspring-boot.run.profiles=docker

# Rodar JAR diretamente
java -jar target/openbag-backend-0.4.0.jar
```

### Conta de demonstração

Para testar tudo com um login só, suba o backend com a conta demo:

```bash
OPENBAG_DEMO_ENABLED=true mvn spring-boot:run
```

Na subida é criada a conta **`demo@openbag.local` / `demo1234`**, que tem todos os perfis: cliente, restaurante, entregador, cooperativa e super admin. Junto com ela vêm:

- a loja **Cantina Demo** (`/r/cantina-demo`), aberta, com horários, endereço em Blumenau e cardápio;
- a **Cooperativa Demo**, já aprovada e com a tabela de entrega;
- o perfil de entregador com uma moto ativa e o vínculo com a cooperativa.

A criação é idempotente: cada parte só é criada se ainda não existir. A senha é pública, então **nunca ligue `OPENBAG_DEMO_ENABLED` em produção** (o padrão é `false`).

O ADMIN inicial de produção é outro: ele vem de `OPENBAG_ADMIN_EMAIL` e `OPENBAG_ADMIN_PASSWORD`.

### Roteamento (rotas pelas ruas)

O caminho das rotas no mapa vem de um servidor [OSRM](https://project-osrm.org). O backend consulta esse servidor e salva o caminho na própria rota (`delivery_routes.street_path`, PostGIS), junto com as paradas usadas no cálculo (`street_path_key`). Enquanto as paradas não mudam, o painel usa o caminho salvo, sem consultar o OSRM de novo. O caminho de um pedido sozinho fica só em memória. Se o OSRM não responder, o mapa desenha linha reta.

| Variável | Padrão | Uso |
|---|---|---|
| `OPENBAG_OSRM_URL` | `https://router.project-osrm.org` | Servidor OSRM |
| `OPENBAG_ROUTING_ENABLED` | `true` | `false` desliga o roteamento (só linhas retas) |

O servidor padrão é a demonstração pública do OSRM: aceita no máximo 1 consulta por segundo e não é para produção. Em produção, suba um OSRM próprio com o recorte do OSM da região (ex: sul do Brasil, do [Geofabrik](https://download.geofabrik.de/south-america/brazil.html)) e aponte `OPENBAG_OSRM_URL` para ele.

### Localização dos endereços de entrega

Quando a loja repassa a taxa ao cliente, o valor depende da distância até o endereço. O backend localiza o endereço digitado com a busca estruturada do [Nominatim](https://nominatim.org) (OpenStreetMap), guarda as respostas em memória e respeita o limite de 1 consulta por segundo do servidor público. Sem resposta, vale o valor "a partir de" (e o entregador recebe esse valor inteiro).

| Variável | Padrão | Uso |
|---|---|---|
| `OPENBAG_GEOCODING_URL` | `https://nominatim.openstreetmap.org` | Servidor Nominatim |
| `OPENBAG_GEOCODING_ENABLED` | `true` | `false` desliga a localização (a taxa por distância fica no "a partir de") |

Em produção, use um Nominatim próprio ou um serviço contratado.

### Profiles disponíveis

| Profile | Descrição | Uso |
|---------|-----------|-----|
| `local` | Desenvolvimento local (localhost) | Banco local, Redis local |
| `docker` | Conecta aos serviços Docker | Banco/Redis no Docker, app local |
| `prod` | Produção | Exige os segredos por variável de ambiente, sem SQL no log e sem Swagger |

### Estrutura de Pacotes

- **`controller`** - REST endpoints (ex: `AuthController`, `RestaurantController`)
- **`service`** - Lógica de negócio
- **`repository`** - Acesso ao banco de dados (Spring Data JPA)
- **`entity`** - Entidades JPA (mapeadas para tabelas)
- **`dto`** - Objetos de transferência de dados (request/response)
- **`config`** - Configurações (Security, CORS, Redis, etc)
- **`security`** - JWT, autenticação, autorização
- **`exception`** - Tratamento de exceções customizadas

---

## 📱 Frontend (Flutter)

### Tecnologias

- **Flutter 3.16+** (Dart)
- **Provider** (State management)
- **GoRouter** (Navigation)
- **Dio** (HTTP client)
- **flutter_map** (OpenStreetMap integration)
- **stomp_dart_client** (tempo real)
- **printing/pdf** (comanda de 80 mm)
- **SharedPreferences** (Local storage)

### Build & Run

```bash
cd frontend

# Instalar dependências
flutter pub get

# Rodar em modo debug (web)
flutter run -d chrome

# Rodar em modo debug (Android)
flutter run -d android

# Rodar em modo debug (iOS - requer macOS)
flutter run -d ios

# Build para produção (web)
flutter build web

# Build para produção (Android APK)
flutter build apk

# Build para produção (iOS - requer macOS)
flutter build ios
```

### Configuração de API URL

O endereço da API é definido no build, sem editar código. O padrão é `http://localhost:8080/api`:

```bash
flutter run -d chrome --dart-define=API_URL=http://localhost:8090/api
flutter build web --dart-define=API_URL=https://api.seu-dominio.com/api
```

### Estrutura de State Management

O projeto usa **Provider** para gerenciamento de estado:

```dart
// Exemplo de uso
class CartService extends ChangeNotifier {
  List<CartItem> _items = [];
  
  void addItem(Product product) {
    _items.add(CartItem(product: product));
    notifyListeners();  // Notifica widgets
  }
}

// No widget
Consumer<CartService>(
  builder: (context, cart, child) {
    return Text('Items: ${cart.items.length}');
  },
)
```

### Web-Specific Considerations

- OpenStreetMap funciona perfeitamente na web (não depende de Google Maps)
- Image picker requer `image_picker_for_web`
- Geolocation funciona com `geolocator_web`

### Buscadores (SEO) e prévia de links

O app continua Flutter web: o backend não gera HTML. O SEO vem de três partes:

1. **`web/index.html`**: idioma, título, descrição, Open Graph e um texto em `<noscript>`. É o que os robôs sem JavaScript leem, inclusive a prévia do WhatsApp e do Facebook, que por isso mostra a prévia padrão do OpenBag e não a de cada loja.
2. **Por página**: a vitrine e a página da loja trocam o título, a descrição e o canônico com o widget `PageMeta` (`lib/widgets/seo/`). A loja também publica os dados estruturados do schema.org (`Restaurant`, com endereço, horários, nota e o cardápio), montados em `lib/widgets/restaurant/restaurant_seo.dart`. O Google executa o JavaScript e lê essas tags.
3. **No deploy**, depois do `flutter build web`:

   ```bash
   python3 tools/seo/build_seo.py --site-url https://seu-dominio --api https://sua-api/api
   ```

   O script gera o `robots.txt` (bloqueia painéis, checkout e pedidos) e o `sitemap.xml` com a vitrine e as lojas ativas, e troca os endereços relativos do `index.html` pelos absolutos. Rode de novo quando entrar loja nova, ou agende.

A árvore de acessibilidade do Flutter fica desligada por padrão. Ligada, ela colocaria no HTML o texto da parte visível da página, mas custou de 5% a 10% a mais de CPU ao rolar a loja, e o cardápio inteiro já vai no JSON-LD.

Os ícones do app (`web/favicon.png` e `web/icons/`) são gerados por `tools/brand/generate_web_icons.py`, com a sacola do logo.

---

## 🗄️ Banco de Dados

### PostgreSQL

O projeto usa **PostgreSQL 15** com **PostGIS 3** como banco de dados principal (imagem montada por `database/Dockerfile`: a `postgres:15` oficial com o pacote `postgresql-15-postgis-3`, na mesma base Debian, para não mudar a collation dos volumes já criados). O PostGIS guarda o caminho pelas ruas das rotas.

A primeira migração cria a extensão, então vale também para um volume antigo, criado com a imagem `postgres:15`.

#### Schema e migrações (Flyway)

O esquema vem das migrações em `backend/src/main/resources/db/migration`, aplicadas pelo Flyway na subida. O Hibernate não cria nem altera nada: com `spring.jpa.hibernate.ddl-auto=validate`, ele só confere se as entidades batem com o banco e impede a subida se faltar uma tabela ou uma coluna.

- `V1__esquema_inicial.sql`: o esquema da 0.3.0, gerado pelo Hibernate, com os mesmos nomes de chaves, únicos e checks que o antigo `ddl-auto=update` criava.
- `V2__preenche_colunas_legadas.sql`: dados que antes eram preenchidos na subida.

**Mudou uma entidade? Crie uma migração.** O nome segue `V<número>__<descrição>.sql` (por exemplo, `V3__pedido_com_versao.sql`), e uma migração já aplicada nunca é editada. Isso inclui valores novos em enums: o Hibernate cria um `CHECK` para cada coluna `@Enumerated(STRING)`, e a migração precisa recriá-lo:

```sql
ALTER TABLE orders DROP CONSTRAINT orders_status_check;
ALTER TABLE orders ADD CONSTRAINT orders_status_check
    CHECK (status IN ('PENDING', 'CONFIRMED', ..., 'NOVO_VALOR'));
```

O teste `FlywayMigrationTest` sobe o backend contra um Postgres + PostGIS de verdade (Testcontainers) e falha se as migrações não baterem com as entidades.

**Banco criado antes do Flyway.** Um banco que já existia entra com *baseline* na V1 (`spring.flyway.baseline-on-migrate`) e segue da V2. Se ele estava atrás do código (o backend não sobe e acusa `Schema-validation: missing column`), suba **uma vez** com `--spring.jpa.hibernate.ddl-auto=update` para completar as colunas e volte ao normal. Se preferir começar do zero, apague o volume do Postgres (os dados se perdem) e a conta de demonstração é recriada com `OPENBAG_DEMO_ENABLED=true`.

```bash
# Para recriar o banco do zero:
docker compose down -v  # Remove volumes (APAGA DADOS)
docker compose up -d
```

#### Acessar banco via CLI

```bash
# Se rodando no Docker
docker exec -it open-bag-postgres psql -U openbag -d openbag

# Comandos úteis
\dt          # Listar tabelas
\d users     # Descrever tabela users
SELECT * FROM restaurants LIMIT 10;
```

#### Credenciais (Docker)

- **Database**: `openbag`
- **User**: `openbag`
- **Password**: `OPENBAG_DB_PASSWORD` do arquivo `.env` (copie o `.env.example`). Sem o `.env`, vale a senha de desenvolvimento, `openbag123`.
- **Port**: `5432`, só em `127.0.0.1`

### Redis

Guarda os contadores do limite de requisições (veja [Limite de requisições](#limite-de-requisições-rate-limiting)). A senha é `OPENBAG_REDIS_PASSWORD` do `.env`, e o padrão de desenvolvimento é `openbag-redis`. O backend lê a mesma variável. Sem Redis, o backend funciona normalmente: cada instância conta sozinha.

```bash
# Acessar Redis CLI (a senha é OPENBAG_REDIS_PASSWORD; o padrão de dev é openbag-redis)
docker exec -it open-bag-redis redis-cli -a openbag-redis

# Contadores do limite de requisições (somem sozinhos quando o limite se refaz)
KEYS rl:*
DEL "rl:login-ip:127.0.0.1"   # Liberar um IP bloqueado em desenvolvimento
```

Um Redis criado antes da senha continua sem ela até ser recriado: `docker compose up -d redis`. Enquanto isso, o backend avisa no log e conta os limites na memória.

### Elasticsearch

Previsto para a busca de restaurantes e produtos. Ainda não é usado pelo código.

```bash
# Acessar Elasticsearch
curl http://localhost:9200

# Listar índices
curl http://localhost:9200/_cat/indices?v

# Buscar no índice de restaurantes
curl http://localhost:9200/restaurants/_search?pretty
```

**Kibana** (visualização): http://localhost:5601

---

## 🐳 Docker & Docker Compose

### Arquitetura de Serviços

O `docker-compose.yml` define 5 serviços:

1. **postgres** - PostgreSQL 15
2. **redis** - Redis 7 (contadores do limite de requisições)
3. **elasticsearch** - Elasticsearch 8.11
4. **kibana** - Kibana 8.11 (dashboard)
5. **app** - Spring Boot API (profile `backend` apenas)

### Comandos Úteis

```bash
# Subir serviços (PostgreSQL, Redis, Elasticsearch, Kibana)
docker compose up -d

# Subir INCLUINDO backend
docker compose --profile backend up -d

# Ver logs de um serviço
docker logs -f open-bag-postgres
docker logs -f open-bag-app

# Parar serviços
docker compose down

# Parar e remover volumes (APAGA DADOS!)
docker compose down -v

# Rebuild de imagens
docker compose build --no-cache

# Entrar em um container
docker exec -it open-bag-postgres bash
docker exec -it open-bag-app bash

# Ver status dos serviços
docker compose ps

# Ver uso de recursos
docker stats
```

### Volumes Persistentes

Os dados são persistidos em volumes Docker:

- `postgres_data` - Dados do PostgreSQL
- `redis_data` - Dados do Redis
- `elasticsearch_data` - Dados do Elasticsearch

### Networks

Todos os serviços estão na mesma rede (`open-bag-network`) e podem se comunicar pelos nomes dos serviços.

---

## 🔐 Variáveis de Ambiente

### Backend

#### Desenvolvimento (perfil padrão, `local` e `docker`)

Os três perfis de desenvolvimento têm valores padrão para tudo e sobem sem nenhuma variável. As mais úteis:

| Variável | Padrão | Uso |
|---|---|---|
| `OPENBAG_DB_PASSWORD` | `openbag123` | Senha do Postgres (a mesma do `.env` do docker-compose) |
| `OPENBAG_REDIS_PASSWORD` | `openbag-redis` | Senha do Redis |
| `OPENBAG_DEMO_ENABLED` | `false` | Conta de demonstração com todos os perfis |
| `OPENBAG_CORS_ORIGINS` | qualquer porta de `localhost` e `127.0.0.1` | Origens do app web |
| `OPENBAG_GEOCODING_ENABLED` e `OPENBAG_ROUTING_ENABLED` | `true` | Desligam o Nominatim e o OSRM (útil sem internet) |

O perfil `docker` aponta para os nomes dos serviços do compose (`postgres`, `redis`). O `local` liga o SQL e o DEBUG no log. Os segredos de desenvolvimento (JWT e senha do ADMIN) são públicos: o backend avisa no log e se recusa a usá-los no perfil `prod`.

#### Produção (perfil `prod`)

Em produção, rode com o perfil `prod` (é o padrão da imagem do `backend/Dockerfile`). Ele não tem valores padrão para segredos: sem as variáveis abaixo, o backend não sobe. O `SecretsValidator` também recusa um segredo do JWT curto ou de desenvolvimento, a senha `admin123`, uma senha de ADMIN com menos de 12 caracteres e a conta de demonstração ligada. Nos outros perfis, ele só avisa no log.

```bash
export SPRING_PROFILES_ACTIVE=prod
export SPRING_DATASOURCE_URL=jdbc:postgresql://host:5432/openbag
export SPRING_DATASOURCE_USERNAME=openbag
export SPRING_DATASOURCE_PASSWORD=senha_segura
export OPENBAG_JWT_SECRET="$(openssl rand -base64 48)"   # pelo menos 32 bytes
export OPENBAG_CORS_ORIGINS=https://seu-dominio.com      # origens do app web, separadas por vírgula
export OPENBAG_ADMIN_EMAIL=admin@seu-dominio.com         # ADMIN inicial (só se não houver nenhum)
export OPENBAG_ADMIN_PASSWORD=senha_forte_com_12_ou_mais # vazia: nenhum ADMIN é criado
# OPENBAG_DEMO_ENABLED não pode ser ligado em produção (conta demo com senha pública)
```

Em desenvolvimento, o CORS e o WebSocket aceitam qualquer porta de `localhost` e `127.0.0.1`. Para outras origens, use `OPENBAG_CORS_ORIGINS`.

#### Limite de requisições (rate limiting)

As rotas mais visadas respondem **429** com `Retry-After` quando passam do limite (`RateLimitFilter`). Os contadores ficam no Redis e valem para todas as instâncias. Sem Redis (é comum em desenvolvimento), cada instância conta sozinha e o log avisa.

| Limite | Padrão | Conta por |
|---|---|---|
| `login-ip` e `login-ip-hourly` | 10 por minuto e 50 por hora | IP |
| `login-email` | 10 a cada 15 minutos | email (protege a conta de vários IPs) |
| `register-ip` | 10 por hora | IP (todos os cadastros públicos) |
| `check-email-ip` | 20 por minuto | IP |
| `public-quote-ip` | 30 por minuto | IP (cotação da página da loja) |
| `order-user` | 10 por minuto | usuário (`POST /orders`) |
| `store-order-user` | 30 por minuto | usuário (pedido do balcão) |
| `quote-user` | 30 por minuto | usuário (cotação no checkout) |
| `upload-user` | 30 por hora | usuário (qualquer envio de arquivo) |

Para trocar um limite, use `app.rate-limit.limits.<nome>=<quantidade>/<período>` (por exemplo, `app.rate-limit.limits.login-ip=20/1m`). Para desligar tudo, use `app.rate-limit.enabled=false`. Atrás de um proxy reverso confiável, defina `OPENBAG_FORWARD_HEADERS_STRATEGY=native` para o limite ver o IP real do cliente.

### Frontend

Edite `lib/constants/app_constants.dart`:

```dart
class AppConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8080/api'
  );
}
```

Build com variável customizada:

```bash
flutter build web --dart-define=API_URL=https://api.openbag.com/api
```

#### Mapa

Os mapas usam o componente `AppMap` (`frontend/lib/core/ui/components/app_map.dart`), desenhado pelo MapLibre (`maplibre_gl`) na web, no Android e no iOS.

- **Estilo:** é nosso e fica em `frontend/assets/map/openbag_style.json`, no formato de estilo do MapLibre. Para mudar cores ou o que aparece (ruas, parques, rótulos), edite o JSON. O [Maputnik](https://maplibre.org/maputnik/) é um editor visual que abre esse arquivo.
- **Dados e fontes:** vêm do [OpenFreeMap](https://openfreemap.org), sem chave e sem limite de uso. O crédito (OpenFreeMap, OpenMapTiles e OpenStreetMap) aparece no botão de atribuição do mapa.
- **Base raster no lugar do estilo** (ex: MapTiler com chave):

  ```bash
  flutter build web \
    --dart-define=MAP_TILE_URL='https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=SUA_CHAVE' \
    --dart-define=MAP_TILE_ATTRIBUTION='© MapTiler © OpenStreetMap'
  ```

---

## 📚 API Documentation

### Swagger/OpenAPI

A documentação interativa da API está disponível em:

**http://localhost:8080/api/swagger-ui.html** (todas as rotas ficam sob o prefixo `/api`)

### Rotas por módulo

A tabela com as rotas base de cada módulo e os tópicos do WebSocket (`/api/ws`) está na [documentação de arquitetura](docs/architecture/README.md#módulos-e-rotas-principais). O Swagger é a lista sempre atualizada.

### Documentação Detalhada

- [API - Índice](docs/api/README.md)
- [API - Onboarding de Restaurante](backend/docs/onboarding-restaurante.md)

---

## 🔄 Workflow de Desenvolvimento

### Git Flow

1. **Clone o repositório**

```bash
git clone https://github.com/LucasRamos-Developer/openbag.git
cd openbag
```

2. **Crie uma branch para sua feature**

```bash
git checkout -b feature/nome-da-feature
```

3. **Faça commits atômicos**

```bash
git add .
git commit -m "feat: adiciona endpoint de busca de restaurantes"
```

#### Convenção de Commits

Usamos [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` Nova funcionalidade
- `fix:` Correção de bug
- `docs:` Documentação
- `style:` Formatação (sem mudança de lógica)
- `refactor:` Refatoração de código
- `test:` Testes
- `chore:` Tarefas de build, configs, etc

4. **Push e crie Pull Request**

```bash
git push origin feature/nome-da-feature
```

Abra um Pull Request no GitHub com descrição detalhada.

### Code Review

- O CI (`.github/workflows/ci.yml`) roda os testes do backend e do app, e precisa passar.
- Mudança de entidade vem com a migração do Flyway, e mudança de comportamento vem com teste.

### Padrões de Código

#### Java

- **Estilo**: Google Java Style Guide
- **Formatter**: IntelliJ/Eclipse default (não há checkstyle configurado no Maven)

#### Dart/Flutter

- **Estilo**: Dart Style Guide oficial
- **Formatter**: `dart format`

```bash
# Formatar código
dart format lib/

# Analisar código
flutter analyze
```

---

## 🧪 Testes

### Backend (JUnit 5 + Mockito)

```bash
cd backend

# Rodar todos os testes (os de integração precisam do Docker; sem ele, são pulados)
mvn test

# Um teste só
mvn test -Dtest=ConcurrentActionsTest

# Dependências com vulnerabilidades conhecidas (precisa de NVD_API_KEY; roda toda semana no CI)
mvn -Psecurity verify -DskipTests
```

**Chave do NVD para o Dependency-Check.** Sem ela, a verificação semanal (`.github/workflows/security.yml`) não roda. Para configurar uma vez:

1. Peça a chave gratuita em https://nvd.nist.gov/developers/request-an-api-key e confirme pelo link que chega no email.
2. No GitHub, abra o repositório em **Settings → Secrets and variables → Actions → New repository secret**, com o nome `NVD_API_KEY` e a chave como valor. Pelo terminal: `gh secret set NVD_API_KEY`.
3. Rode o workflow uma vez na mão, em **Actions → Dependências vulneráveis → Run workflow**, e confira se o artefato `dependency-check-report` aparece.

Para rodar localmente, exporte a chave antes do comando: `NVD_API_KEY=... mvn -Psecurity verify -DskipTests`. A primeira execução baixa a base inteira e demora.

#### Estrutura de Testes

- A maioria é de unidade, com JUnit 5 e Mockito, ao lado do pacote testado (`<domínio>/<funcionalidade>/service/...Test`).
- Os testes de integração estendem `support/IntegrationTest`: sobem o backend inteiro contra um Postgres + PostGIS em container (Testcontainers, com a imagem de `database/Dockerfile`), com o esquema criado pelas migrações e a conta de demonstração ligada. A primeira execução constrói a imagem e demora cerca de um minuto.
- Os casos de ações simultâneas ficam em `concurrency/ConcurrentActionsTest`: duas threads disputando o mesmo pedido, a mesma fatura ou a mesma caixinha.
- Os jobs agendados ficam desligados nos testes (`application-test.properties`). Um teste que precisa de um job chama o método direto.

### Frontend (Flutter Test)

```bash
cd frontend

# Rodar todos os testes
flutter test

# Rodar com coverage
flutter test --coverage

# Ver coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 🐛 Troubleshooting

### Problemas Comuns

#### 1. Backend não conecta ao PostgreSQL

**Erro**: `Connection refused` ou `Could not connect to database`

**Solução**:
```bash
# Verificar se PostgreSQL está rodando
docker ps | grep postgres

# Verificar logs
docker logs open-bag-postgres

# Recriar container
docker compose down
docker compose up -d postgres
```

#### 2. Porta 8080 já está em uso

**Erro**: `Port 8080 is already in use`

**Solução**:
```bash
# Descobrir processo usando a porta
lsof -i :8080

# Matar processo (substitua PID)
kill -9 <PID>

# Ou usar outra porta
mvn spring-boot:run -Dserver.port=8081
```

#### 3. Flutter não encontra dispositivos

**Erro**: `No devices found`

**Solução**:
```bash
# Web: habilitar Chrome
flutter config --enable-web

# Android: verificar emulador
flutter emulators
flutter emulators --launch <emulator-id>

# iOS: abrir Xcode Simulator (macOS only)
open -a Simulator
```

#### 4. Erro de CORS no frontend

**Erro**: `CORS policy: No 'Access-Control-Allow-Origin' header`

**Solução**: o CORS e o WebSocket aceitam as origens de `app.cors.allowed-origins`. Em desenvolvimento, isso vale para qualquer porta de `localhost` e `127.0.0.1`. Se o app roda em outro endereço (um IP da rede, por exemplo), passe a origem:

```bash
OPENBAG_CORS_ORIGINS=http://192.168.0.10:[*] mvn spring-boot:run
```

#### 5. Erro de restrição ao salvar um valor novo de enum

**Erro**: `violates check constraint "..._check"`

**Causa**: o valor novo do enum não está no `CHECK` da coluna.

**Solução**: crie uma migração que recria o `CHECK` com o valor novo (veja [Schema e migrações](#schema-e-migrações-flyway)). Não altere o banco à mão: os outros bancos (de outras pessoas, do CI e de produção) ficariam diferentes.

#### 6. O backend não sobe: `Schema-validation: missing column`

**Causa**: o banco está atrás do código (foi criado antes de uma entidade mudar, ou antes do Flyway).

**Solução**: suba uma vez com `--spring.jpa.hibernate.ddl-auto=update` e volte ao normal (veja [Schema e migrações](#schema-e-migrações-flyway)). Se a coluna é nova no código, falta a migração dela.

#### 7. Resposta 429 em desenvolvimento

**Causa**: o limite de requisições (por exemplo, 10 logins por minuto do mesmo IP).

**Solução**: espere o tempo do `Retry-After`, apague o contador no Redis (`DEL "rl:login-ip:127.0.0.1"`) ou suba com `--app.rate-limit.enabled=false`.

#### 8. Redis connection timeout

**Solução**:
```bash
# Verificar se Redis está rodando
docker compose ps redis

# Testar conexão
docker exec -it open-bag-redis redis-cli ping
# Deve retornar: PONG

# Reiniciar Redis
docker compose restart redis
```

---

## 📖 Recursos Adicionais

### Documentação Oficial

- [Spring Boot Documentation](https://docs.spring.io/spring-boot/docs/current/reference/html/)
- [Flutter Documentation](https://docs.flutter.dev/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Docker Documentation](https://docs.docker.com/)

### Guias Internos

- [Arquitetura](docs/architecture/README.md)
- [OpenStreetMap Integration](docs/guides/openstreetmap.md)
- [API - Onboarding de Restaurante](backend/docs/onboarding-restaurante.md)
- [CHANGELOG e versionamento](CHANGELOG.md)

### Ferramentas Recomendadas

- **IDE Backend**: IntelliJ IDEA, Eclipse, VS Code
- **IDE Frontend**: VS Code, Android Studio
- **Database Client**: DBeaver, pgAdmin
- **API Testing**: Postman, Insomnia, cURL
- **Git Client**: GitKraken, SourceTree, CLI

---

## 🤝 Precisa de Ajuda?

- Consulte o [README principal](README.md) para visão geral do projeto
- Veja [CONTRIBUTING.md](CONTRIBUTING.md) para guidelines de contribuição
- Abra uma [Issue](https://github.com/LucasRamos-Developer/openbag/issues) para reportar bugs
- Entre em contato: [lucasramos.developer@gmail.com](mailto:lucasramos.developer@gmail.com)

---

**Desenvolvido com ❤️ pela comunidade OpenBag**
