import 'package:flutter_test/flutter_test.dart';
import 'package:open_bag/core/ui/ui.dart';

void main() {
  group('AppLayout.contentPadding', () {
    test('centraliza o conteúdo em 1200px em telas largas', () {
      final padding = AppLayout.contentPadding(1600);
      expect(padding.left, 200);
      expect(padding.right, 200);
      expect(1600 - padding.horizontal, AppLayout.maxContentWidth);
    });

    test('mantém o gutter quando a tela é menor que o conteúdo', () {
      expect(AppLayout.contentPadding(1000).left, 24);
      expect(AppLayout.contentPadding(390).left, 16);
    });

    test('respeita a largura máxima informada', () {
      final padding = AppLayout.contentPadding(1000, maxWidth: 688);
      expect(1000 - padding.horizontal, 688);
    });
  });

  group('AppResponsiveGrid.columnsFor', () {
    test('até 4 colunas no desktop, 3 no tablet, 2 no celular grande e 1 no pequeno', () {
      expect(AppResponsiveGrid.columnsFor(1200), 4);
      expect(AppResponsiveGrid.columnsFor(752), 3);
      expect(AppResponsiveGrid.columnsFor(472), 2);
      expect(AppResponsiveGrid.columnsFor(358), 1);
    });
  });
}
