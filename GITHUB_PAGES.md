# 🌐 Como Configurar GitHub Pages

Este guia mostra como ativar o GitHub Pages para hospedar gratuitamente a landing page do OpenBag.

## 📋 O Que é GitHub Pages?

GitHub Pages é um serviço gratuito de hospedagem de sites estáticos fornecido pelo GitHub. Perfeito para documentação, landing pages e sites de projetos open source.

**Características:**
- ✅ **Gratuito** para repositórios públicos
- ✅ **HTTPS** automático
- ✅ **Custom domain** suportado
- ✅ **Deploy automático** ao fazer push
- ✅ **Sem limite de visitantes**

---

## 🚀 Passo a Passo: Ativar GitHub Pages

### 1. Acesse as Configurações do Repositório

1. Vá para o repositório no GitHub: `https://github.com/seu-usuario/openbag`
2. Clique em **Settings** (Configurações) no menu superior
3. No menu lateral esquerdo, clique em **Pages**

### 2. Configure a Fonte (Source)

Na seção **Build and deployment**:

1. **Source**: Selecione `Deploy from a branch`
2. **Branch**: 
   - Selecione `main` (ou `master`)
   - Selecione `/docs` como pasta
3. Clique em **Save**

### 3. Aguarde o Deploy

- O GitHub começará a construir e publicar seu site automaticamente
- Isso pode levar de 30 segundos a 2 minutos
- Você verá uma mensagem verde quando estiver pronto: ✅ _"Your site is live at..."_

### 4. Acesse Seu Site

Após o deploy, seu site estará disponível em:

```
https://seu-usuario.github.io/openbag/
```

---

## 🔧 Configuração Avançada

### Custom Domain (Opcional)

Se você tiver um domínio próprio (ex: `openbag.app`):

#### 1. Configure DNS do Seu Domínio

Adicione os seguintes registros DNS:

**Apex domain (openbag.app):**
```
A     185.199.108.153
A     185.199.109.153
A     185.199.110.153
A     185.199.111.153
```

**Subdomain (www.openbag.app):**
```
CNAME    seu-usuario.github.io
```

#### 2. Configure no GitHub Pages

1. Em **Settings > Pages**
2. Em **Custom domain**, digite: `openbag.app` ou `www.openbag.app`
3. Clique em **Save**
4. Aguarde verificação DNS (pode levar até 24h)
5. Marque **Enforce HTTPS** (após verificação)

#### 3. Crie Arquivo CNAME

Crie o arquivo `/docs/CNAME` com o conteúdo:

```
openbag.app
```

Ou via terminal:
```bash
echo "openbag.app" > docs/CNAME
git add docs/CNAME
git commit -m "chore: adiciona domínio customizado para GitHub Pages"
git push
```

---

## 📝 Atualizar URLs no Código

Após configurar o GitHub Pages, **atualize as URLs** nos seguintes arquivos:

### 1. `docs/index.html`

Procure e substitua `seu-usuario` pelo seu username real do GitHub:

```html
<!-- Open Graph / Facebook -->
<meta property="og:url" content="https://SEU-USUARIO.github.io/openbag/">

<!-- Twitter -->
<meta property="twitter:url" content="https://SEU-USUARIO.github.io/openbag/">

<!-- Canonical URL -->
<link rel="canonical" href="https://SEU-USUARIO.github.io/openbag/">

<!-- Links no footer -->
<a href="https://github.com/SEU-USUARIO/openbag">GitHub</a>
```

### 2. `docs/sitemap.xml`

```xml
<url>
  <loc>https://SEU-USUARIO.github.io/openbag/</loc>
  ...
</url>
```

### 3. `docs/robots.txt`

```
Sitemap: https://SEU-USUARIO.github.io/openbag/sitemap.xml
```

### 4. `README.md`

```markdown
- 🌐 **Website**: [openbag.app](https://SEU-USUARIO.github.io/openbag/)
```

---

## 🎨 Adicionar Imagens (Opcional)

Para melhorar o SEO e compartilhamento em redes sociais, adicione imagens:

### 1. Crie as Imagens

Crie imagens com as seguintes dimensões:

- **og-image.png**: 1200x630px (Open Graph - Facebook, LinkedIn)
- **twitter-image.png**: 1200x600px (Twitter Card)
- **favicon.png**: 32x32px (ícone do navegador)
- **logo.png**: 512x512px (logo principal)

### 2. Salve na Pasta Assets

```bash
mkdir -p docs/assets
# Copie suas imagens para docs/assets/
```

### 3. Atualize Referências no HTML

```html
<!-- Favicon -->
<link rel="icon" type="image/png" sizes="32x32" href="assets/favicon.png">

<!-- Open Graph -->
<meta property="og:image" content="https://seu-usuario.github.io/openbag/assets/og-image.png">

<!-- Twitter -->
<meta property="twitter:image" content="https://seu-usuario.github.io/openbag/assets/twitter-image.png">
```

---

## 🔍 Otimização de SEO

### Google Search Console

