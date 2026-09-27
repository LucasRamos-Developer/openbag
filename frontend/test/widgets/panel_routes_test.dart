import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:open_bag/widgets/navigation/panel_routes.dart';

enum _Section implements PanelSection {
  first('primeira', ['a', 'b']),
  second('segunda', []);

  @override
  final String slug;
  @override
  final List<String> tabs;

  const _Section(this.slug, this.tabs);

  @override
  String get label => slug;
  @override
  IconData get icon => Icons.circle_outlined;
  @override
  IconData get selectedIcon => Icons.circle;
}

/// Conta quantas vezes o painel foi criado, para provar que trocar de seção não o recria
class _Panel extends StatefulWidget {
  final _Section section;
  final String? tab;

  const _Panel(this.section, this.tab);

  static int created = 0;

  @override
  State<_Panel> createState() => _PanelState();
}

class _PanelState extends State<_Panel> {
  @override
  void initState() {
    super.initState();
    _Panel.created++;
  }

  @override
  Widget build(BuildContext context) => Text('${widget.section.slug}/${widget.tab}');
}

void main() {
  late GoRouter router;

  Future<void> start(WidgetTester tester, String location) async {
    _Panel.created = 0;
    router = GoRouter(
      initialLocation: location,
      routes: panelRoutes(base: '/painel', sections: _Section.values, builder: (s, tab) => _Panel(s, tab)),
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  String location() => router.routerDelegate.currentConfiguration.uri.toString();

  testWidgets('a raiz leva à primeira seção e à primeira aba', (tester) async {
    await start(tester, '/painel');
    expect(location(), '/painel/primeira/a');
    expect(find.text('primeira/a'), findsOneWidget);
  });

  testWidgets('seção ou aba desconhecida é corrigida', (tester) async {
    await start(tester, '/painel/nao-existe');
    expect(location(), '/painel/primeira/a');

    router.go('/painel/primeira/zzz');
    await tester.pumpAndSettle();
    expect(location(), '/painel/primeira/a');

    router.go('/painel/segunda/zzz');
    await tester.pumpAndSettle();
    expect(location(), '/painel/segunda');
  });

  testWidgets('trocar de seção e de aba reaproveita o mesmo painel', (tester) async {
    await start(tester, '/painel/primeira/b');
    expect(find.text('primeira/b'), findsOneWidget);

    router.go('/painel/segunda');
    await tester.pumpAndSettle();
    expect(find.text('segunda/null'), findsOneWidget);

    router.go('/painel/primeira/a');
    await tester.pumpAndSettle();
    expect(find.text('primeira/a'), findsOneWidget);
    expect(_Panel.created, 1);
  });
}
