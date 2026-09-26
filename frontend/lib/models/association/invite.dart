import 'association.dart';

/// Código de convite para entrada direta na associação
class Invite {
  final int id;
  final String code;
  final DateTime? expiresAt;
  final int? maxUses;
  final int usesCount;
  final bool active;
  final bool usable;
  final DateTime? createdAt;
  final String? createdByName;

  Invite({
    required this.id,
    required this.code,
    this.expiresAt,
    this.maxUses,
    required this.usesCount,
    required this.active,
    required this.usable,
    this.createdAt,
    this.createdByName,
  });

  factory Invite.fromJson(Map<String, dynamic> json) {
    return Invite(
      id: json['id'],
      code: json['code'],
      expiresAt: parseDate(json['expiresAt']),
      maxUses: json['maxUses'],
      usesCount: json['usesCount'] ?? 0,
      active: json['active'] ?? false,
      usable: json['usable'] ?? false,
      createdAt: parseDate(json['createdAt']),
      createdByName: json['createdByName'],
    );
  }

  /// Motivo de o convite não poder mais ser usado
  String get statusLabel {
    if (usable) return 'Válido';
    if (!active) return 'Revogado';
    if (maxUses != null && usesCount >= maxUses!) return 'Esgotado';
    return 'Expirado';
  }

  String get usesLabel => maxUses == null ? '$usesCount usos' : '$usesCount de $maxUses usos';
}
