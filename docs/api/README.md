# 🔌 API Documentation

Documentação completa dos endpoints da API REST do OpenBag.

## 📋 Índice Geral

- [Autenticação](#autenticação)
- [Restaurantes](#restaurantes)
- [Produtos](#produtos)
- [Pedidos](#pedidos)
- [Usuários](#usuários)
- [Entregadores](#entregadores)

---

## 🔐 Autenticação

Todos os endpoints protegidos requerem autenticação via **JWT Bearer Token**.

### Incluir Token nas Requisições

```bash
Authorization: Bearer <seu_token_jwt>
```

### Obter Token

Use os endpoints de registro ou login para obter um token JWT.

---

## 📑 Endpoints Disponíveis

### Autenticação e Onboarding

#### [Onboarding de Restaurante](onboarding-restaurante.md)

Documentação completa do processo de cadastro de restaurantes.

**Endpoints:**
- `GET /api/auth/check-email` - Verificar disponibilidade de email
- `POST /api/auth/register/restaurant` - Cadastro completo de restaurante
- `POST /api/auth/login` - Login (obtém JWT token)

**[📖 Ver documentação completa](onboarding-restaurante.md)**

---

### Restaurantes

> **Status:** Em desenvolvimento  
> **Documentação:** _A ser criada_

**Endpoints previstos:**
```
GET    /api/restaurants              # Listar restaurantes
GET    /api/restaurants/{id}         # Detalhes do restaurante
GET    /api/restaurants/search       # Buscar por nome, categoria, localização
POST   /api/restaurants              # Criar restaurante (ADMIN)
PUT    /api/restaurants/{id}         # Atualizar restaurante (OWNER)
DELETE /api/restaurants/{id}         # Remover restaurante (ADMIN)
GET    /api/restaurants/{id}/menu    # Cardápio completo
```

---

### Produtos

> **Status:** Em desenvolvimento  
> **Documentação:** _A ser criada_

**Endpoints previstos:**
```
GET    /api/products                 # Listar produtos
GET    /api/products/{id}            # Detalhes do produto
POST   /api/products                 # Criar produto (RESTAURANT_OWNER)
PUT    /api/products/{id}            # Atualizar produto
DELETE /api/products/{id}            # Remover produto
PATCH  /api/products/{id}/stock      # Atualizar estoque
```

---

### Pedidos

> **Status:** Em desenvolvimento  
> **Documentação:** _A ser criada_

**Endpoints previstos:**
```
GET    /api/orders                   # Listar pedidos do usuário
GET    /api/orders/{id}              # Detalhes do pedido
POST   /api/orders                   # Criar novo pedido
PUT    /api/orders/{id}/status       # Atualizar status (RESTAURANT/DRIVER)
DELETE /api/orders/{id}              # Cancelar pedido
GET    /api/orders/{id}/tracking     # Rastreamento em tempo real
```

---

### Usuários

> **Status:** Em desenvolvimento  
> **Documentação:** _A ser criada_

**Endpoints previstos:**
```
GET    /api/users/me                 # Perfil do usuário logado
PUT    /api/users/me                 # Atualizar perfil
PUT    /api/users/me/password        # Alterar senha
GET    /api/users/me/addresses       # Endereços salvos
POST   /api/users/me/addresses       # Adicionar endereço
DELETE /api/users/me/addresses/{id}  # Remover endereço
```

---

### Entregadores

> **Status:** Em desenvolvimento  
> **Documentação:** _A ser criada_

**Endpoints previstos:**
```
GET    /api/drivers                  # Listar entregadores (ADMIN/COOPERATIVE)
GET    /api/drivers/{id}             # Detalhes do entregador
POST   /api/drivers                  # Cadastrar entregador
PUT    /api/drivers/{id}             # Atualizar informações
GET    /api/drivers/{id}/deliveries  # Histórico de entregas
GET    /api/drivers/available        # Entregadores disponíveis
```

---

## 🧪 Testando a API

### Swagger UI (Recomendado)

A interface interativa Swagger está disponível quando o backend está rodando:

**URL:** http://localhost:8080/swagger-ui.html

### Postman Collection

Importe a collection localizada em:

```
backend/docs/postman-collection.json
```

### cURL Examples

```bash
# Verificar email disponível
curl -X GET "http://localhost:8080/api/auth/check-email?email=teste@example.com"

# Login
curl -X POST "http://localhost:8080/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "teste@example.com",
    "password": "senha123"
  }'

# Listar restaurantes (com token)
curl -X GET "http://localhost:8080/api/restaurants" \
  -H "Authorization: Bearer SEU_TOKEN_JWT"
```

---

## 📊 Schemas e Modelos

### Restaurant Schema

```json
{
  "id": "uuid",
  "name": "string",
  "email": "string",
  "phone": "string",
  "category": "string",
  "description": "string",
  "address": {
    "street": "string",
    "number": "string",
    "complement": "string",
    "neighborhood": "string",
    "city": "string",
    "state": "string",
    "zipCode": "string",
    "latitude": "number",
    "longitude": "number"
  },
  "operatingHours": [
    {
      "dayOfWeek": "MONDAY",
      "openTime": "09:00",
      "closeTime": "18:00"
    }
  ],
  "isActive": "boolean",
  "rating": "number",
  "createdAt": "timestamp"
}
```

### Order Schema

```json
{
  "id": "uuid",
  "customer": {
    "id": "uuid",
    "name": "string"
  },
  "restaurant": {
    "id": "uuid",
    "name": "string"
  },
  "items": [
    {
      "product": {
        "id": "uuid",
        "name": "string",
        "price": "number"
      },
      "quantity": "number",
      "subtotal": "number"
    }
  ],
  "deliveryAddress": "Address",
  "status": "PENDING | CONFIRMED | PREPARING | READY | IN_DELIVERY | DELIVERED | CANCELLED",
  "totalAmount": "number",
  "deliveryFee": "number",
  "platformFee": 2.00,
  "createdAt": "timestamp",
  "estimatedDelivery": "timestamp"
}
```

---

## 🔒 Autenticação e Autorização

### Roles (Papéis)

| Role | Descrição | Permissões |
|------|-----------|------------|
| `CUSTOMER` | Cliente final | Fazer pedidos, avaliar |
| `RESTAURANT_OWNER` | Dono de restaurante | Gerenciar cardápio, pedidos |
| `DRIVER` | Entregador | Aceitar/concluir entregas |
| `COOPERATIVE_ADMIN` | Admin de cooperativa | Gerenciar entregadores |
| `ADMIN` | Administrador da plataforma | Acesso total |

### JWT Token Structure

```json
{
  "sub": "user_id",
  "email": "user@example.com",
  "roles": ["CUSTOMER"],
  "iat": 1234567890,
  "exp": 1234567890
}
```

**Duração do token:** 24 horas

---

## ⚠️ Códigos de Erro

| Código | Significado | Descrição |
|--------|-------------|-----------|
| `200` | OK | Requisição bem-sucedida |
| `201` | Created | Recurso criado com sucesso |
| `204` | No Content | Sucesso sem conteúdo de retorno |
| `400` | Bad Request | Dados inválidos |
| `401` | Unauthorized | Token ausente ou inválido |
| `403` | Forbidden | Sem permissão |
| `404` | Not Found | Recurso não encontrado |
| `409` | Conflict | Conflito (ex: email já existe) |
| `422` | Unprocessable Entity | Validação falhou |
| `500` | Internal Server Error | Erro no servidor |

### Formato de Erro

```json
{
  "timestamp": "2026-04-23T10:30:00Z",
  "status": 400,
  "error": "Bad Request",
  "message": "Email já está em uso",
  "path": "/api/auth/register"
}
```

---

## 📈 Rate Limiting

> **Status:** Planejado  
> **Implementação:** _A ser definida_

Limites previstos:
- **Anônimo**: 100 req/hora
- **Autenticado**: 1000 req/hora
- **Restaurante**: 5000 req/hora

---

## 🔄 Versionamento

**Versão atual:** `v1`

Todas as APIs estão sob o prefixo `/api/v1/` (ou apenas `/api/` para v1).

Mudanças futuras usarão:
- `/api/v2/` para breaking changes
- Backward compatibility mantida por 6 meses

---

## 📝 Changelog

### v1.0.0 (Current)
- ✅ Autenticação JWT
- ✅ Onboarding de restaurantes
- ✅ Cadastro de usuários
- 🚧 CRUD de produtos (em desenvolvimento)
- 🚧 Sistema de pedidos (em desenvolvimento)

---

## 🤝 Contribuindo

Quer adicionar ou melhorar documentação de API?

1. Veja [CONTRIBUTING.md](../../CONTRIBUTING.md)
2. Use o tipo de commit `docs(api):`
3. Inclua exemplos de request/response
4. Teste os exemplos antes de commitar

---

## 📞 Suporte

- 🐛 [Reportar Bug de API](https://github.com/seu-usuario/openbag/issues)
- 💬 [Discussões](https://github.com/seu-usuario/openbag/discussions)
- 📧 Email: api@openbag.app

---

<p align="center">
  <a href="../README.md">📚 Voltar para Documentação Geral</a>
</p>
