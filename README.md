# OpenBag

> **Uma plataforma open source de delivery que conecta associações e cooperativas de entregadores com restaurantes, promovendo taxas justas e impacto social positivo.**

---

## Nossa Missão

O OpenBag nasceu para **combater o monopólio** das grandes plataformas de delivery e oferecer uma alternativa justa, transparente e socialmente responsável.

### O Problema

Grandes empresas dominam o mercado de delivery e implementam taxas abusivas sem transparência:

- **Taxas elevadas** que sufocam restaurantes pequenos e médios
- **Comissões que chegam a 30%** sobre cada pedido
- **Mudanças unilaterais** de regras e preços (exemplo: taxa implementada sem aviso)
- **Falta de proteção social** para entregadores autônomos
- **Centralização de lucros** em detrimento de quem realmente trabalha

### Nossa Solução

O OpenBag propõe um modelo **justo, transparente e cooperativo**:

| Característica | Similares | OpenBag |
|---------------|-------------------|---------|
| **Comissão** | Até 30% por pedido | Taxa fixa de R$ 3,98 por pedido |
| **Transparência** | Mudanças unilaterais | Open source, auditável |
| **Proteção Social** | Nenhuma | Modelo cooperativo viabiliza benefícios |
| **Quem lucra?** | Acionistas | Restaurantes e entregadores |
| **Controle** | Centralizado | Descentralizado (cooperativas) |

**Como funciona a nossa taxa de R$ 3,98:**
- **R$ 1,99 cobrado do Restaurante:** Valor destinado a manter a infraestrutura técnica do OpenBag rodando.
- **R$ 1,99 cobrado do Entregador/Cooperativa:** A plataforma não lucra com isso. Esse valor é repassado integralmente para a cooperativa, que terá acesso a esse fundo exclusivo para dar suporte, proteção e benefícios ao seu entregador cooperado.

O resto do valor do pedido e da entrega é todo de quem trabalha. Diferente de modelos que cobram um percentual alto, nossa taxa fixa garante que o lucro real fique com os restaurantes e entregadores, reduzindo os custos até mesmo para o consumidor final.

---

## Impacto Social

O OpenBag foi pensado para fortalecer **associações e cooperativas de entregadores**. Diferente de plataformas que trabalham com autônomos isolados, **exigimos que entregadores sejam vinculados a uma cooperativa ou associação**.

### Por Que Apenas Cooperativas?

O modelo cooperativo permite que aquele repasse de R$ 1,99 da entrega seja administrado de forma coletiva para oferecer:

- **Seguro de vida e acidentes pessoais** para os membros  
- **Planos de previdência e aposentadoria** coletivos  
- **Suporte jurídico** compartilhado  
- **Capacitação e treinamento** profissional  
- **Representação coletiva** e voz ativa  
- **Gestão democrática** das decisões

Nota: A plataforma não fornece esses serviços diretamente, ela viabiliza financeiramente para que as cooperativas possam oferecê-los aos seus associados. A cooperativa também é livre para definir taxas adicionais se os membros concordarem.

### Para Restaurantes

- **Custos previsíveis:** sem surpresas de comissões variáveis.
- **Maior margem de lucro** por pedido.
- **Controle sobre seus dados** e de seus clientes.
- **Parcerias locais** com cooperativas da região.
- **Visibilidade justa:** sem leilão de posições no aplicativo.

### Para Consumidores

- **Preços mais baixos:** a redução da intermediação barateia o cardápio.
- **Transparência total** sobre quem está recebendo as taxas.
- **Apoio à economia local** e ao cooperativismo.
- **Contribuição para direitos trabalhistas** dos entregadores.

---

## Como Funciona

### 1. Restaurante se cadastra na plataforma
Processo simples e gratuito, sem burocracias desnecessárias.

### 2. Cooperativa de entregadores faz parceria
Associações e cooperativas locais se cadastram e conectam aos restaurantes da região.

### 3. Cliente faz pedido pelo app
Interface simples e intuitiva, via web ou mobile.

### 4. Entregador associado realiza a entrega
O entregador vinculado à cooperativa aceita e entrega usando rotas otimizadas (via OpenStreetMap).

### 5. Taxas transparentes beneficiam todos
- **R$ 1,99** do restaurante (manutenção da plataforma OpenBag).
- **R$ 1,99** do entregador (repassado para a cooperativa dar suporte ao cooperado).
- **Todo o resto** fica com quem trabalhou (restaurante e entregador).

---

