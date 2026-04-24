# 📦 Guia de Exportação - Core UI Components

Este guia explica como exportar os componentes UI deste projeto para reutilizar em outros projetos Flutter.

## 🎯 O que será exportado

Sistema completo de componentes UI baseado no design MUI Minimal:

- **Componentes**: TextField, Button, Card
- **Tema**: Cores, tipografia, estilos Material 3
- **Showcase**: Tela de exemplo com todos os componentes

## 📂 Estrutura Exportável

```
lib/core/ui/
├── components/
│   ├── app_text_field.dart    # TextField com 3 variantes + 3 tamanhos
│   ├── app_button.dart         # Button com 4 variantes + 3 tamanhos
│   └── app_card.dart           # Card com variantes e Paper
├── theme/
│   ├── app_colors.dart         # Sistema de cores completo
│   └── app_theme.dart          # Tema Material 3 (light + dark)
├── showcase/
│   └── ui_components_showcase.dart  # Exemplos visuais
├── ui.dart                     # Barrel file para imports
└── README.md                   # Documentação completa
```

## 🚀 Como Exportar

### Passo 1: Copiar a pasta

```bash
# No projeto de origem
cd /caminho/do/projeto/openbag/frontend

# Copiar a pasta completa
cp -r lib/core/ui /caminho/do/novo/projeto/lib/core/
```

### Passo 2: Verificar dependências

Os componentes usam apenas pacotes padrão do Flutter. Certifique-se que seu `pubspec.yaml` tem:

```yaml
dependencies:
  flutter:
    sdk: flutter
```

**Não precisa de dependências externas!** ✨

### Passo 3: Atualizar imports

No novo projeto, importe os componentes:

```dart
// Importar tudo de uma vez
import 'package:seu_projeto/core/ui/ui.dart';

// Ou importar componentes específicos
import 'package:seu_projeto/core/ui/components/app_button.dart';
import 'package:seu_projeto/core/ui/theme/app_theme.dart';
```

### Passo 4: Aplicar o tema

No `main.dart` do novo projeto:

```dart
import 'package:flutter/material.dart';
import 'core/ui/ui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu App',
      theme: AppTheme.light,        // 👈 Tema claro
      darkTheme: AppTheme.dark,     // 👈 Tema escuro
      themeMode: ThemeMode.system,  // 👈 Auto baseado no sistema
      home: const HomeScreen(),
    );
  }
}
```

## 💡 Exemplos de Uso

### TextField

```dart
// Outlined (padrão)
AppTextField(
  labelText: 'Email',
  hintText: 'seu@email.com',
  prefixIcon: Icon(Icons.email),
  validator: (value) => value?.isEmpty ?? true ? 'Obrigatório' : null,
)

// Filled
AppTextField(
  labelText: 'Nome',
  variant: TextFieldVariant.filled,
  size: TextFieldSize.large,
)

// Standard
AppTextField(
  labelText: 'Telefone',
  variant: TextFieldVariant.standard,
  helperText: 'Com DDD',
)
```

### Button

```dart
// Contained (padrão)
AppButton(
  text: 'Enviar',
  onPressed: () {},
  icon: Icons.send,
)

// Outlined
AppButton(
  text: 'Cancelar',
  onPressed: () {},
  variant: ButtonVariant.outlined,
)

// Soft (fundo suave)
AppButton(
  text: 'Upload',
  onPressed: () {},
  variant: ButtonVariant.soft,
  backgroundColor: AppColors.info,
)

// Loading state
AppButton(
  text: 'Salvando...',
  onPressed: () {},
  isLoading: true,
)
```

### Card

```dart
// Card simples
AppCard(
  child: Text('Conteúdo'),
  elevation: 2,
)

// Card com borda
AppCard(
  child: Text('Conteúdo'),
  elevation: 0,
  borderColor: AppColors.primary,
  borderWidth: 2,
)

// Paper (variantes prontas)
AppPaper(
  variant: PaperVariant.outlined,
  child: Text('Conteúdo'),
)
```

### Cores

```dart
// Usar cores do sistema
Container(
  color: AppColors.primary,
  child: Text(
    'Texto',
    style: TextStyle(
      color: AppColors.getContrastColor(AppColors.primary),
    ),
  ),
)

// Manipular cores
final lighterPrimary = AppColors.lighten(AppColors.primary, 0.2);
final darkerPrimary = AppColors.darken(AppColors.primary, 0.2);
final transparentPrimary = AppColors.withAlpha(AppColors.primary, 0.5);
```

## 🎨 Customização

### Personalizar Cores

Edite `lib/core/ui/theme/app_colors.dart`:

```dart
class AppColors {
  // Altere as cores principais
  static const Color primary = Color(0xFF2E7D32);  // Sua cor aqui
  static const Color accent = Color(0xFFFF7043);   // Sua cor aqui
  // ...
}
```

### Personalizar Tema

Edite `lib/core/ui/theme/app_theme.dart`:

```dart
static ThemeData get light => ThemeData(
  // Customize qualquer aspecto do tema Material 3
  useMaterial3: true,
  colorScheme: ColorScheme.light(
    primary: AppColors.primary,
    // ...
  ),
  // ...
);
```

### Extender Componentes

Crie variações dos componentes:

```dart
// Criar um botão customizado
class MyCustomButton extends AppButton {
  const MyCustomButton({
    super.key,
    required super.text,
    required super.onPressed,
  }) : super(
    variant: ButtonVariant.soft,
    size: ButtonSize.large,
    backgroundColor: AppColors.accent,
  );
}
```

## 🧪 Testar Componentes

Acesse a showcase para ver todos os componentes:

```dart
// Adicione esta rota no seu router
GoRoute(
  path: '/ui-showcase',
  builder: (context, state) => const UIComponentsShowcase(),
),
```

Ou navegue direto:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const UIComponentsShowcase(),
  ),
);
```

## ✅ Checklist de Exportação

- [ ] Copiei a pasta `lib/core/ui/` completa
- [ ] Atualizei imports no novo projeto
- [ ] Apliquei `AppTheme.light` no MaterialApp
- [ ] Testei um componente básico (AppButton)
- [ ] Verifiquei que não há erros de compilação
- [ ] Customizei cores se necessário
- [ ] Li a documentação em `core/ui/README.md`

## 📝 Notas Importantes

1. **Sem dependências externas**: Os componentes usam apenas Flutter puro
2. **Material 3**: Certifique-se de usar `useMaterial3: true`
3. **Barrel file**: Use `import 'core/ui/ui.dart'` para importar tudo
4. **Customização**: Prefira parâmetros aos componentes ao invés de editar o código fonte
5. **Versionamento**: Considere versionar a pasta `core/ui/` separadamente

## 🔗 Links Úteis

- [Material 3 Design](https://m3.material.io/)
- [MUI Minimal (referência)](https://minimals.cc/)
- [Flutter Docs](https://docs.flutter.dev/)

## 📞 Suporte

Se encontrar problemas:

1. Verifique que copiou toda a pasta `core/ui/`
2. Confirme que os imports estão corretos
3. Teste com `flutter clean && flutter pub get`
4. Veja exemplos na UIComponentsShowcase

---

**Pronto!** 🎉 Seus componentes estão prontos para serem reutilizados em qualquer projeto Flutter.
