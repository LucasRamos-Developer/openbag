import 'package:flutter_test/flutter_test.dart';
import 'package:open_bag/models/cooperative/announcement.dart';

void main() {
  test('comunicado do cooperado: reunião com data e ainda não lido', () {
    final a = Announcement.fromJson({
      'id': 4,
      'type': 'MEETING',
      'title': 'Assembleia de outubro',
      'body': 'Pauta: tabela de entrega.',
      'eventAt': '2026-10-08T19:00:00',
      'publishedAt': '2026-10-01T10:00:00',
      'read': false,
    });

    expect(a.type, AnnouncementType.MEETING);
    expect(a.type.hasEvent, isTrue);
    expect(a.eventAt, DateTime(2026, 10, 8, 19));
    expect(a.read, isFalse);
    expect(a.archived, isFalse);
    expect(a.readCount, isNull, reason: 'o cooperado não vê quantos leram');
  });

  test('comunicado do gestor traz quantos leram; tipo desconhecido vira aviso', () {
    final a = Announcement.fromJson({
      'id': 5,
      'type': 'TIPO_NOVO',
      'title': 'Chuva',
      'body': 'Cuidado.',
      'readCount': 3,
      'memberCount': 10,
      'archivedAt': '2026-10-02T08:00:00',
    });

    expect(a.type, AnnouncementType.NOTICE);
    expect(a.type.hasEvent, isFalse);
    expect(a.readCount, 3);
    expect(a.memberCount, 10);
    expect(a.archived, isTrue);
  });
}
