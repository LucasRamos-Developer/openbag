# 🛍️ OpenBag

> **Uma plataforma open source de delivery que conecta associações e cooperativas de entregadores com restaurantes, promovendo taxas justas e impacto social positivo.**

---

## 🎯 Nossa Missão

O OpenBag nasceu para **combater o monopólio** das grandes plataformas de delivery e oferecer uma alternativa justa, transparente e socialmente responsável.

### O Problema

Grandes empresas dominam o mercado de delivery e implementam taxas abusivas sem transparência:

- **Taxas elevadas** que sufocam restaurantes pequenos e médios
- **Comissões que chegam a 30%** sobre cada pedido
- **Mudanças unilaterais** de regras e preços (exemplo: taxa de R$ 1,99 implementada sem aviso)
- **Falta de proteção social** para entregadores autônomos
- **Centralização de lucros** em detrimento de quem realmente trabalha

### Nossa Solução

O OpenBag propõe um modelo **justo, transparente e cooperativo**:

| Característica | Similares | OpenBag |
|---------------|-------------------|---------|
| **Comissão** | Até 30% por pedido | Taxa fixa de R$ 1,98* |
| **Transparência** | Mudanças unilaterais | Open source, auditável |
| **Proteção Social** | Nenhuma | Modelo cooperativo viabiliza benefícios |
| **Quem lucra?** | Shareholders | Restaurantes e entregadores |
| **Controle** | Centralizado | Descentralizado (cooperativas) |

**Taxa dividida: R$ 0,99 para o restaurante + R$ 0,99 para a cooperativa de entregadores*

💡 **O resto é todo de quem trabalha:** diferente de modelos que cobram percentual, nossa taxa fixa garante que o lucro real fique com restaurantes e entregadores, reduzindo custos para o consumidor.

---

## 🤝 Impacto Social

O OpenBag foi pensado para fortalecer **associações e cooperativas de entregadores**. Diferente de plataformas que trabalham com autônomos isolados, **exigimos que entregadores sejam vinculados a uma cooperativa ou associação**.

### Por Que Apenas Cooperativas?

O modelo cooperativo permite que a taxa de R$ 1,00 destinada aos entregadores seja usada para:

✅ **Seguro de vida e acidentes pessoais** para os membros  
✅ **Planos de previdência e aposentadoria** coletivos  
✅ **Suporte jurídico** compartilhado  
✅ **Capacitação e treinamento** profissional  
✅ **Representação coletiva** e voz ativa  
✅ **Gestão democrática** das decisões

💡 **A plataforma não fornece esses serviços diretamente** - ela viabiliza que as cooperativas possam oferecê-los aos seus associados através da taxa destinada a elas.

### Para Restaurantes

✅ **Custos previsíveis** (sem surpresas de comissão)  
✅ **Maior margem de lucro** por pedido  
✅ **Controle sobre seus dados** e clientes  
✅ **Parcerias locais** com cooperativas da região  
✅ **Visibilidade justa** (sem leilão de posições)

### Para Consumidores

✅ **Preços mais baixos** (menos intermediação)  
✅ **Transparência total** sobre taxas  
✅ **Apoio à economia local** e cooperativismo  
✅ **Contribuição para direitos trabalhistas** dos entregadores

---

## 🚀 Como Funciona

### 1. Restaurante se cadastra na plataforma
Processo simples e gratuito, sem burocracias desnecessárias.

### 2. Cooperativa de entregadores faz parceria
Associações e cooperativas locais se cadastram e conectam aos restaurantes da região.

### 3. Cliente faz pedido pelo app
Interface simples e intuitiva, web e mobile.

### 4. Entregador associado realiza a entrega
Entregador vinculado à cooperativa aceita e entrega usando rotas otimizadas (OpenStreetMap).

### 5. Taxas transparentes beneficiam todos
- **R$ 1,00** vai para o restaurante (manutenção da plataforma)
- **R$ 1,00** vai para a cooperativa (que pode usar para benefícios sociais)
- **Todo o resto** fica com quem trabalhou: restaurante e entregador

---

## 🏗️ Arquitetura Técnica

```
OpenBag/
├── 📱 Frontend (Flutter)    → App mobile e web
├── ☕ Backend (Spring Boot) → API REST (Java 21)
├── 🗄️ PostgreSQL            → Banco de dados
├── 🔍 Elasticsearch         → Busca de restaurantes
├── 🗺️ OpenStreetMap         → Mapas (sem dependência do Google)
└── 🐳 Docker Compose        → Deploy simplificado
```

**[📖 Ver documentação técnica completa](README-DEVELOPER.md)**

---

## 💻 Quick Start

### Para Desenvolvedores

