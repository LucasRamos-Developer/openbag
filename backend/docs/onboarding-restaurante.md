# API - Onboarding de Restaurante

Documentação dos endpoints para cadastro completo de restaurantes parceiros na plataforma OpenBag.

## Endpoints

### 1. Verificar Disponibilidade de E-mail

Verifica se um e-mail está disponível para cadastro antes de iniciar o processo de onboarding.

**Endpoint:** `GET /api/auth/check-email`

**Autenticação:** Não requerida (público)

**Query Parameters:**

| Parâmetro | Tipo   | Obrigatório | Descrição                    |
|-----------|--------|-------------|------------------------------|
| email     | string | Sim         | E-mail a ser verificado      |

**Exemplo de Request:**
```bash
GET /api/auth/check-email?email=contato@pizzaria.com
```

**Exemplo de Response (200 OK):**
```json
{
  "available": true
}
```

```json
{
  "available": false
}
```

**Códigos de Status:**
- `200 OK` - Verificação realizada com sucesso

---

### 2. Cadastro Completo de Restaurante

Realiza o cadastro completo de um restaurante, incluindo proprietário, endereço, horários de funcionamento e configurações de layout.

**Endpoint:** `POST /api/auth/register/restaurant`

**Autenticação:** Não requerida (público)

**Content-Type:** `application/json`

**Request Body:**

```json
{
  "owner": {
    "fullName": "string",      // Obrigatório, max 100 caracteres
    "email": "string",          // Obrigatório, formato válido de e-mail, max 100 caracteres
    "phoneNumber": "string",    // Obrigatório, max 15 caracteres
    "password": "string"        // Obrigatório, min 6 caracteres, max 100 caracteres
  },
  "restaurant": {
    "name": "string",           // Obrigatório, max 100 caracteres
    "description": "string",    // Opcional, max 500 caracteres
    "phoneNumber": "string",    // Obrigatório, max 15 caracteres
    "cnpj": "string",           // Obrigatório, max 18 caracteres
    "logoUrl": "string",        // Opcional
    "bannerUrl": "string",      // Opcional
    "deliveryFee": number,      // Obrigatório, >= 0.0
    "minimumOrder": number,     // Obrigatório, >= 0.0
    "deliveryTimeMin": number,  // Obrigatório, >= 0 (minutos)
    "deliveryTimeMax": number   // Obrigatório, >= 0 (minutos)
  },
  "address": {
    "street": "string",         // Endereço completo
    "number": "string",
    "complement": "string",     // Opcional
    "neighborhood": "string",
    "city": "string",
    "state": "string",
    "zipCode": "string",
    "latitude": number,         // Opcional
    "longitude": number         // Opcional
  },
  "openingHours": [             // Array, min 1 item
    {
      "label": "string",        // Opcional, max 50 caracteres (ex: "Café da manhã", "Almoço")
      "weekday": number,        // Obrigatório, 1-7 (1=segunda, 7=domingo)
      "openTime": "HH:mm",      // Obrigatório, formato 24h (ex: "08:00")
      "closeTime": "HH:mm",     // Obrigatório, formato 24h (ex: "23:00")
      "observation": "string"   // Opcional, max 255 caracteres
    }
  ],
  "layoutConfig": {
    "primaryColor": "string",   // Obrigatório, formato hexadecimal #RRGGBB (ex: "#FF0000")
    "secondaryColor": "string"  // Obrigatório, formato hexadecimal #RRGGBB (ex: "#000000")
  },
  "categoryIds": [number]       // Array de IDs de categorias, min 1 item
}
```

**Exemplo Completo de Request:**
```json
{
  "owner": {
    "fullName": "João Silva",
    "email": "joao@pizzaria.com",
    "password": "senha123",
    "phoneNumber": "11999999999"
  },
  "restaurant": {
    "name": "Pizzaria do João",
    "description": "As melhores pizzas artesanais da região",
    "phoneNumber": "1133334444",
    "cnpj": "12.345.678/0001-90",
    "logoUrl": "https://exemplo.com/logo.png",
    "bannerUrl": "https://exemplo.com/banner.jpg",
    "deliveryFee": 5.00,
    "minimumOrder": 30.00,
    "deliveryTimeMin": 30,
    "deliveryTimeMax": 50
  },
  "address": {
    "street": "Rua das Flores",
    "number": "123",
    "complement": "Loja 2",
    "neighborhood": "Centro",
    "city": "São Paulo",
    "state": "SP",
    "zipCode": "01234-567",
    "latitude": -23.550520,
    "longitude": -46.633308
  },
  "openingHours": [
    {
      "label": "Almoço",
      "weekday": 1,
      "openTime": "11:00",
      "closeTime": "15:00"
    },
    {
      "label": "Jantar",
      "weekday": 1,
      "openTime": "18:00",
      "closeTime": "23:00"
    },
    {
      "label": "Almoço",
      "weekday": 2,
      "openTime": "11:00",
      "closeTime": "15:00"
    },
    {
      "label": "Jantar",
      "weekday": 2,
      "openTime": "18:00",
      "closeTime": "23:00"
    }
  ],
  "layoutConfig": {
    "primaryColor": "#FF0000",
    "secondaryColor": "#000000"
  },
  "categoryIds": [1, 2]
}
```