1. Acesse [Google Search Console](https://search.google.com/search-console)
2. Adicione propriedade: `https://seu-usuario.github.io/openbag/`
3. Verifique propriedade (método HTML tag ou arquivo)
4. Envie o sitemap: `https://seu-usuario.github.io/openbag/sitemap.xml`

### Google Analytics (Opcional)

1. Crie conta em [Google Analytics](https://analytics.google.com)
2. Crie propriedade para seu site
3. Copie o Measurement ID (ex: `G-XXXXXXXXXX`)
4. Descomente e configure no `docs/index.html`:

```html
<!-- Google Analytics -->
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', 'G-XXXXXXXXXX');
</script>
```

---

## 🧪 Testar Localmente Antes de Publicar

Para testar a landing page localmente antes de fazer push:

### Opção 1: Python Simple Server

```bash
cd docs
python3 -m http.server 8000
# Acesse: http://localhost:8000
```

### Opção 2: Node.js http-server

```bash
npm install -g http-server
cd docs
http-server -p 8000
# Acesse: http://localhost:8000
```

### Opção 3: VS Code Live Server

1. Instale extensão "Live Server"
2. Abra `docs/index.html`
3. Clique com botão direito > "Open with Live Server"

---

## 🐛 Troubleshooting

### Site não aparece / Erro 404

**Soluções:**
1. Verifique se a branch está correta (`main` ou `master`)
2. Confirme que selecionou `/docs` como pasta
3. Aguarde 2-5 minutos para propagação
4. Limpe cache do navegador (Ctrl+Shift+R)
5. Verifique **Actions** tab no GitHub para erros de build

### CSS/Imagens não carregam

**Causa:** Caminhos relativos incorretos

**Solução:** Use caminhos relativos sem `/` no início:

```html
<!-- ❌ Errado -->
<link href="/style.css" rel="stylesheet">

<!-- ✅ Correto -->
<link href="style.css" rel="stylesheet">
<link href="assets/logo.png">
```

### Custom domain não funciona

**Verificar:**
1. DNS propagou? Use [whatsmydns.net](https://www.whatsmydns.net/)
2. Arquivo `CNAME` existe em `/docs/`?
3. HTTPS enforcement desabilitado temporariamente?
4. Aguarde até 24h para propagação DNS completa

### Mudanças não aparecem

**Soluções:**
1. Confirme que fez commit e push
2. Aguarde 1-2 minutos para rebuild
3. Force refresh: Ctrl+Shift+R (Windows/Linux) ou Cmd+Shift+R (Mac)
4. Verifique tab **Actions** para status do deploy

---

## 📊 Monitoramento de Performance

### Lighthouse (Google Chrome)

1. Abra seu site no Chrome
2. Pressione F12 (DevTools)
3. Vá para tab **Lighthouse**
4. Clique em **Analyze page load**

**Metas:**
- ✅ Performance: 90+
- ✅ Accessibility: 90+
- ✅ Best Practices: 90+
- ✅ SEO: 90+

### PageSpeed Insights

1. Acesse [PageSpeed Insights](https://pagespeed.web.dev/)
2. Cole URL: `https://seu-usuario.github.io/openbag/`
3. Analise sugestões de otimização

---

## 🔄 Deploy Automático

Toda vez que você fizer push para a branch `main` (na pasta `/docs`), o GitHub Pages:

1. Detecta mudanças automaticamente
2. Rebuilda o site
3. Publica a nova versão
4. Geralmente leva 30-90 segundos

**Acompanhe deploys:**
- Vá para tab **Actions** no repositório
- Veja status de cada deploy
- Em caso de erro, veja logs detalhados

---

## 📚 Recursos Adicionais

- [Documentação Oficial GitHub Pages](https://docs.github.com/pages)
- [Custom Domain Setup](https://docs.github.com/pages/configuring-a-custom-domain-for-your-github-pages-site)
- [Troubleshooting Guide](https://docs.github.com/pages/getting-started-with-github-pages/troubleshooting-github-pages-builds)
- [Jekyll (gerador estático)](https://jekyllrb.com/) - opcional

---

## ✅ Checklist Final

Antes de considerar o setup completo:

- [ ] GitHub Pages ativado (Settings > Pages)
- [ ] Site acessível em `https://seu-usuario.github.io/openbag/`
- [ ] Todas URLs atualizadas (substitua `seu-usuario`)
- [ ] Imagens og:image e favicon adicionadas (opcional)
- [ ] Lighthouse score 90+ em todas categorias
- [ ] Sitemap enviado ao Google Search Console (opcional)
- [ ] Custom domain configurado (se aplicável)
- [ ] HTTPS enforcement habilitado
- [ ] Testado em mobile e desktop
- [ ] Compartilhamento em redes sociais funcionando

---

## 🎉 Pronto!

Seu site agora está no ar! Compartilhe com o mundo:

```
🌐 https://seu-usuario.github.io/openbag/
```

**Próximos passos:**
1. Compartilhe nas redes sociais
2. Adicione ao README.md do projeto
3. Monitore analytics (se configurado)
4. Mantenha conteúdo atualizado

---

<p align="center">
  <strong>Desenvolvido com ❤️ pela comunidade OpenBag</strong>
</p>