## Para Desenvolvedores

Toda a parte técnica, arquitetura detalhada (Flutter, Spring Boot, PostgreSQL, Docker) e o guia completo para rodar o projeto localmente foram documentados separadamente para manter este repositório limpo.

**Consulte o [Guia de Desenvolvimento (README-DEVELOPER.md)](README-DEVELOPER.md)** para instruções de setup, variáveis de ambiente e padrões de código.

### Para Usuários (em breve)

- **App Android**: Google Play Store (em desenvolvimento)
- **App iOS**: Apple App Store (em desenvolvimento)
- **Web**: https://openbag.app (em desenvolvimento)

---

## Roadmap

### Fase 1 - MVP (Atual)
- [x] Cadastro de restaurantes
- [x] Cadastro de clientes
- [x] Carrinho de compras
- [x] Sistema de pedidos
- [x] Integração com OpenStreetMap
- [x] Autenticação JWT

### Fase 2 - Cooperativas (Q2 2026)
- [ ] Painel de gestão para cooperativas
- [ ] Sistema de alocação de entregas
- [ ] Relatórios financeiros
- [ ] Integração com sistemas de pagamento
- [ ] Dashboard de métricas sociais

### Fase 3 - Expansão (Q3 2026)
- [ ] App nativo para entregadores
- [ ] Sistema de avaliações
- [ ] Programa de fidelidade
- [ ] Multi-idiomas
- [ ] Expansão para outras cidades

### Fase 4 - Governança (Q4 2026)
- [ ] DAO (Organização Autônoma Descentralizada)
- [ ] Votação democrática de features
- [ ] Modelo de franquia cooperativa
- [ ] Federação de cooperativas

---

## Como Contribuir

O OpenBag é **100% open source** e depende da comunidade!

### Formas de Contribuir

- **Código**: Backend (Java), Frontend (Flutter), DevOps
- **Documentação**: Tradução, tutoriais, guias
- **Design**: UI/UX, branding, materiais de divulgação
- **Testes**: Reportar bugs, testar features
- **Ideias**: Sugerir funcionalidades, melhorias
- **Divulgação**: Compartilhar o projeto, recrutar cooperativas

**Leia nosso [guia de contribuição](CONTRIBUTING.md)** para começar.

1. Faça um Fork do projeto
2. Crie uma branch (`git checkout -b feature/nova-funcionalidade`)
3. Faça o Commit de suas mudanças (`git commit -am 'Adiciona nova funcionalidade'`)
4. Faça o Push para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request

---

## Licença

Este projeto é licenciado sob a **AGPL-3.0 License** - veja o arquivo [LICENSE](LICENSE) para detalhes.

Escolhemos a AGPL-3.0 por ser uma licença **mais forte que protege contra uso em SaaS** sem o compartilhamento do código-fonte. Isso significa que é permitido:

- Usar comercialmente
- Modificar o código
- Distribuir
- Usar em projetos privados

**Aviso Importante:** Se você modificar o código e usar a plataforma como um serviço (SaaS) na rede, você é obrigado a disponibilizar o código-fonte das suas modificações. Isso garante que o OpenBag permaneça sempre aberto e beneficie toda a comunidade.

---

## Equipe

- **Desenvolvedor Principal**: Lucas Ramos
- **Contribuidores**: [Lista de contribuidores]

---

## Sobre o Nome

**"OpenBag"** é um nome **provisório** e estamos totalmente abertos a sugestões que reflitam melhor nossa missão cooperativista e social!

**Dúvidas e questões?** Entre em contato através:
- Email: contato@openbag.dev ou lucasramos-developer@gmail.com
- [Discussões no GitHub](https://github.com/LucasRamos-Developer/openbag/discussions)
- [Issues no GitHub](https://github.com/LucasRamos-Developer/openbag/issues)

## Apoiadores

Este projeto é possível graças ao apoio de:

- Desenvolvedores voluntários
- Cooperativas de entregadores parceiras
- Restaurantes que acreditam em um modelo mais justo
- A comunidade open source

**Quer apoiar o projeto?** Entre em contato ou contribua diretamente no GitHub!

---

Desenvolvido pela comunidade OpenBag.
Porque delivery justo é possível.

[Documentação Técnica](README-DEVELOPER.md) | [Como Contribuir](CONTRIBUTING.md) | [Reportar Bug](https://github.com/LucasRamos-Developer/openbag/issues) | [Sugerir Feature](https://github.com/LucasRamos-Developer/openbag/discussions)