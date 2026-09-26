# Core UI Components

Sistema de componentes reutilizáveis baseado no design MUI Minimal.

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
- `small` - 32px altura
- `medium` - 40px altura
- `large` - 48px altura

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
