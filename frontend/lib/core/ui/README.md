# Core UI Components

Sistema de componentes reutilizáveis baseado no design MUI Minimal.

## 🧭 Linguagem visual padrão

**Referência:** [`layout/restaurante-padrão.png`](../../../../layout/restaurante-padrão.png). Toda tela nova (e toda tela redesenhada) segue esse estilo. Os prints da página do restaurante em cada tema ficam em [`layout/temas/`](../../../../layout/temas/).

**Inspiração de UX/UI:** [minimals.cc](https://minimals.cc/). Vale para os cards limpos, o respiro entre blocos, a hierarquia da tipografia e os painéis com números. É só uma inspiração: quando os dois divergem, o padrão desta seção vence.

### Mobile first

Toda tela é pensada primeiro para o celular e depois cresce para tablet e desktop.

- Desenhe e confira a tela em **375px** de largura antes de olhar no desktop. Ela vai até 1200px (`AppLayout.maxContentWidth`).
- A área de toque tem no mínimo **48px**. A ação principal fica ao alcance do polegar: no rodapé do card ou da tela, e não escondida num canto do topo.
- Nenhuma ação depende só de hover, e a página nunca rola na horizontal. Tabelas largas viram lista de cards no celular.
- Colunas lado a lado empilham na largura pequena ([AppResponsiveRow](#appresponsiverow)).

### Tokens de cor (`AppThemeColors`)

Nunca use `Colors.x` ou `AppColors.x` fixos em tela nova; leia os tokens com `context.appColors`.

| Token | Uso |
|---|---|
| `background` | fundo da página |
| `surface` / `surfaceAlt` | cards / campos, placeholders, skeleton |
| `text` / `textMuted` | títulos e nomes / descrições e metadados |
| `primary` | cor da marca: degradês, ícones, destaques |
| `action` + `onAction` | preenchimento de botões e chips ativos + texto sobre eles |
| `primaryText` | preço, links e textos na cor da marca |
| `secondary` + `onSecondary` | selos e áreas suaves + texto sobre eles |
| `accent` | detalhes (sublinhado do banner, selo "Novo") |
| `border`, `cardShadow` | borda e sombra dos cards |
| `success`, `danger`, `rating` | **semânticas fixas**: status aberto/fechado e estrela, nunca mudam com a marca |

`action`, `primaryText` e `onSecondary` são derivados com contraste WCAG AA garantido (teste em `test/core/ui/app_theme_colors_test.dart`), inclusive quando o restaurante usa a própria cor da marca.

### Temas (`AppThemePreset`)

Fresh Green (padrão do app), Sunset Orange, Berry Pink, Ocean Blue, Grape Purple e os escuros Midnight Green, Midnight Blue e Graphite. O app inteiro usa `AppTheme.light` (Fresh Green); a página do restaurante aplica o tema do dono com `RestaurantThemeScope`, que faz `Theme(data: AppTheme.fromColors(...))`.

### Forma e tipografia

- Fonte **Plus Jakarta Sans** (400 a 800). Títulos de página e de seção usam peso 800.
- Raios (`AppRadius`): 8 pequenos, 12 botões e campos, 16 cards, 24 banner e bottom sheets, pílula em busca, chips e selos.
- Cards: `surface`, borda `border` de 1px e `cardShadow` (no tema escuro, só a borda).
- Espaçamento: 12 entre cards, 24–28 antes de cada seção, gutter de 24 no desktop e 12 no celular. Conteúdo com largura máxima de 1180.

### Blocos do padrão

| Bloco | Componente |
|---|---|
| Banner com degradê, título e subtítulo | `AppHeroBanner` |
| Card de informações sobreposto | `RestaurantHeader` / `RestaurantInfoCard` (widgets/restaurant) |
| Metadados com ícone e separador | `AppMetaItem` + `AppMetaRow` |
| Busca em pílula | `AppSearchBar` |
| Chips com ícone (ativo preenchido com ✓) | `AppFilterChips` + `SelectItem.icon` |
| Título de seção com ícone | `AppSectionHeader(leadingIcon: ...)` |
| Selos | `AppBadge` (tons primary, accent, danger, neutral) |
| Card de produto | `MenuProductCard` (widgets/menu) |
| Carregamento | `AppSkeleton` + `AppSkeleton.group` |
| Bloco de configuração dos painéis | `AppPanelCard` |
| Menu lateral dos painéis + troca de perfil | `AppPanelScaffold` + `AppPanelProfileHeader` |
| Etiquetas com limite e sugestões | `AppTagField` |
| Cor | `AppColorField` |
| Largura padrão do conteúdo (1200px) | `AppLayout` + `AppPageListView` / `AppPageContainer` |
| Grade de cards (até 4 colunas) | `AppResponsiveGrid` |
| Barra horizontal de vidro da vitrine | `AppTopNavBar` (+ `StorefrontScaffold` em widgets/navigation) |
| Situação no menu do painel (aberta, online...) | `AppPanelStatus` |

## 📦 Componentes Disponíveis

### AppTextField
Campo de texto com suporte a múltiplas variantes e tamanhos.

**Variantes:**
- `outlined` - Borda ao redor (padrão)
- `filled` - Fundo preenchido
- `standard` - Apenas linha inferior

**Tamanhos:**
- `small` - Compacto
- `medium` - Padrão
- `large` - Grande

**Exemplo:**
```dart
AppTextField(
  labelText: 'Email',
  hintText: 'seu@email.com',
  variant: TextFieldVariant.outlined,
  size: TextFieldSize.medium,
  prefixIcon: Icon(Icons.email),
  validator: (value) => value?.isEmpty ?? true ? 'Campo obrigatório' : null,
)
```

### AppButton
Botão com diferentes variantes e animações.

**Variantes:**
- `contained` - Preenchido (padrão)
- `outlined` - Com borda
- `text` - Sem fundo
- `soft` - Fundo suave/transparente

**Tamanhos:**
- `small` - 36px de altura, fonte 13: só em linhas densas (cards de pedido, item de lista)
- `medium` - 44px de altura, fonte 14: padrão para toda ação
- `large` - 52px de altura, fonte 16: ação principal da tela (carrinho, checkout)

Os botões do Material (`FilledButton`, `OutlinedButton`, `TextButton`, `ElevatedButton`) seguem o tema com a mesma altura mínima do `medium` (44px).

**Exemplo:**
```dart
AppButton(
  text: 'Enviar',
  onPressed: () {},
  variant: ButtonVariant.contained,
  size: ButtonSize.medium,
  icon: Icons.send,
  isLoading: false,
)
```

### AppCard
Container com sombra e bordas arredondadas.

**Exemplo:**
```dart
AppCard(
  elevation: 2,
  borderRadius: 12,
  padding: EdgeInsets.all(16),
  child: Text('Conteúdo'),
)
```

### AppPaper
Variante de card com estilos pré-definidos.

**Variantes:**
- `elevation` - Com sombra
- `outlined` - Com borda
- `filled` - Fundo preenchido

**Exemplo:**
```dart
AppPaper(
  variant: PaperVariant.outlined,
  child: Text('Conteúdo'),
)
```

### AppResponsiveRow
Campos lado a lado que empilham em coluna quando falta largura (celular).

**Exemplo:**
```dart
AppResponsiveRow(
  flex: const [1, 2], // opcional
  breakpoint: 480,    // abaixo disso, empilha
  children: [numeroField, complementoField],
)
```

### AppSectionHeader
Título de seção com subtítulo e ação opcionais.

**Exemplo:**
```dart
AppSectionHeader(
  title: 'Associados',
  subtitle: '12 encontrados',
  action: AppButton(text: 'Cadastrar', onPressed: _cadastrar),
)
```

**Acordeão:** com `onToggle`, o `AppSectionHeader` ganha a seta e o toque no título, e `expanded` diz se o conteúdo está aberto. Quem esconde o conteúdo é a tela. `prominent: true` usa o título grande sem precisar de ícone (ex: seções do cardápio).

### AppSectionTitle
Título de seção com sublinhado: texto na cor da marca, traço da mesma cor na largura do texto e linha fina até o fim, com `trailing` opcional à direita (ex: "4 lojas"). É usado na vitrine.

### AppPillSelect
Escolha compacta em pílula, da altura da busca (`AppSearchBar`), que abre um menu com as opções (`SelectItem`). Serve para ordenar ou filtrar uma lista.

### AppEmptyState
Estado vazio ou de erro, com ação opcional.

**Exemplo:**
```dart
AppEmptyState(
  icon: Icons.cloud_off_outlined,
  message: 'Não foi possível carregar',
  actionLabel: 'Tentar novamente',
  onAction: _carregar,
)
```

### AppStatusChip
Selo de status (texto colorido sobre fundo suave). Prefira tons escuros da paleta para contraste.

**Exemplo:**
```dart
AppStatusChip(label: 'Ativo', color: AppColors.successDark)
```

### AppFilterChips
Faixa rolável de chips de filtro com seleção única. Usa `SelectItem`; valor `null` representa "Todos".

**Exemplo:**
```dart
AppFilterChips<Status?>(
  items: const [
    SelectItem(value: null, label: 'Todos'),
    SelectItem(value: Status.ACTIVE, label: 'Ativos'),
  ],
  value: _filtro,
  onSelected: (valor) => setState(() => _filtro = valor),
)
```

### AppDialog
Diálogos padrão: confirmação e confirmação com motivo.

**Exemplo:**
```dart
final ok = await AppDialog.confirm(context,
    title: 'Aprovar?', message: 'O entregador ficará ativo.', confirmLabel: 'Aprovar');

// Retorna o motivo ou null se cancelado
final motivo = await AppDialog.reason(context,
    title: 'Recusar?', confirmLabel: 'Recusar', required: true);
```

### AppPanelScaffold
Layout dos painéis de gestão (restaurante, entregador, cooperativa, admin), no estilo do menu do app fieng:

Prints de referência em [`layout/menu/`](../../../../layout/menu/).

- **Tela larga (≥ 800px):** menu flutuante arredondado sobre o conteúdo. ☰ alterna entre recolhido (84px, só ícones com tooltip) e expandido (256px, ícone + rótulo + contador); a escolha fica salva (`panel_menu_expanded`).
- **Celular:** barra mínima com ☰ e o título da aba; o mesmo menu abre como gaveta e fecha ao escolher um item.
- Ordem do menu: ☰, `header`, `status`, abas (`destinations`) e "Sair" (`onLogout`) no rodapé. Item ativo com fundo `primary` suave e texto `primaryText`.
- Não há faixa no topo do conteúdo: a situação do painel (loja aberta, pausada...) vai em `status`, com um `AppPanelStatus` (ponto colorido quando recolhido; um toque abre as ações).
- **Rotas:** cada aba tem endereço próprio (`/restaurante/pedidos`, `/restaurante/loja/horarios`). As seções são um enum que implementa `PanelSection`, e as rotas vêm de `panelRoutes(...)` (`widgets/navigation/panel_routes.dart`). Todas usam a mesma chave de página: trocar de aba não recria o painel. A aba ativa vem do endereço (`selectedIndex: widget.section.index`) e a troca é `context.go(section.path)`.
- `AppPanelProfileHeader`: avatar, nome e perfil ativo; um toque abre as `sections` (ex: "Seus restaurantes", "Seus perfis"). Seções vazias não aparecem.
- A lista de perfis do usuário vem de `PanelProfile.of(user)` (`models/panel_profile.dart`) e a seção pronta de `panelProfilesSection` (`widgets/navigation/panel_profiles.dart`).

**Exemplo:**
```dart
AppPanelScaffold(
  header: AppPanelProfileHeader(
    avatar: RestaurantLogo(logoUrl: store.logoUrl, name: store.name, size: 40),
    title: store.name,
    subtitle: 'Restaurante',
    sections: [panelProfilesSection(context, current: PanelProfile.restaurant)],
  ),
  status: StoreStatusMenuTile(store: store),
  destinations: [for (final s in RestaurantSection.values) s.destination()],
  selectedIndex: widget.section.index,
  onDestinationSelected: (i) => context.go(RestaurantSection.values[i].path),
  onLogout: _logout,
  body: IndexedStack(index: widget.section.index, children: [...]),
)
```

### Largura do conteúdo (`AppLayout`)
Toda tela limita o conteúdo a `AppLayout.maxContentWidth` (1200px), com margem lateral de 24 (16 no celular).
- `AppPageListView(children: [...])`: lista rolável centralizada; a barra de rolagem fica na borda da tela.
- `AppPageContainer(child: ...)`: o mesmo sem rolagem (ex: quadro de colunas).
- `AppLayout.contentPadding(width)`: o padding pronto para `SliverPadding` ou listas próprias.
- `AppPageListView(footer: ...)`: o rodapé ocupa a largura toda no fim da rolagem e desce até o pé da tela em páginas curtas. Use com `StorefrontFooter` nas telas do cliente.

### AppPagedList
Lista com título, busca em pílula (opcional), filtros e "Carregar mais", para rotas paginadas do backend (`Page` do Spring → `AppPage.fromJson`). Refaz a busca quando o texto muda (com espera) e quando `filterKey` muda. É usada nas listas do painel admin.

### AppMap
Mapa do app com o estilo próprio do OpenBag (`assets/map/openbag_style.json`), desenhado pelo MapLibre. Recebe `markers` (`AppMapMarker`: ponto, cor, texto dentro e legenda ao lado), `lines` (`AppMapLine`) e `fitPoints`, que enquadra a câmera. Tudo é declarativo: mudou a lista, o mapa redesenha. Detalhes do estilo e da troca de base estão no README-DEVELOPER.

### AppTopNavBar
Barra horizontal de vidro (fundo translúcido desfocado) das telas do cliente, para `Scaffold(extendBodyBehindAppBar: true)`. Tem os espaços `logo`, `links` e `trailing`. Abaixo de 700px os links saem da barra. Nas telas use `StorefrontScaffold` (widgets/navigation), que já monta o logo, os links, o carrinho e a conta, e opcionalmente uma linha de título com o botão voltar.

## 🎨 Sistema de Cores

### AppColors
Define todas as cores da aplicação.

**Cores principais:**
- `primary` - Verde (#2E7D32)
- `accent` - Laranja (#FF7043)
- `error` - Vermelho (#EF5350)
- `warning` - Amarelo (#FFB300)
- `info` - Azul (#42A5F5)
- `success` - Verde (primary)

**Cores de superfície:**
- `backgroundMain` - Fundo principal (#F8FAFC)
- `backgroundSurface` - Cards e superfícies (#FFFFFF)
- `backgroundAlt` - Alternativo (#F1F5F9)

**Cores de texto:**
- `textTitle` - Títulos (#1E293B)
- `textBody` - Corpo (#64748B)
- `textSecondary` - Secundário (#94A3B8)
- `textDisabled` - Desabilitado (#CBD5E1)

**Métodos utilitários:**
```dart
// Cor com opacidade
AppColors.withAlpha(AppColors.primary, 0.5)

// Cor de contraste
AppColors.getContrastColor(AppColors.primary)

// Clarear/escurecer
AppColors.lighten(AppColors.primary, 0.2)
AppColors.darken(AppColors.primary, 0.2)
```

## 🎭 Tema

### AppTheme
Configuração de tema Material 3.

**Uso no main.dart:**
```dart
MaterialApp(
  theme: AppTheme.light,
  darkTheme: AppTheme.dark,
  themeMode: ThemeMode.system,
  // ...
)
```

## 📦 Exportação

### Para exportar para outro projeto:

1. Copie a pasta `core/ui` inteira
2. Ajuste os imports no arquivo `ui.dart` se necessário
3. Importe no novo projeto:

```dart
import 'package:seu_app/core/ui/ui.dart';
```

### Estrutura de pastas:
```
lib/
└── core/
    └── ui/
        ├── components/
        │   ├── app_text_field.dart
        │   ├── app_button.dart
        │   └── app_card.dart
        ├── theme/
        │   ├── app_colors.dart
        │   └── app_theme.dart
        ├── ui.dart (barrel file)
        └── README.md
```

## 🎯 Boas Práticas

1. **Use as variantes**: Aproveite os diferentes estilos disponíveis
2. **Seja consistente**: Use os mesmos tamanhos e variantes em todo o app
3. **Customize com cuidado**: Prefira os parâmetros dos componentes ao invés de hardcoded styles
4. **Reutilize cores**: Use sempre `AppColors` ao invés de `Color(0x...)`
5. **Documente mudanças**: Se customizar, documente no código

## 🔧 Customização

Para customizar cores globalmente, edite `AppColors`:

```dart
class AppColors {
  static const Color primary = Color(0xFF2E7D32); // Sua cor
  // ...
}
```

Para customizar componentes específicos, use os parâmetros:

```dart
AppButton(
  backgroundColor: Colors.blue,
  textColor: Colors.white,
  borderRadius: 20,
  // ...
)
```

## 📝 Licença

Estes componentes são parte do projeto e podem ser reutilizados livremente.
