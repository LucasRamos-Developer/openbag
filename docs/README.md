# 📚 Documentação do OpenBag

> Versão da documentação: **0.4.0**, atualizada em 2026-09-29. Veja o que mudou no [CHANGELOG](../CHANGELOG.md).
>
> **Em andamento:** a 0.5.0 (operação do dia a dia), em cinco entregas pequenas. As ocorrências, os km, tempo e médias e o custo estimado do veículo estão prontos; a próxima são os comunicados da cooperativa. O resumo está na seção [Versões e roadmap](../README.md#versões-e-roadmap) do README.

## 📖 Estrutura da documentação

### 🏠 Geral

- **[README principal](../README.md)**: proposta, telas, roadmap e contato.
- **[CHANGELOG](../CHANGELOG.md)**: histórico de versões, regras do versionamento semântico e roadmap.
- **[Roadmap 0.4.0](roadmap/0.4.0-seguranca.md)**: segurança e integridade dos dados. Foi lançada, com o que foi feito em cada item, o checklist do OWASP Top 10 e o que ficou para depois.
- **[Roadmap 0.5.0](roadmap/0.5.0-operacao.md)**: operação do dia a dia, a próxima versão, com o estado de cada item, o que falta e o que ficou para depois da 1.0.
- **[Layout](../layout/)**: todas as capturas de tela da versão atual.
- **[Guia de contribuição](../CONTRIBUTING.md)**: como contribuir com o projeto.

### 🏗️ Arquitetura

- **[Arquitetura](architecture/README.md)**: módulos do backend, ciclo do pedido, tempo real (WebSocket/STOMP), segurança, despacho, rotas, caixa, jobs, dados (Flyway, ações simultâneas, idempotência) e estrutura do app.

### 🛠️ Desenvolvimento

- **[Guia de desenvolvimento](../README-DEVELOPER.md)**: setup, Docker, variáveis (desenvolvimento e produção), limite de requisições, migrações e testes.
- **[Design system](../frontend/lib/core/ui/README.md)**: componentes `App*` e temas do app Flutter.

### 🔌 API

- **[API REST](api/README.md)**: rotas por área, cabeçalhos (`Idempotency-Key`, `Retry-After`), WebSocket e formato dos erros.
- **[Onboarding de restaurante](../backend/docs/onboarding-restaurante.md)**: cadastro completo de restaurantes.
- **Swagger UI** (local): http://localhost:8080/api/swagger-ui.html. É a lista sempre atualizada.

### 📘 Guias técnicos

- **[OpenStreetMap](guides/openstreetmap.md)**: mapas sem Google Maps.

### 🌐 Site (GitHub Pages)

- **[index.html](index.html)**: página do projeto, publicada em https://lucasramos-developer.github.io/openbag/
- **[assets/screens/](assets/screens/)**: cópias otimizadas das telas usadas no site. O GitHub Pages só serve a pasta `docs/`, por isso as imagens de `layout/` são copiadas para cá.
- **[sitemap.xml](sitemap.xml)** e **[robots.txt](robots.txt)**: indexação.

---

## 📁 Organização dos arquivos

```
docs/
├── index.html              # Site (GitHub Pages)
├── assets/
│   ├── og-image.jpg        # Imagem de compartilhamento
│   └── screens/            # Telas usadas no site
├── sitemap.xml
├── robots.txt
├── README.md               # Este arquivo
├── architecture/
│   └── README.md           # Arquitetura do sistema
├── api/
│   └── README.md           # API REST
├── roadmap/
│   ├── 0.4.0-seguranca.md  # 0.4.0: segurança e integridade (lançada)
│   └── 0.5.0-operacao.md   # 0.5.0: operação do dia a dia (próxima)
└── guides/
    └── openstreetmap.md
```

---

## 🔖 Versionamento da documentação

A documentação acompanha a versão do sistema:

1. Toda mudança relevante entra em **Não lançado** no [CHANGELOG](../CHANGELOG.md).
2. Ao fechar uma versão, atualize a linha "Versão da documentação" no topo deste arquivo, do [README](../README.md) e da [arquitetura](architecture/README.md), além do selo de versão no [site](index.html).
3. Se as telas mudaram, atualize as capturas em `layout/` e as cópias em `docs/assets/screens/`.

Use o tipo de commit `docs:` para mudanças só de documentação:

```bash
git commit -m "docs(arquitetura): descreve o fluxo de rotas"
```

---

## 📬 Contato

Quer saber mais? Escreva para [lucasramos.developer@gmail.com](mailto:lucasramos.developer@gmail.com) ou abra uma [discussão no GitHub](https://github.com/LucasRamos-Developer/openbag/discussions).