```bash
# 1. Clone o repositório
git clone https://github.com/seu-usuario/openbag.git
cd openbag

# 2. Suba a infraestrutura
docker compose up -d

# 3. Rode o backend
cd backend
mvn spring-boot:run

# 4. Rode o frontend
cd frontend
flutter run -d chrome
```

📚 **Para instruções detalhadas de desenvolvimento, consulte [README-DEVELOPER.md](README-DEVELOPER.md)**

### Para Mantenedores: Publicar Landing Page

Quer hospedar a landing page do projeto no GitHub Pages?

🌐 **Veja o guia completo: [GITHUB_PAGES.md](GITHUB_PAGES.md)**

### Para Usuários (em breve)

- 📱 **App Android**: Google Play Store _(em desenvolvimento)_
- 🍎 **App iOS**: Apple App Store _(em desenvolvimento)_
- 🌐 **Web**: https://openbag.app _(em desenvolvimento)_

---

## 🗺️ Roadmap

### ✅ Fase 1 - MVP (Atual)
- [x] Cadastro de restaurantes
- [x] Cadastro de clientes
- [x] Carrinho de compras
- [x] Sistema de pedidos
- [x] Integração com OpenStreetMap
- [x] Autenticação JWT

### 🚧 Fase 2 - Cooperativas (Q2 2026)
- [ ] Painel de gestão para cooperativas
- [ ] Sistema de alocação de entregas
- [ ] Relatórios financeiros
- [ ] Integração com sistemas de pagamento
- [ ] Dashboard de métricas sociais

### 📅 Fase 3 - Expansão (Q3 2026)
- [ ] App nativo para entregadores
- [ ] Sistema de avaliações
- [ ] Programa de fidelidade
- [ ] Multi-idiomas
- [ ] Expansão para outras cidades

### 🔮 Fase 4 - Governança (Q4 2026)
- [ ] DAO (Organização Autônoma Descentralizada)
- [ ] Votação democrática de features
- [ ] Modelo de franquia cooperativa
- [ ] Federação de cooperativas

---

## 🤝 Como Contribuir

O OpenBag é **100% open source** e depende da comunidade!

### Formas de Contribuir

- 💻 **Código**: Backend (Java), Frontend (Flutter), DevOps
- 📝 **Documentação**: Tradução, tutoriais, guias
- 🎨 **Design**: UI/UX, branding, materiais de divulgação
- 🐛 **Testes**: Reportar bugs, testar features
- 💡 **Ideias**: Sugerir funcionalidades, melhorias
- 🌍 **Divulgação**: Compartilhar o projeto, recrutar cooperativas

📖 **Leia nosso [guia de contribuição](CONTRIBUTING.md)** para começar

---

## 📄 Licença

Este projeto é licenciado sob a **MIT License** - veja o arquivo [LICENSE](LICENSE) para detalhes.

Isso significa que você pode:
- ✅ Usar comercialmente
- ✅ Modificar o código
- ✅ Distribuir
- ✅ Usar em projetos privados

**A única exigência é manter a atribuição aos autores originais.**

---

## 💬 Sobre o Nome

**"OpenBag"** é um nome sugestivo e **pode ser alterado** conforme o projeto evolui. Estamos abertos a sugestões que reflitam melhor nossa missão cooperativista e social!

Sugestões? Abra uma [discussão](https://github.com/seu-usuario/openbag/discussions) ou [issue](https://github.com/seu-usuario/openbag/issues)!

---

## 📞 Contato & Comunidade

- 🌐 **Website**: [openbag.app](https://openbag.app) _(em construção)_
- 💬 **Discord**: [discord.gg/openbag](#) _(em breve)_
- 📧 **Email**: contato@openbag.app
- 🐦 **Twitter/X**: [@OpenBagApp](#) _(em breve)_
- 📱 **Telegram**: [t.me/openbag](#) _(em breve)_

---

## 🙏 Apoiadores

Este projeto é possível graças ao apoio de:

- Desenvolvedores voluntários
- Cooperativas de entregadores parceiras
- Restaurantes que acreditam em um modelo mais justo
- A comunidade open source

**Quer apoiar o projeto?** Entre em contato ou contribua diretamente no GitHub!

---

<p align="center">
  <strong>Desenvolvido com ❤️ pela comunidade OpenBag</strong><br>
  <em>Porque delivery justo é possível.</em>
</p>

<p align="center">
  <a href="README-DEVELOPER.md">📖 Documentação Técnica</a> •
  <a href="CONTRIBUTING.md">🤝 Como Contribuir</a> •
  <a href="https://github.com/seu-usuario/openbag/issues">🐛 Reportar Bug</a> •
  <a href="https://github.com/seu-usuario/openbag/discussions">💡 Sugerir Feature</a>
</p>

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
