# 🛠️ OpenBag - Documentação para Desenvolvedores

Documentação técnica completa para desenvolvedores que desejam contribuir com o projeto OpenBag.

## 📋 Índice

- [Pré-requisitos](#pré-requisitos)
- [Configuração do Ambiente](#configuração-do-ambiente)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Backend (Java Spring Boot)](#backend-java-spring-boot)
- [Frontend (Flutter)](#frontend-flutter)
- [Banco de Dados](#banco-de-dados)
- [Docker & Docker Compose](#docker--docker-compose)
- [Variáveis de Ambiente](#variáveis-de-ambiente)
- [API Documentation](#api-documentation)
- [Workflow de Desenvolvimento](#workflow-de-desenvolvimento)
- [Testes](#testes)
- [Troubleshooting](#troubleshooting)

---

## 🔧 Pré-requisitos

### Obrigatórios

- **Java Development Kit (JDK) 21+**
  ```bash
  # Verificar versão instalada
  java -version
  
  # Instalar no Ubuntu/Debian
  sudo apt install openjdk-21-jdk
  
  # Instalar no macOS (via Homebrew)
  brew install openjdk@21
  ```

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

- **PostgreSQL 15+**
- **Redis 7+**
- **Elasticsearch 8.11+**

---

## 🚀 Configuração do Ambiente

### Opção 1: Usando Docker (Recomendado)

A maneira mais rápida de rodar o projeto completo com todos os serviços:

```bash
# 1. Clonar o repositório
git clone https://github.com/seu-usuario/openbag.git
cd openbag

# 2. Subir todos os serviços (PostgreSQL, Redis, Elasticsearch, Kibana)
docker compose up -d

# 3. Rodar o backend localmente (conectando aos serviços Docker)
cd backend
mvn spring-boot:run -Dspring-boot.run.profiles=docker

# 4. Rodar o frontend (em outro terminal)
cd frontend
flutter pub get
flutter run -d chrome  # Para web
# ou
flutter run            # Para mobile (requer emulador/device)
```

**Portas utilizadas:**
- `8080` - Backend API
- `5432` - PostgreSQL
- `6379` - Redis
- `9200` - Elasticsearch
- `5601` - Kibana (dashboard)

### Opção 2: Backend no Docker (Full Stack)

Para rodar o backend também no Docker (útil para testar o Dockerfile):

```bash
# Subir todos os serviços incluindo o backend
docker compose --profile backend up -d

# Ver logs do backend
docker logs -f open-bag-app
```

### Opção 3: Desenvolvimento Local (sem Docker)

Para desenvolvimento sem Docker, você precisa instalar PostgreSQL, Redis e Elasticsearch localmente.

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

```
backend/
├── src/
│   ├── main/
│   │   ├── java/com/openbag/
│   │   │   ├── annotation/         # Custom annotations (@ValidEmail, etc)
│   │   │   ├── config/             # Configurações (Security, Redis, CORS, etc)
│   │   │   ├── controller/         # REST Controllers
│   │   │   ├── dto/                # Data Transfer Objects
│   │   │   ├── entity/             # JPA Entities
│   │   │   ├── exception/          # Custom Exceptions & Handlers
│   │   │   ├── repository/         # Spring Data JPA Repositories
│   │   │   ├── security/           # JWT, UserDetails, Filters
│   │   │   ├── service/            # Business Logic
│   │   │   └── util/               # Utility classes
│   │   └── resources/
│   │       ├── application.properties           # Config padrão
│   │       ├── application-local.properties     # Config local
│   │       ├── application-docker.properties    # Config Docker
│   │       └── db/migration/                    # Flyway migrations
│   └── test/                       # Testes unitários e integração
├── docs/                           # Documentação de APIs
├── Dockerfile                      # Multi-stage build
└── pom.xml                         # Maven dependencies
```

### Frontend (`/frontend`)

```
frontend/
├── lib/
│   ├── main.dart                   # Entry point
│   ├── constants/                  # Constantes (URLs, chaves, etc)
│   ├── models/                     # Data models
│   ├── screens/                    # UI Screens
│   │   ├── auth/                   # Login, Register
│   │   ├── home/                   # Home screen
│   │   ├── restaurant/             # Restaurant details
│   │   ├── cart/                   # Shopping cart
│   │   ├── orders/                 # Order history
│   │   └── profile/                # User profile
│   ├── services/                   # API Services
│   │   ├── auth_service.dart       # Authentication
│   │   ├── restaurant_service.dart # Restaurant APIs
│   │   └── cart_service.dart       # Cart management
│   ├── widgets/                    # Reusable widgets
│   └── utils/                      # Utilities (theme, helpers)
├── assets/                         # Images, icons, fonts
├── web/                            # Web-specific files
└── pubspec.yaml                    # Dependencies
```

### Documentação (`/docs`)

```
docs/
├── api/                            # API Documentation
│   ├── README.md                   # API Index
│   └── onboarding-restaurante.md  # Restaurant onboarding
├── guides/                         # Guias técnicos
│   └── openstreetmap.md            # OpenStreetMap integration
└── architecture/                   # Diagramas de arquitetura
```

---

## ☕ Backend (Java Spring Boot)

### Tecnologias

- **Spring Boot 3.3.0** (Java 21)
- **Spring Security** + JWT Authentication
- **Spring Data JPA** (Hibernate)
- **PostgreSQL** (Database)
- **Redis** (Cache & Session)
- **Elasticsearch** (Search engine)
- **Flyway** (Database migrations)
- **SpringDoc OpenAPI** (API Documentation)
- **ModelMapper** (DTO mapping)

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
java -jar target/openbag-backend-0.0.1-SNAPSHOT.jar
```

### Profiles disponíveis

| Profile | Descrição | Uso |
|---------|-----------|-----|
| `local` | Desenvolvimento local (localhost) | Banco local, Redis local |
| `docker` | Conecta aos serviços Docker | Banco/Redis no Docker, app local |
| `prod` | Produção | Configurações de produção |

### Estrutura de Pacotes

- **`controller`** - REST endpoints (ex: `AuthController`, `RestaurantController`)
- **`service`** - Lógica de negócio
- **`repository`** - Acesso ao banco de dados (Spring Data JPA)
- **`entity`** - Entidades JPA (mapeadas para tabelas)
- **`dto`** - Objetos de transferência de dados (request/response)
- **`config`** - Configurações (Security, CORS, Redis, etc)
- **`security`** - JWT, autenticação, autorização
- **`exception`** - Tratamento de exceções customizadas

### Hot Reload

Para desenvolvimento com hot reload:

```bash
# Adicionar spring-boot-devtools no pom.xml (já incluído)
mvn spring-boot:run

# O servidor reiniciará automaticamente ao detectar mudanças
```

---

## 📱 Frontend (Flutter)

### Tecnologias

- **Flutter 3.16+** (Dart)
- **Provider** (State management)
- **GoRouter** (Navigation)
- **Dio** (HTTP client)
- **flutter_map** (OpenStreetMap integration)
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

Edite `lib/constants/app_constants.dart`:

```dart
class AppConstants {
  // Desenvolvimento local
  static const String baseUrl = 'http://localhost:8080/api';
  
  // Produção
  // static const String baseUrl = 'https://api.openbag.com/api';
}
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

---

## 🗄️ Banco de Dados

### PostgreSQL

O projeto usa **PostgreSQL 15** como banco de dados principal.

#### Schema

O schema é gerenciado automaticamente via **Flyway Migrations** localizadas em:

```
backend/src/main/resources/db/migration/
```

#### Migrações

```bash
# As migrações rodam automaticamente ao subir a aplicação
# Para forçar rebuild do schema:
docker compose down -v  # Remove volumes
docker compose up -d    # Recria tudo
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
- **Password**: `openbag123`
- **Port**: `5432`

### Redis

Usado para:
- Cache de dados frequentes
- Sessões de usuário
- Rate limiting

```bash
# Acessar Redis CLI
docker exec -it open-bag-redis redis-cli

# Comandos úteis
KEYS *              # Listar todas as keys
GET user:123        # Obter valor
FLUSHALL            # Limpar cache (cuidado!)
```

### Elasticsearch

Usado para busca avançada de restaurantes e produtos.

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
2. **redis** - Redis 7 (cache)
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

#### Profile: `local`

```properties
# application-local.properties
spring.datasource.url=jdbc:postgresql://localhost:5432/openbag
spring.datasource.username=seu_usuario
spring.datasource.password=sua_senha

spring.redis.host=localhost
spring.redis.port=6379

elasticsearch.host=localhost
elasticsearch.port=9200
```

#### Profile: `docker`

```properties
# application-docker.properties
spring.datasource.url=jdbc:postgresql://postgres:5432/openbag
spring.datasource.username=openbag
spring.datasource.password=openbag123

spring.redis.host=redis
spring.redis.port=6379

elasticsearch.host=elasticsearch
elasticsearch.port=9200
```

#### Variáveis Sensíveis (Produção)

Para produção, defina como variáveis de ambiente:

```bash
export JWT_SECRET=seu_jwt_secret_aqui
export DB_PASSWORD=senha_segura
export REDIS_PASSWORD=senha_redis
```

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

---

## 📚 API Documentation

### Swagger/OpenAPI

A documentação interativa da API está disponível em:

**http://localhost:8080/swagger-ui.html**

### Endpoints Principais

#### Autenticação

```
POST /api/auth/register/restaurant    # Cadastro de restaurante
POST /api/auth/register/customer      # Cadastro de cliente
POST /api/auth/register/driver        # Cadastro de entregador
POST /api/auth/login                  # Login
GET  /api/auth/check-email            # Verificar disponibilidade de email
```

#### Restaurantes

```
GET    /api/restaurants               # Listar restaurantes
GET    /api/restaurants/{id}          # Detalhes do restaurante
POST   /api/restaurants               # Criar restaurante (ADMIN)
PUT    /api/restaurants/{id}          # Atualizar restaurante
DELETE /api/restaurants/{id}          # Remover restaurante
```

#### Produtos

```
GET    /api/restaurants/{id}/products # Produtos de um restaurante
POST   /api/products                  # Criar produto
PUT    /api/products/{id}             # Atualizar produto
DELETE /api/products/{id}             # Remover produto
```

#### Pedidos

```
GET    /api/orders                    # Listar pedidos
GET    /api/orders/{id}               # Detalhes do pedido
POST   /api/orders                    # Criar pedido
PUT    /api/orders/{id}/status        # Atualizar status
```

### Postman Collection

Importe a collection localizada em `backend/docs/postman-collection.json` para testar os endpoints.

### Documentação Detalhada

- [API - Onboarding de Restaurante](docs/api/onboarding-restaurante.md)
- [API - Autenticação](docs/api/auth.md) _(a criar)_
- [API - Pedidos](docs/api/orders.md) _(a criar)_

---

## 🔄 Workflow de Desenvolvimento

### Git Flow

1. **Clone o repositório**

```bash
git clone https://github.com/seu-usuario/openbag.git
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

- PRs requerem pelo menos 1 aprovação
- Todos os testes devem passar
- Code coverage mínimo: 80%

### Padrões de Código

#### Java

- **Estilo**: Google Java Style Guide
- **Formatter**: IntelliJ/Eclipse default
- **Checkstyle**: Configurado no Maven

```bash
# Verificar estilo
mvn checkstyle:check
```

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

# Rodar todos os testes
mvn test

# Rodar testes de integração
mvn verify

# Rodar com coverage
mvn test jacoco:report

# Ver report de coverage
open target/site/jacoco/index.html
```

#### Estrutura de Testes

```
src/test/java/com/openbag/
├── controller/          # Testes de Controller (MockMvc)
├── service/             # Testes de Service (Mockito)
├── repository/          # Testes de Repository (DataJpaTest)
└── integration/         # Testes de integração (SpringBootTest)
```

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

**Solução**: Verificar configuração em `backend/src/main/java/com/openbag/config/CorsConfig.java`

```java
@Configuration
public class CorsConfig implements WebMvcConfigurer {
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOrigins("http://localhost:*")  // Permite todas portas localhost
                .allowedMethods("*");
    }
}
```

#### 5. Migrações Flyway falham

**Erro**: `Migration checksum mismatch`

**Solução**:
```bash
# Remover volumes e recriar
docker compose down -v
docker compose up -d

# Ou limpar histórico Flyway manualmente
docker exec -it open-bag-postgres psql -U openbag -d openbag
DELETE FROM flyway_schema_history;
```

#### 6. Redis connection timeout

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

- [OpenStreetMap Integration](docs/guides/openstreetmap.md)
- [API - Onboarding de Restaurante](docs/api/onboarding-restaurante.md)

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
- Abra uma [Issue](https://github.com/seu-usuario/openbag/issues) para reportar bugs
- Entre em contato com a equipe: dev@openbag.com

---

**Desenvolvido com ❤️ pela comunidade OpenBag**