**Exemplo de Response (201 Created):**
```json
{
  "restaurantId": 15,
  "message": "Restaurante cadastrado com sucesso!",
  "slug": null
}
```

**Exemplos de Erros:**

**400 Bad Request - E-mail duplicado:**
```json
{
  "error": "Email já está em uso"
}
```

**400 Bad Request - Telefone duplicado:**
```json
{
  "error": "Telefone já está em uso"
}
```

**400 Bad Request - CNPJ duplicado:**
```json
{
  "error": "CNPJ já cadastrado"
}
```

**400 Bad Request - Validação de campos:**
```json
{
  "error": "Validation failed",
  "errors": {
    "owner.email": "Email deve ter um formato válido",
    "layoutConfig.primaryColor": "Cor primária deve estar no formato hexadecimal (ex: #FF0000)",
    "openingHours": "Horários de funcionamento são obrigatórios"
  }
}
```

**404 Not Found - Categoria inexistente:**
```json
{
  "error": "Uma ou mais categorias não foram encontradas"
}
```

**Códigos de Status:**
- `201 Created` - Restaurante cadastrado com sucesso
- `400 Bad Request` - Erro de validação ou dados duplicados
- `404 Not Found` - Categorias não encontradas
- `500 Internal Server Error` - Erro interno do servidor

---

## Regras de Negócio

### Horários de Funcionamento (openingHours)

1. **Múltiplos períodos por dia:** Um restaurante pode ter vários horários no mesmo dia
   - Exemplo: Café (08:00-11:00), Almoço (12:00-15:00), Jantar (18:00-23:00)

2. **Dias da semana:**
   - `1` = Segunda-feira
   - `2` = Terça-feira
   - `3` = Quarta-feira
   - `4` = Quinta-feira
   - `5` = Sexta-feira
   - `6` = Sábado
   - `7` = Domingo

3. **Dia fechado:** Se não houver registro de `openingHours` para um determinado dia, o restaurante está fechado nesse dia
   - Não é necessário enviar um registro marcando como "fechado"

4. **Validações:**
   - `closeTime` deve ser posterior a `openTime`
   - Horários no formato 24h (HH:mm)

### Layout Config

1. **Cores:** Devem estar no formato hexadecimal `#RRGGBB`
   - Exemplos válidos: `#FF0000`, `#000000`, `#3498db`
   - Exemplos inválidos: `red`, `rgb(255,0,0)`, `#F00`

### Categorias

1. **Múltiplas categorias:** Um restaurante pode pertencer a múltiplas categorias
   - Exemplo: [1, 2] = Pizzaria + Italiana

2. **IDs válidos:** Todas as categorias enviadas em `categoryIds` devem existir no sistema

### Proprietário (Owner)

1. **Roles automáticas:** Após o cadastro, o proprietário recebe automaticamente:
   - `CUSTOMER` - Role padrão para todos os usuários
   - `RESTAURANT_OWNER` - Role específica para donos de restaurante

2. **Unicidade:**
   - E-mail deve ser único no sistema
   - Telefone deve ser único no sistema

### Restaurante

1. **CNPJ único:** Cada CNPJ pode ter apenas um restaurante cadastrado

2. **Status inicial:**
   - `isActive: true` - Restaurante ativo
   - `isOpen: true` - Restaurante disponível para pedidos

---

## Fluxo Recomendado para o Front-end

### Passo 1: Validação de E-mail
```javascript
// Antes de mostrar o formulário completo
const response = await fetch('/api/auth/check-email?email=contato@pizzaria.com');
const { available } = await response.json();

if (!available) {
  // Mostrar mensagem: "E-mail já cadastrado. Faça login ou use outro e-mail."
}
```

### Passo 2: Cadastro Completo
```javascript
const onboardingData = {
  owner: { /* dados do formulário */ },
  restaurant: { /* dados do formulário */ },
  address: { /* dados do formulário */ },
  openingHours: [ /* array de horários */ ],
  layoutConfig: { /* cores escolhidas */ },
  categoryIds: [ /* categorias selecionadas */ ]
};

const response = await fetch('/api/auth/register/restaurant', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(onboardingData)
});

if (response.status === 201) {
  const { restaurantId, message } = await response.json();
  // Sucesso! Redirecionar para dashboard ou página de confirmação
} else if (response.status === 400) {
  const { error } = await response.json();
  // Mostrar mensagem de erro (email duplicado, validação, etc)
} else if (response.status === 404) {
  const { error } = await response.json();
  // Categoria inválida - verificar seleção de categorias
}
```

