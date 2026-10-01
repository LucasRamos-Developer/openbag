import 'package:flutter/material.dart';

/// Tipo do comunicado da associação. Reunião precisa de data e hora; treinamento pode ter.
enum AnnouncementType {
  NOTICE('Aviso', Icons.campaign_outlined),
  MEETING('Reunião', Icons.groups_outlined),
  OPERATIONAL_CHANGE('Mudança na operação', Icons.sync_alt),
  RATE_CHANGE('Alteração de valor', Icons.price_change_outlined),
  NEW_PARTNERSHIP('Nova parceria', Icons.handshake_outlined),
  TRAINING('Treinamento', Icons.school_outlined);

  final String label;
  final IconData icon;
  const AnnouncementType(this.label, this.icon);

  bool get hasEvent => this == MEETING || this == TRAINING;

  static AnnouncementType fromName(String? name) => values.firstWhere((e) => e.name == name, orElse: () => NOTICE);
}

/// Comunicado do mural da associação. O gestor recebe [readCount] de [memberCount]; o cooperado recebe [read].
class Announcement {
  final int id;
  final AnnouncementType type;
  final String title;
  final String body;
  final DateTime? eventAt;
  final DateTime? publishedAt;
  final DateTime? archivedAt;
  final int? readCount;
  final int? memberCount;
  final bool read;

  Announcement({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.eventAt,
    this.publishedAt,
    this.archivedAt,
    this.readCount,
    this.memberCount,
    this.read = false,
  });

  static DateTime? _date(dynamic v) => v is String ? DateTime.tryParse(v) : null;

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
        id: json['id'],
        type: AnnouncementType.fromName(json['type']),
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        eventAt: _date(json['eventAt']),
        publishedAt: _date(json['publishedAt']),
        archivedAt: _date(json['archivedAt']),
        readCount: (json['readCount'] as num?)?.toInt(),
        memberCount: (json['memberCount'] as num?)?.toInt(),
        read: json['read'] ?? false,
      );

  bool get archived => archivedAt != null;
}
