import 'package:flutter/material.dart';
import '../association/association.dart' show parseDate;

enum BenefitCategory {
  WORKSHOP('Oficina', Icons.build_outlined),
  LANGUAGES('Idiomas', Icons.translate),
  EDUCATION('Cursos', Icons.school_outlined),
  HEALTH('Saúde', Icons.favorite_border),
  FUEL('Combustível', Icons.local_gas_station_outlined),
  PARTS('Peças e acessórios', Icons.two_wheeler),
  FOOD('Alimentação', Icons.restaurant_outlined),
  OTHER('Outros', Icons.local_offer_outlined);

  final String label;
  final IconData icon;
  const BenefitCategory(this.label, this.icon);

  static BenefitCategory fromName(String? name) => values.firstWhere((e) => e.name == name, orElse: () => OTHER);
}

/// Convênio da associação com um parceiro
class Benefit {
  final int id;
  final String partnerName;
  final BenefitCategory category;
  final String headline;
  final String? description;
  final String? address;
  final String? phone;
  final String? link;
  final String? logoUrl;
  final DateTime? validUntil;
  final bool active;
  final bool available;

  const Benefit({
    required this.id,
    required this.partnerName,
    required this.category,
    required this.headline,
    this.description,
    this.address,
    this.phone,
    this.link,
    this.logoUrl,
    this.validUntil,
    required this.active,
    required this.available,
  });

  factory Benefit.fromJson(Map<String, dynamic> json) => Benefit(
        id: json['id'],
        partnerName: json['partnerName'] ?? '',
        category: BenefitCategory.fromName(json['category']),
        headline: json['headline'] ?? '',
        description: json['description'],
        address: json['address'],
        phone: json['phone'],
        link: json['link'],
        logoUrl: json['logoUrl'],
        validUntil: parseDate(json['validUntil']),
        active: json['active'] ?? true,
        available: json['available'] ?? true,
      );
}

enum PollStatus {
  DRAFT('Rascunho'),
  OPEN('Aberta'),
  CLOSED('Encerrada');

  final String label;
  const PollStatus(this.label);

  static PollStatus fromName(String? name) => values.firstWhere((e) => e.name == name, orElse: () => DRAFT);
}

class PollOption {
  final int id;
  final String label;

  /// Nulo enquanto o resultado está escondido (o cooperado ainda não votou)
  final int? votes;

  const PollOption({required this.id, required this.label, this.votes});

  factory PollOption.fromJson(Map<String, dynamic> json) =>
      PollOption(id: json['id'], label: json['label'] ?? '', votes: json['votes']);
}

/// Enquete; o voto é secreto (só as contagens aparecem)
class Poll {
  final int id;
  final String question;
  final String? description;
  final PollStatus status;
  final DateTime? openedAt;
  final DateTime? closesAt;
  final DateTime? closedAt;
  final List<PollOption> options;
  final int totalVotes;
  final int eligibleVoters;
  final bool showResults;
  final int? myOptionId;

  const Poll({
    required this.id,
    required this.question,
    this.description,
    required this.status,
    this.openedAt,
    this.closesAt,
    this.closedAt,
    required this.options,
    required this.totalVotes,
    required this.eligibleVoters,
    required this.showResults,
    this.myOptionId,
  });

  factory Poll.fromJson(Map<String, dynamic> json) => Poll(
        id: json['id'],
        question: json['question'] ?? '',
        description: json['description'],
        status: PollStatus.fromName(json['status']),
        openedAt: parseDate(json['openedAt']),
        closesAt: parseDate(json['closesAt']),
        closedAt: parseDate(json['closedAt']),
        options: [for (final o in (json['options'] as List? ?? [])) PollOption.fromJson(o)],
        totalVotes: json['totalVotes'] ?? 0,
        eligibleVoters: json['eligibleVoters'] ?? 0,
        showResults: json['showResults'] ?? false,
        myOptionId: json['myOptionId'],
      );

  bool get voted => myOptionId != null;
  bool get canVote => status == PollStatus.OPEN && !voted;
}

enum AssociationDocumentType {
  MINUTES('Ata de reunião', Icons.groups_2_outlined),
  BYLAWS('Estatuto', Icons.gavel_outlined),
  FINANCIAL_REPORT('Prestação de contas', Icons.receipt_long_outlined),
  OTHER('Outro', Icons.description_outlined);

  final String label;
  final IconData icon;
  const AssociationDocumentType(this.label, this.icon);

  static AssociationDocumentType fromName(String? name) => values.firstWhere((e) => e.name == name, orElse: () => OTHER);
}

class AssociationDocument {
  final int id;
  final String title;
  final AssociationDocumentType type;
  final DateTime? date;
  final String? description;
  final String fileName;
  final int fileSize;
  final DateTime? createdAt;

  const AssociationDocument({
    required this.id,
    required this.title,
    required this.type,
    this.date,
    this.description,
    required this.fileName,
    required this.fileSize,
    this.createdAt,
  });

  factory AssociationDocument.fromJson(Map<String, dynamic> json) => AssociationDocument(
        id: json['id'],
        title: json['title'] ?? '',
        type: AssociationDocumentType.fromName(json['type']),
        date: parseDate(json['date']),
        description: json['description'],
        fileName: json['fileName'] ?? 'documento.pdf',
        fileSize: json['fileSize'] ?? 0,
        createdAt: parseDate(json['createdAt']),
      );

  /// "245 KB" ou "1,2 MB"
  String get sizeLabel => fileSize < 1024 * 1024
      ? '${(fileSize / 1024).ceil()} KB'
      : '${(fileSize / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB';
}
