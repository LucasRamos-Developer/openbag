import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/cooperative/billing.dart';
import '../models/cooperative/community.dart';
import '../models/cooperative/ledger.dart';
import '../utils/formatters.dart';
import 'api_client.dart';

/// Gestão da associação: cobrança (política, adicionais, faturas), livro-caixa e caixinha, convênios,
/// enquetes e documentos. As rotas são da associação [organizationId].
class CooperativeService {
  final ApiClient _api;

  CooperativeService(this._api);

  String _base(int organizationId) => '/associations/$organizationId';

  // ============= Cobrança =============

  Future<FeePolicy> fetchFeePolicy(int organizationId) async =>
      FeePolicy.fromJson(await _api.get('${_base(organizationId)}/fee-policy'));

  Future<FeePolicy> updateFeePolicy(int organizationId, FeePolicy policy) async =>
      FeePolicy.fromJson(await _api.put('${_base(organizationId)}/fee-policy', data: policy.toJson()));

  Future<List<AddonPlan>> fetchAddonPlans(int organizationId) async =>
      [for (final p in await _api.get('${_base(organizationId)}/addon-plans') as List) AddonPlan.fromJson(p)];

  Future<AddonPlan> saveAddonPlan(int organizationId, Map<String, dynamic> body, {int? planId}) async =>
      AddonPlan.fromJson(planId == null
          ? await _api.post('${_base(organizationId)}/addon-plans', data: body)
          : await _api.put('${_base(organizationId)}/addon-plans/$planId', data: body));

  /// Propõe aos escolhidos ou, sem lista, a todos os ativos. Devolve quantos receberam.
  Future<int> proposeAddon(int organizationId, int planId, {List<int>? membershipIds}) async {
    final data = await _api.post('${_base(organizationId)}/addon-plans/$planId/propose',
        data: {'membershipIds': membershipIds ?? const []});
    return (data['proposed'] as num?)?.toInt() ?? 0;
  }

  Future<List<MemberAddon>> fetchMemberAddons(int organizationId, int membershipId) async => [
        for (final a in await _api.get('${_base(organizationId)}/members/$membershipId/addons') as List)
          MemberAddon.fromJson(a)
      ];

  Future<MemberAddon> cancelMemberAddon(int organizationId, int memberAddonId) async =>
      MemberAddon.fromJson(await _api.post('${_base(organizationId)}/member-addons/$memberAddonId/cancel'));

  // ============= Faturas =============

  Future<InvoiceMonth> fetchInvoices(int organizationId, DateTime month) async => InvoiceMonth.fromJson(
      await _api.get('${_base(organizationId)}/invoices', query: {'month': apiMonth(month)}));

  Future<InvoiceMonth> generateInvoices(int organizationId, DateTime month) async => InvoiceMonth.fromJson(
      await _api.post('${_base(organizationId)}/invoices/generate?month=${apiMonth(month)}'));

  Future<Invoice> payInvoice(int organizationId, int invoiceId,
          {required MemberPaymentMethod method, DateTime? paidOn, String? notes}) async =>
      Invoice.fromJson(await _api.post('${_base(organizationId)}/invoices/$invoiceId/pay', data: {
        'method': method.name,
        if (paidOn != null) 'paidOn': apiDate(paidOn),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      }));

  Future<Invoice> waiveInvoice(int organizationId, int invoiceId, String? reason) async => Invoice.fromJson(
      await _api.post('${_base(organizationId)}/invoices/$invoiceId/waive', data: {'reason': reason}));

  Future<Invoice> reopenInvoice(int organizationId, int invoiceId) async =>
      Invoice.fromJson(await _api.post('${_base(organizationId)}/invoices/$invoiceId/reopen'));

  // ============= Livro-caixa =============

  Future<FinanceSummary> fetchSummary(int organizationId) async =>
      FinanceSummary.fromJson(await _api.get('${_base(organizationId)}/finance/summary'));

