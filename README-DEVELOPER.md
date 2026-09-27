# 🛠️ OpenBag - Documentação para Desenvolvedores

Documentação técnica completa para desenvolvedores que desejam contribuir com o projeto OpenBag.

> Versão da documentação: **0.2.0**, atualizada em 2026-09-27. Veja o [CHANGELOG](CHANGELOG.md) e a [arquitetura](docs/architecture/README.md).

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

- **PostgreSQL 15+**
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

O backend é organizado **por módulo de domínio**. Cada módulo tem `controller`, `dto`, `entity`, `repository` e `service`. Os detalhes estão na [documentação de arquitetura](docs/architecture/README.md).

```
backend/
├── src/
│   ├── main/
│   │   ├── java/com/openbag/
│   │   │   ├── annotation/         # Anotações de validação
│   │   │   ├── config/             # Security, OpenAPI, Redis, agendamento
│   │   │   ├── enums/              # Status e tipos compartilhados
│   │   │   ├── exception/          # GlobalExceptionHandler
│   │   │   ├── security/           # JWT, UserDetails, PermissionEvaluator
│   │   │   └── modules/
│   │   │       ├── user/           # Cadastro, login, perfil
│   │   │       ├── restaurant/     # Loja, aparência, horários, página pública
│   │   │       ├── menu/           # Cardápio do dono
│   │   │       ├── product/        # Produtos, categorias, complementos
│   │   │       ├── combo/          # Combos
│   │   │       ├── order/          # Pedidos e tempo real (WebSocket)
│   │   │       ├── delivery/       # Entregadores, despacho, rotas, caixa
│   │   │       ├── organization/   # Associações e cooperativas
│   │   │       └── shared/         # Arquivos, health, utilitários
│   │   └── resources/
│   │       ├── application.properties           # Config padrão
│   │       ├── application-local.properties     # Config local
│   │       └── application-docker.properties    # Config Docker
│   └── test/                       # Testes unitários e de serviço
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
│   │   ├── home/, restaurant/      # Vitrine e página da loja (cliente, em testes)
│   │   ├── cart/, checkout/, orders/
│   │   ├── restaurant_panel/       # Painel do restaurante (/restaurante)
│   │   ├── kitchen/                # Tela da cozinha
│   │   ├── courier/                # Painel do entregador (/entregador, em desenvolvimento)
│   │   ├── association/            # Painel da associação (/associacao, em desenvolvimento)
│   │   ├── admin/, auth/, onboarding/, profile/
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

- **Spring Boot 3.3.0** (Java 25)
- **Spring Security** + JWT Authentication
- **Spring Data JPA** (Hibernate)
- **PostgreSQL** (Database)
- **WebSocket + STOMP** (pedidos e ofertas em tempo real)
- **Redis** e **Elasticsearch** (no Docker Compose; ainda sem uso relevante no código)
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
java -jar target/openbag-backend-0.2.0.jar
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

Hoje o schema é gerado pelo Hibernate (`spring.jpa.hibernate.ddl-auto=update`). Os arquivos em `db/migration` são antigos e **não são aplicados**, porque o Flyway não está no `pom.xml`.

Cuidados com o `update`:
- colunas novas em tabelas existentes chegam `NULL`, então use tipos wrapper ou getters com valor padrão;
- as restrições `CHECK` de enums não são atualizadas, então um valor novo de enum exige ajuste manual no banco.

A troca por migrações versionadas está no roadmap da versão **0.4.0** (veja o [CHANGELOG](CHANGELOG.md#roadmap)).

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
- **Password**: `openbag123`
- **Port**: `5432`

### Redis

Hoje só a configuração existe. Os usos previstos são cache e rate limiting (roadmap 0.4.0).

```bash
# Acessar Redis CLI
docker exec -it open-bag-redis redis-cli

# Comandos úteis
KEYS *              # Listar todas as keys
GET user:123        # Obter valor
FLUSHALL            # Limpar cache (cuidado!)
```

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

#### 5. Erro de restrição ao salvar um valor novo de enum

**Erro**: `violates check constraint "..._check"`

**Causa**: o `ddl-auto=update` não atualiza as restrições `CHECK` que o Hibernate cria para colunas `@Enumerated(STRING)`.

**Solução**:
```bash
docker exec -it open-bag-postgres psql -U openbag -d openbag
-- remova a restrição antiga (o nome aparece na mensagem de erro)
ALTER TABLE <tabela> DROP CONSTRAINT <tabela>_<coluna>_check;
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
