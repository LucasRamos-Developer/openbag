# 🛍️ Open Bag

Um aplicativo de delivery open source, similar ao iFood, desenvolvido com Java Spring Boot e Flutter.

## 📋 Visão Geral

O Open Bag é uma plataforma completa de delivery que conecta restaurantes, entregadores e clientes através de uma solução tecnológica moderna e escalável.

## 🏗️ Arquitetura

```
open-bag/
├── backend/                 # API REST em Java Spring Boot
│   ├── src/main/java/
│   ├── src/main/resources/
│   └── pom.xml
├── frontend/               # Aplicativo Flutter
│   ├── lib/
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
├── docs/                   # Documentação
└── docker-compose.yml      # Configuração Docker
```

## 🚀 Funcionalidades Principais

### Para Clientes
- [x] Cadastro e autenticação
- [x] Busca de restaurantes por localização
- [x] Visualização de cardápios
- [x] Carrinho de compras
- [x] Pagamento integrado
- [x] Rastreamento de pedidos em tempo real
- [x] Avaliações e comentários

### Para Restaurantes
- [x] Painel de gerenciamento
- [x] Cadastro de produtos
- [x] Gestão de pedidos
- [x] Controle de estoque
- [x] Relatórios de vendas

### Para Entregadores
- [x] App de entrega
- [x] Gestão de rotas
- [x] Histórico de entregas
- [x] Sistema de pagamento

## 🛠️ Tecnologias

### Backend
- **Java 17+**
- **Spring Boot 3.x**
- **Spring Security** (JWT)
- **Spring Data JPA**
- **PostgreSQL**
- **Redis** (Cache)
- **Docker**

### Frontend
- **Flutter 3.x**
- **Dart**
- **Provider/Bloc** (Gerenciamento de estado)
- **HTTP/Dio** (Requisições)
- **OpenStreetMap** (Mapas)

## 📱 Screenshots

*Em desenvolvimento...*

## 🚀 Como Executar

### Pré-requisitos
- Java 17+
- Maven 3.6+
- Flutter 3.0+
- Docker & Docker Compose
- PostgreSQL (ou usar Docker)

### Backend
```bash
cd backend
mvn spring-boot:run
```

### Frontend
```bash
cd frontend
flutter pub get
flutter run
```

### Com Docker
```bash
docker-compose up
```

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch (`git checkout -b feature/nova-funcionalidade`)
3. Commit suas mudanças (`git commit -am 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 👥 Equipe

- **Desenvolvedor Principal**: Lucas Ramos
- **Contribuidores**: [Lista de contribuidores]

## 🗺️ Roadmap

- [ ] Sistema de cupons e promoções
- [ ] Chat em tempo real
- [ ] Sistema de fidelidade
- [ ] Analytics avançado
- [ ] API para terceiros
- [ ] Suporte a múltiplas linguagens

## 📞 Contato

- Email: contato@openbag.dev
- Discord: [Link do servidor]
- Website: [Em construção]

---

⭐ Se você gostou do projeto, não esqueça de dar uma estrela!