  Future<LedgerPage> fetchLedger(int organizationId,
          {LedgerAccount? account, DateTime? from, DateTime? to, int page = 0}) async =>
      LedgerPage.fromJson(await _api.get('${_base(organizationId)}/ledger', query: {
        'account': account?.name,
        'from': from != null ? apiDate(from) : null,
        'to': to != null ? apiDate(to) : null,
        'page': page,
        'size': 30,
      }));

  Future<LedgerEntry> createLedgerEntry(int organizationId,
          {required ManualEntryKind kind,
          required double amount,
          required String description,
          DateTime? date,
          int? membershipId}) async =>
      LedgerEntry.fromJson(await _api.post('${_base(organizationId)}/ledger', data: {
        'kind': kind.name,
        'amount': amount,
        'description': description,
        if (date != null) 'date': apiDate(date),
        if (membershipId != null) 'membershipId': membershipId,
      }));

  Future<void> deleteLedgerEntry(int organizationId, int entryId) =>
      _api.delete('${_base(organizationId)}/ledger/$entryId');

  // ============= Convênios =============

  Future<List<Benefit>> fetchBenefits(int organizationId) async =>
      [for (final b in await _api.get('${_base(organizationId)}/benefits') as List) Benefit.fromJson(b)];

  Future<Benefit> saveBenefit(int organizationId, Map<String, dynamic> body, {int? benefitId}) async =>
      Benefit.fromJson(benefitId == null
          ? await _api.post('${_base(organizationId)}/benefits', data: body)
          : await _api.put('${_base(organizationId)}/benefits/$benefitId', data: body));

  Future<Benefit> updateBenefitLogo(int organizationId, int benefitId, XFile file) async {
    final form = FormData.fromMap({'file': MultipartFile.fromBytes(await file.readAsBytes(), filename: file.name)});
    return Benefit.fromJson(await _api.post('${_base(organizationId)}/benefits/$benefitId/logo', data: form));
  }

  Future<void> deleteBenefit(int organizationId, int benefitId) =>
      _api.delete('${_base(organizationId)}/benefits/$benefitId');

  // ============= Enquetes =============

  Future<List<Poll>> fetchPolls(int organizationId) async =>
      [for (final p in await _api.get('${_base(organizationId)}/polls') as List) Poll.fromJson(p)];

  Future<Poll> savePoll(int organizationId,
      {required String question, String? description, required List<String> options, DateTime? closesAt, int? pollId}) async {
    final body = {
      'question': question,
      'description': description,
      'options': options,
      'closesAt': closesAt?.toIso8601String(),
    };
    return Poll.fromJson(pollId == null
        ? await _api.post('${_base(organizationId)}/polls', data: body)
        : await _api.put('${_base(organizationId)}/polls/$pollId', data: body));
  }

  /// open ou close
  Future<Poll> pollAction(int organizationId, int pollId, String action) async =>
      Poll.fromJson(await _api.post('${_base(organizationId)}/polls/$pollId/$action'));

  Future<void> deletePoll(int organizationId, int pollId) => _api.delete('${_base(organizationId)}/polls/$pollId');

  // ============= Documentos =============

  Future<List<AssociationDocument>> fetchDocuments(int organizationId) async => [
        for (final d in await _api.get('${_base(organizationId)}/documents') as List) AssociationDocument.fromJson(d)
      ];

  Future<AssociationDocument> uploadDocument(int organizationId,
      {required Uint8List bytes,
      required String fileName,
      required String title,
      required AssociationDocumentType type,
      DateTime? date,
      String? description}) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: fileName, contentType: DioMediaType('application', 'pdf')),
      'title': title,
      'type': type.name,
      if (date != null) 'date': apiDate(date),
      if (description != null && description.isNotEmpty) 'description': description,
    });
    return AssociationDocument.fromJson(await _api.post('${_base(organizationId)}/documents', data: form));
  }

  Future<Uint8List> downloadDocument(int organizationId, int documentId) =>
      _api.getBytes('${_base(organizationId)}/documents/$documentId/file');

  Future<void> deleteDocument(int organizationId, int documentId) =>
      _api.delete('${_base(organizationId)}/documents/$documentId');
}