---

## Exemplos de Casos de Uso

### Restaurante com múltiplos horários por dia
```json
"openingHours": [
  {
    "label": "Café da manhã",
    "weekday": 1,
    "openTime": "08:00",
    "closeTime": "11:00"
  },
  {
    "label": "Almoço",
    "weekday": 1,
    "openTime": "12:00",
    "closeTime": "15:00"
  },
  {
    "label": "Jantar",
    "weekday": 1,
    "openTime": "18:00",
    "closeTime": "23:00"
  }
]
```

### Restaurante fechado em alguns dias
```json
// Aberto segunda (1) a sexta (5), fechado sábado e domingo
"openingHours": [
  { "weekday": 1, "openTime": "11:00", "closeTime": "23:00" },
  { "weekday": 2, "openTime": "11:00", "closeTime": "23:00" },
  { "weekday": 3, "openTime": "11:00", "closeTime": "23:00" },
  { "weekday": 4, "openTime": "11:00", "closeTime": "23:00" },
  { "weekday": 5, "openTime": "11:00", "closeTime": "23:00" }
  // Sem registros para weekday 6 e 7 = fechado
]
```

### Restaurante com horário especial em um dia
```json
"openingHours": [
  { "weekday": 1, "openTime": "11:00", "closeTime": "23:00" },
  // ...
  { 
    "weekday": 7, 
    "label": "Domingo - Horário Especial",
    "openTime": "12:00", 
    "closeTime": "20:00",
    "observation": "Rodízio de massas aos domingos"
  }
]
```

---

## Notas Importantes

1. **Transação Atômica:** Todo o cadastro é feito em uma única transação. Se qualquer parte falhar, nada é salvo.

2. **Senha:** A senha do proprietário é automaticamente criptografada com BCrypt antes de ser armazenada.

3. **Validação em Tempo Real:** Recomenda-se validar os campos no front-end antes de enviar (formato de e-mail, cores hex, etc).

4. **CNPJ:** Aceita com ou sem formatação (12.345.678/0001-90 ou 12345678000190).

5. **Telefone:** Aceita com ou sem formatação, mas limite de 15 caracteres.

6. **Logo e Banner:** URLs opcionais. Podem ser adicionados posteriormente via upload S3.

---

## Testando com cURL

```bash
# 1. Verificar e-mail
curl -X GET "http://localhost:8080/api/auth/check-email?email=novo@teste.com"

# 2. Cadastrar restaurante
curl -X POST "http://localhost:8080/api/auth/register/restaurant" \
  -H "Content-Type: application/json" \
  -d '{
    "owner": {
      "fullName": "Maria Santos",
      "email": "maria@hamburgueriatop.com",
      "password": "senha123",
      "phoneNumber": "21988887777"
    },
    "restaurant": {
      "name": "Hamburgueria Top",
      "description": "Os melhores hambúrgueres artesanais",
      "phoneNumber": "2133332222",
      "cnpj": "98765432000100",
      "deliveryFee": 7.50,
      "minimumOrder": 25.00,
      "deliveryTimeMin": 25,
      "deliveryTimeMax": 40
    },
    "address": {
      "street": "Avenida Principal",
      "number": "500",
      "neighborhood": "Botafogo",
      "city": "Rio de Janeiro",
      "state": "RJ",
      "zipCode": "22250-040"
    },
    "openingHours": [
      {
        "weekday": 1,
        "openTime": "18:00",
        "closeTime": "23:30"
      }
    ],
    "layoutConfig": {
      "primaryColor": "#FFD700",
      "secondaryColor": "#8B4513"
    },
    "categoryIds": [1]
  }'
```

---

## Perguntas Frequentes (FAQ)

**Q: Posso cadastrar um restaurante sem especificar logo ou banner?**  
R: Sim, `logoUrl` e `bannerUrl` são opcionais.

**Q: O que acontece se eu enviar um weekday inválido (ex: 0 ou 8)?**  
R: Você receberá um erro 400 com a mensagem "Dia da semana deve ser entre 1 e 7".

**Q: Posso usar a mesma cor para primaryColor e secondaryColor?**  
R: Sim, não há validação que impeça isso, mas não é recomendado para UX.

**Q: Como obter a lista de categorias disponíveis?**  
R: Use o endpoint `GET /api/categories/public` (verifique documentação separada).

**Q: O proprietário pode ter múltiplos restaurantes?**  
R: Sim, o mesmo e-mail não pode ser reutilizado, mas a arquitetura suporta um owner com múltiplos restaurantes no futuro.

**Q: A senha precisa ter requisitos especiais (maiúsculas, números, etc)?**  
R: Atualmente apenas mínimo de 6 caracteres. Validações adicionais podem ser implementadas no front-end.
