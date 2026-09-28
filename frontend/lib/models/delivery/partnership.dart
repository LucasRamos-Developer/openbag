import '../association/association.dart' show parseDate;
import 'delivery_rate.dart';

/// Situação da parceria entre loja e associação
enum PartnershipStatus {
  PENDING('Pendente'),
  ACTIVE('Ativa'),
  DECLINED('Recusada'),
  ENDED('Encerrada');

  final String label;
  const PartnershipStatus(this.label);

  static PartnershipStatus fromName(String? name) => values.firstWhere((e) => e.name == name, orElse: () => ACTIVE);
}

/// Lado da parceria: quem pediu ou propôs; o outro é quem responde
enum PartnershipSide {
  RESTAURANT('a loja'),
  ASSOCIATION('a associação');

  final String label;
  const PartnershipSide(this.label);

  PartnershipSide get other => this == RESTAURANT ? ASSOCIATION : RESTAURANT;

  static PartnershipSide? fromName(String? name) => name == null ? null : values.firstWhere((e) => e.name == name);
}

/// Proposta de tabela especial aguardando o outro lado; [toDefault] = voltar à tabela da associação
class RateProposal {
  final DeliveryRate? rate;
  final bool toDefault;
  final PartnershipSide proposedBy;
  final DateTime? proposedAt;

  RateProposal({this.rate, required this.toDefault, required this.proposedBy, this.proposedAt});

  static RateProposal? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return RateProposal(
      rate: json['rate'] != null ? DeliveryRate.fromJson(json['rate']) : null,
      toDefault: json['toDefault'] ?? false,
      proposedBy: PartnershipSide.fromName(json['proposedBy'])!,
      proposedAt: parseDate(json['proposedAt']),
    );
  }
}

/// O que os dois painéis mostram de uma parceria (a loja vê a associação e vice-versa)
abstract class PartnershipInfo {
  int get id;
  PartnershipStatus get status;
  PartnershipSide? get requestedBy;
  PartnershipSide? get endedBy;

  /// Tabela especial combinada (nula = vale a padrão da associação)
  DeliveryRate? get agreedRate;
  DeliveryRate get effectiveRate;
  RateProposal? get rateProposal;
  DateTime? get since;
  DateTime? get endedAt;

  /// Quem precisa responder: o pedido, a contraproposta ou a proposta de tabela (nulo = ninguém)
  PartnershipSide? get awaitingSide;

  bool get isActive => status == PartnershipStatus.ACTIVE;
  bool get isPending => status == PartnershipStatus.PENDING;
  bool get hasAgreedRate => agreedRate != null;

  /// A vez de responder é de [viewer]
  bool awaits(PartnershipSide viewer) => awaitingSide == viewer;

  /// Ponto de partida de uma nova proposta ou contraproposta: a proposta em aberto ou a tabela que vale hoje
  DeliveryRate proposalStart(PartnershipSide viewer) => rateProposal?.rate ?? effectiveRate;

  /// Dá para propor a volta à tabela padrão: há tabela especial combinada ou proposta
  bool get canProposeDefault => hasAgreedRate || rateProposal?.rate != null;
}

/// Lê o lado que precisa responder; sem o campo (API antiga), deduz pelo pedido e pela proposta
PartnershipSide? parseAwaitingSide(Map<String, dynamic> json) {
  if (json.containsKey('awaitingSide')) return PartnershipSide.fromName(json['awaitingSide']);
  final status = PartnershipStatus.fromName(json['status']);
  final proposedBy = PartnershipSide.fromName((json['rateProposal'] as Map?)?['proposedBy']);
  if (status == PartnershipStatus.PENDING) return (proposedBy ?? PartnershipSide.fromName(json['requestedBy']))?.other;
  if (status == PartnershipStatus.ACTIVE) return proposedBy?.other;
  return null;
}

/// Ações aceitas pelas rotas de parceria dos dois lados
abstract final class PartnershipAction {
  static const accept = 'accept';
  static const decline = 'decline';
  static const end = 'end';
  static const rateAccept = 'rate-accept';
  static const rateDecline = 'rate-decline';
  static const rateCancel = 'rate-cancel';
}
