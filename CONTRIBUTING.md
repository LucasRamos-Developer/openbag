# 🤝 Guia de Contribuição

Obrigado por considerar contribuir com o OpenBag! Este projeto é construído pela comunidade e para a comunidade. Toda ajuda é bem-vinda!

## 📋 Índice

- [Como Posso Contribuir?](#como-posso-contribuir)
- [Configurando o Ambiente de Desenvolvimento](#configurando-o-ambiente-de-desenvolvimento)
- [Workflow de Contribuição](#workflow-de-contribuição)
- [Padrões de Código](#padrões-de-código)
- [Convenções de Commit](#convenções-de-commit)
- [Pull Requests](#pull-requests)
- [Reportando Bugs](#reportando-bugs)
- [Sugerindo Melhorias](#sugerindo-melhorias)
- [Código de Conduta](#código-de-conduta)

---

## 💡 Como Posso Contribuir?

Existem muitas formas de contribuir com o OpenBag, mesmo sem escrever código:

### 1. 💻 Código

- **Backend (Java/Spring Boot)**: Implementar features, corrigir bugs, melhorar performance
- **Frontend (Flutter)**: Desenvolver UI/UX, adicionar features mobile/web
- **DevOps**: Melhorar Docker, CI/CD, deployment
- **Testes**: Escrever testes unitários, integração, end-to-end

### 2. 📝 Documentação

- Melhorar README e documentação técnica
- Criar tutoriais e guias
- Traduzir documentação para outros idiomas
- Documentar APIs e endpoints

### 3. 🎨 Design

- Criar mockups de UI/UX
- Desenvolver identidade visual
- Criar materiais de divulgação
- Melhorar acessibilidade

### 4. 🐛 Qualidade

- Reportar bugs com detalhes
- Testar features novas
- Revisar Pull Requests
- Sugerir melhorias de UX

### 5. 🌍 Comunidade

- Ajudar outros contribuidores
- Responder perguntas nas Issues/Discussions
- Divulgar o projeto
- Recrutar cooperativas e restaurantes

---

## 🔧 Configurando o Ambiente de Desenvolvimento

### Pré-requisitos

Certifique-se de ter instalado:

- **Java 21+** (JDK)
- **Maven 3.6+**
- **Flutter 3.16+**
- **Docker & Docker Compose**
- **Git**

### Passo a Passo

#### 1. Fork do Repositório

Clique em "Fork" no topo da [página do projeto](https://github.com/seu-usuario/openbag).

#### 2. Clone Seu Fork

```bash
# Substitua SEU-USUARIO pelo seu username do GitHub
git clone https://github.com/SEU-USUARIO/openbag.git
cd openbag
```

#### 3. Adicione o Remote Upstream

```bash
git remote add upstream https://github.com/seu-usuario/openbag.git
```

#### 4. Configure o Ambiente

```bash
# Subir serviços (PostgreSQL, Redis, Elasticsearch, Kibana)
docker compose up -d

# Em um terminal: Rodar backend
cd backend
mvn spring-boot:run

# Em outro terminal: Rodar frontend
cd frontend
flutter pub get
flutter run -d chrome
```

#### 5. Verificar Instalação

- Backend: http://localhost:8080
- Frontend: http://localhost:**** (porta varia)
- Swagger: http://localhost:8080/swagger-ui.html

### Documentação Completa

Para instruções detalhadas de setup, consulte [README-DEVELOPER.md](README-DEVELOPER.md).

---

## 🔄 Workflow de Contribuição

### 1. Sincronize Seu Fork

Antes de começar a trabalhar, sincronize com o repositório principal:

```bash
git checkout main
git fetch upstream
git merge upstream/main
git push origin main
```

### 2. Crie uma Branch

Sempre crie uma branch para sua feature/fix:

```bash
# Para features
git checkout -b feature/nome-da-feature

# Para correções
git checkout -b fix/descricao-do-bug

# Para documentação
git checkout -b docs/descricao-da-alteracao
```

**Convenção de nomes de branch:**

- `feature/` - Nova funcionalidade
- `fix/` - Correção de bug
- `docs/` - Documentação
- `refactor/` - Refatoração de código
- `test/` - Adição ou correção de testes
- `chore/` - Tarefas de manutenção

### 3. Faça Suas Alterações

Desenvolva sua feature ou correção. Lembre-se de:

- ✅ Seguir os padrões de código
- ✅ Escrever testes
- ✅ Documentar código complexo
- ✅ Testar localmente

### 4. Commit Suas Mudanças

Faça commits atômicos e descritivos (veja [Convenções de Commit](#convenções-de-commit)):

```bash
git add .
git commit -m "feat: adiciona busca de restaurantes por categoria"
```

### 5. Push Para Seu Fork

```bash
git push origin feature/nome-da-feature
```

### 6. Abra um Pull Request

1. Vá para seu fork no GitHub
2. Clique em "Compare & pull request"
3. Preencha o template de PR
4. Aguarde review

---

## 📐 Padrões de Código

### Java (Backend)

- **Estilo**: [Google Java Style Guide](https://google.github.io/styleguide/javaguide.html)
- **Formatter**: IntelliJ IDEA / Eclipse default
- **Lint**: Checkstyle configurado no Maven

```bash
# Verificar estilo
mvn checkstyle:check

# Formatar código (IntelliJ)
Ctrl+Alt+L (Windows/Linux)
Cmd+Option+L (macOS)
```

**Boas práticas:**

- Use nomes descritivos para variáveis e métodos
- Evite métodos com mais de 50 linhas
- Mantenha classes com responsabilidade única (SRP)
- Use `Optional` para valores que podem ser nulos
- Documente métodos públicos com JavaDoc

**Exemplo:**

```java
/**
 * Busca restaurantes por categoria e localização.
 *
 * @param category Categoria do restaurante (ex: "pizza", "japonês")
 * @param latitude Latitude do usuário
 * @param longitude Longitude do usuário
 * @param radiusKm Raio de busca em quilômetros
 * @return Lista de restaurantes encontrados
 */
public List<Restaurant> findByCategory(
    String category,
    double latitude,
    double longitude,
    int radiusKm
) {
    // Implementação
}
```

### Dart/Flutter (Frontend)

- **Estilo**: [Effective Dart](https://dart.dev/guides/language/effective-dart)
- **Formatter**: `dart format`
- **Lint**: `flutter analyze`

```bash
# Formatar código
dart format lib/

# Analisar código
flutter analyze

# Corrigir problemas automaticamente
dart fix --apply
```

**Boas práticas:**

- Use `const` quando possível
- Extraia widgets complexos em widgets separados
- Use `Provider` para state management
- Nomeie widgets de forma descritiva
- Documente widgets públicos

**Exemplo:**

```dart
/// Widget que exibe card de restaurante com imagem, nome e avaliação.
///
/// Exemplo:
/// ```dart
/// RestaurantCard(
///   restaurant: myRestaurant,
///   onTap: () => navigateToDetails(),
/// )
/// ```
class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final VoidCallback? onTap;

  const RestaurantCard({
    Key? key,
    required this.restaurant,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Implementação
  }
}
```

---

## 📝 Convenções de Commit

Usamos [Conventional Commits](https://www.conventionalcommits.org/) para mensagens de commit consistentes e automatização de changelogs.

### Formato

```
<tipo>(<escopo>): <descrição>

[corpo opcional]

[rodapé opcional]
```

### Tipos

| Tipo | Descrição | Exemplo |
|------|-----------|---------|
| `feat` | Nova funcionalidade | `feat(auth): adiciona login com Google` |
| `fix` | Correção de bug | `fix(cart): corrige cálculo de total` |
| `docs` | Documentação | `docs(readme): atualiza instruções de setup` |
| `style` | Formatação (sem mudança de lógica) | `style(backend): formata código com checkstyle` |
| `refactor` | Refatoração | `refactor(services): simplifica lógica de busca` |
| `test` | Testes | `test(auth): adiciona testes de login` |
| `chore` | Manutenção | `chore(deps): atualiza dependências` |
| `perf` | Performance | `perf(db): otimiza query de restaurantes` |
| `ci` | CI/CD | `ci: adiciona workflow de deploy` |

### Exemplos

```bash
# Feature simples
git commit -m "feat: adiciona filtro por preço"

# Bug fix com contexto
git commit -m "fix(payment): corrige erro ao processar pagamento com cartão"

# Breaking change
git commit -m "feat(api): altera estrutura de response de pedidos

BREAKING CHANGE: campo 'items' agora é 'orderItems'"

# Com issue relacionada
git commit -m "fix: resolve erro de timeout no checkout

Closes #123"
```

### Regras

- ✅ Use verbos no infinitivo ("adiciona", não "adicionado")
- ✅ Primeira letra minúscula (exceto nomes próprios)
- ✅ Não use ponto final
- ✅ Limite a primeira linha a 72 caracteres
- ✅ Referencie issues quando aplicável (`Closes #123`)

---

## 🔍 Pull Requests

### Antes de Abrir

- [ ] Código segue os padrões de estilo
- [ ] Todos os testes passam (`mvn test` e `flutter test`)
- [ ] Novos testes foram adicionados para novas features
- [ ] Documentação foi atualizada (se necessário)
- [ ] Commits seguem Conventional Commits
- [ ] Branch está atualizada com `main`

### Template de PR

Ao abrir um PR, preencha as seguintes seções:

```markdown
## Descrição
[Descreva o que este PR faz]

## Tipo de Mudança
- [ ] Bug fix
- [ ] Nova feature
- [ ] Breaking change
- [ ] Documentação

## Como Testar
[Passos para testar as mudanças]

## Checklist
- [ ] Testes passam localmente
- [ ] Código segue padrões de estilo
- [ ] Documentação atualizada
- [ ] Sem breaking changes (ou documentadas)

## Issues Relacionadas
Closes #[número da issue]
```

### Review Process

1. **Automated Checks**: CI roda testes automaticamente
2. **Code Review**: Pelo menos 1 aprovação necessária
3. **Discussão**: Responda comentários e faça ajustes
4. **Merge**: Após aprovação, mantenedor fará merge

### Após o Merge

- Seu PR será incluído no próximo release
- Você será adicionado aos contribuidores
- Obrigado por contribuir! 🎉

---

## 🐛 Reportando Bugs

### Antes de Reportar

1. Verifique se já existe uma issue similar
2. Atualize para a versão mais recente
3. Confirme que é realmente um bug

### Como Reportar

Abra uma [nova issue](https://github.com/seu-usuario/openbag/issues/new) com:

**Template:**

```markdown
## Descrição do Bug
[Descrição clara do problema]

## Para Reproduzir
1. Vá para '...'
2. Clique em '...'
3. Role até '...'
4. Veja o erro

## Comportamento Esperado
[O que deveria acontecer]

## Screenshots
[Se aplicável]

## Ambiente
- OS: [ex: Ubuntu 22.04]
- Navegador: [ex: Chrome 120]
- Versão: [ex: v1.0.0]

## Logs/Erros
```
[Cole logs relevantes]
```

## Contexto Adicional
[Qualquer outra informação]
```

---

## 💡 Sugerindo Melhorias

### Feature Requests

Abra uma [discussion](https://github.com/seu-usuario/openbag/discussions) ou [issue](https://github.com/seu-usuario/openbag/issues) com:

```markdown
## Problema que Resolve
[Que problema esta feature resolve?]

## Solução Proposta
[Como você imagina que funcione?]

## Alternativas Consideradas
[Outras soluções que pensou?]

## Impacto
- [ ] Usuários finais
- [ ] Desenvolvedores
- [ ] Cooperativas
- [ ] Restaurantes

## Mockups/Exemplos
[Se tiver, adicione imagens ou exemplos]
```

---

## 📜 Código de Conduta

### Nosso Compromisso

O OpenBag se compromete a fornecer um ambiente acolhedor e respeitoso para todos, independentemente de:

- Identidade de gênero e expressão
- Orientação sexual
- Deficiência
- Aparência física
- Raça, etnia e nacionalidade
- Idade, religião ou nível de experiência

### Comportamentos Esperados

✅ **Seja respeitoso** - Trate todos com respeito e empatia  
✅ **Seja colaborativo** - Trabalhe junto, não contra  
✅ **Seja construtivo** - Críticas devem ser construtivas  
✅ **Seja paciente** - Nem todos têm o mesmo nível de experiência  
✅ **Seja inclusivo** - Use linguagem acolhedora

### Comportamentos Inaceitáveis

❌ Assédio, intimidação ou discriminação  
❌ Linguagem ofensiva ou excludente  
❌ Ataques pessoais ou políticos  
❌ Publicar informações privadas de outros  
❌ Trolling ou comentários depreciativos

### Aplicação

Violações podem resultar em:

1. Aviso formal
2. Banimento temporário
3. Banimento permanente

Reporte comportamentos inadequados para: **conduct@openbag.app**

---

## 🎓 Recursos para Iniciantes

### Nunca Contribuiu com Open Source?

- [How to Contribute to Open Source](https://opensource.guide/how-to-contribute/)
- [First Contributions](https://github.com/firstcontributions/first-contributions)
- [Good First Issues](https://github.com/seu-usuario/openbag/labels/good%20first%20issue)

### Aprendendo as Tecnologias

- **Java/Spring Boot**: [Spring Guides](https://spring.io/guides)
- **Flutter**: [Flutter Codelabs](https://docs.flutter.dev/codelabs)
- **Git**: [Git Handbook](https://guides.github.com/introduction/git-handbook/)
- **Docker**: [Docker Get Started](https://docs.docker.com/get-started/)

---

## 🙏 Agradecimentos

Obrigado por dedicar seu tempo para contribuir com o OpenBag! Cada contribuição, por menor que seja, ajuda a construir uma plataforma de delivery mais justa e cooperativa.

**Juntos, podemos fazer a diferença!** 🚀

---

## 📞 Precisa de Ajuda?

- 💬 [GitHub Discussions](https://github.com/seu-usuario/openbag/discussions)
- 🐛 [Issues](https://github.com/seu-usuario/openbag/issues)
- 📧 Email: dev@openbag.app
- 📖 [Documentação Técnica](README-DEVELOPER.md)

---

<p align="center">
  <strong>Desenvolvido com ❤️ pela comunidade OpenBag</strong>
</p>
