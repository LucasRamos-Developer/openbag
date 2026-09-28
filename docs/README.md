# 📚 Documentação do OpenBag

> Versão da documentação: **0.2.0**, atualizada em 2026-09-27. Veja o que mudou no [CHANGELOG](../CHANGELOG.md).

## 📖 Estrutura da documentação

### 🏠 Geral

- **[README principal](../README.md)**: proposta, telas, roadmap e contato.
- **[CHANGELOG](../CHANGELOG.md)**: histórico de versões, regras do versionamento semântico e roadmap.
- **[Roadmap 0.6.0](roadmap/0.6.0-operacao.md)**: operação do dia a dia, com o estado de cada item e o que falta.
- **[Layout](../layout/)**: todas as capturas de tela da versão atual.
- **[Guia de contribuição](../CONTRIBUTING.md)**: como contribuir com o projeto.

### 🏗️ Arquitetura

- **[Arquitetura](architecture/README.md)**: módulos do backend, ciclo do pedido, tempo real (WebSocket/STOMP), despacho, rotas, caixa, jobs e estrutura do app.

### 🛠️ Desenvolvimento

- **[Guia de desenvolvimento](../README-DEVELOPER.md)**: setup, Docker, variáveis e testes.
- **[Design system](../frontend/lib/core/ui/README.md)**: componentes `App*` e temas do app Flutter.

### 🔌 API

- **[Índice de APIs](api/README.md)**: endpoints REST.
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
│   └── README.md           # Índice de APIs
├── roadmap/
│   └── 0.6.0-operacao.md   # Itens planejados da 0.6.0
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
