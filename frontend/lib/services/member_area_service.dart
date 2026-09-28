import 'package:flutter/foundation.dart';
import '../models/cooperative/billing.dart';
import '../models/cooperative/community.dart';
import '../models/cooperative/ledger.dart';
import 'api_client.dart';

/// Área do cooperado: faturas, adicionais, caixinha, convênios, enquetes e documentos da associação dele
class MemberAreaService {
  final ApiClient _api;

  MemberAreaService(this._api);

  static const _base = '/me/association';

  Future<MyInvoices> fetchInvoices() async => MyInvoices.fromJson(await _api.get('$_base/invoices'));

  Future<List<MemberAddon>> fetchAddons() async =>
      [for (final a in await _api.get('$_base/addons') as List) MemberAddon.fromJson(a)];

  /// accept, decline ou cancel
  Future<MemberAddon> answerAddon(int memberAddonId, String action) async =>
      MemberAddon.fromJson(await _api.post('$_base/addons/$memberAddonId/$action'));

  Future<SolidarityFund> fetchFund() async => SolidarityFund.fromJson(await _api.get('$_base/solidarity-fund'));

  Future<double> setContribution(double amount) async {
    final data = await _api.put('$_base/solidarity-contribution', data: {'amount': amount});
    return (data['amount'] as num?)?.toDouble() ?? 0;
  }

  Future<List<Benefit>> fetchBenefits() async =>
      [for (final b in await _api.get('$_base/benefits') as List) Benefit.fromJson(b)];

  Future<List<Poll>> fetchPolls() async => [for (final p in await _api.get('$_base/polls') as List) Poll.fromJson(p)];

  Future<Poll> vote(int pollId, int optionId) async =>
      Poll.fromJson(await _api.post('$_base/polls/$pollId/vote', data: {'optionId': optionId}));

  Future<List<AssociationDocument>> fetchDocuments() async =>
      [for (final d in await _api.get('$_base/documents') as List) AssociationDocument.fromJson(d)];

  Future<Uint8List> downloadDocument(int documentId) => _api.getBytes('$_base/documents/$documentId/file');
}
