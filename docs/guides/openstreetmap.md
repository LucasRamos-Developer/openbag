# OpenStreetMap no Open Bag

Este projeto utiliza o **OpenStreetMap** como alternativa open source ao Google Maps.

## Dependências

As seguintes dependências foram adicionadas ao `pubspec.yaml`:

```yaml
# Maps (Web compatible) - OpenStreetMap
flutter_map: ^6.1.0
latlong2: ^0.9.0
geolocator: ^10.1.0
geolocator_web: ^2.2.0
```

## Vantagens do OpenStreetMap

### ✅ **Vantagens:**
- **Gratuito**: Sem custos de API ou limites de uso
- **Open Source**: Dados abertos e colaborativos
- **Sem necessidade de chaves de API**: Funciona imediatamente
- **Privacidade**: Não rastreia usuários como outras plataformas
- **Customizável**: Estilos de mapa personalizáveis
- **Dados atualizados**: Comunidade ativa mantém os dados

### 🔄 **Comparação com Google Maps:**
- **Google Maps**: Requer chave de API, tem limites de uso, custos altos
- **OpenStreetMap**: Completamente gratuito e aberto

## Implementação

### Widget Básico de Mapa

```dart
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

FlutterMap(
  options: MapOptions(
    center: LatLng(-23.550520, -46.633308), // São Paulo
    zoom: 13.0,
  ),
  children: [
    TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.openbag.app',
    ),
  ],
)
```

### Funcionalidades Implementadas

1. **Localização Atual**: Detecta a posição do usuário
2. **Marcadores Customizados**: Para restaurantes e pontos de interesse
3. **Seleção de Localização**: Usuário pode tocar no mapa
4. **Marcadores de Restaurantes**: Mostra restaurantes próximos

### Arquivos Criados

- `lib/widgets/map_widget.dart`: Widget principal do mapa
- `lib/screens/location_selection_screen.dart`: Tela de seleção de localização

## Provedores de Tiles Alternativos

Além do OpenStreetMap padrão, você pode usar outros provedores:

```dart
// CartoDB Positron (estilo clean)
'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png'

// CartoDB Dark Matter (tema escuro)
'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'

// OpenStreetMap France
'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png'
```

## Configurações Web

Para funcionar na web, adicione no `web/index.html`:

```html
<meta name="referrer" content="no-referrer">
```

## Permissões

### Android (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS (`ios/Runner/Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Este app precisa de acesso à localização para mostrar restaurantes próximos.</string>
```

## Exemplo de Uso

```dart
// Tela com mapa
MapWidget(
  initialLocation: LatLng(-23.550520, -46.633308),
  onLocationSelected: (location) {
    print('Localização selecionada: $location');
  },
  markers: [
    MapMarker(
      position: LatLng(-23.550520, -46.633308),
      title: 'Restaurante XYZ',
      icon: Icons.restaurant,
    ),
  ],
)
```

## Performance

- **Tiles em Cache**: O `flutter_map` automaticamente faz cache dos tiles
- **Lazy Loading**: Carrega apenas os tiles visíveis
- **Otimizado**: Performance similar ao Google Maps

## Recursos Futuros

- [ ] Rotas e navegação (usando OSRM)
- [ ] Geocodificação (Nominatim)
- [ ] Busca de locais
- [ ] Integração com APIs de trânsito público
