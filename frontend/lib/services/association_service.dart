import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../models/association/association.dart';
import '../models/delivery/delivery_rate.dart';
import '../models/association/association_stats.dart';
import '../models/association/invite.dart';
import '../models/association/member.dart';
import 'api_client.dart';

/// Estado e operações do painel do gestor da associação
class AssociationService extends ChangeNotifier {
  final ApiClient _api;

  AssociationService(this._api);

  Association? _association;
  AssociationStats? _stats;
  bool _isLoading = false;
  String? _error;

  Association? get association => _association;
  AssociationStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get _base => '/associations/${_association!.id}';

  /// Carrega a associação do gestor logado (e as estatísticas, se ela estiver ativa)
  Future<void> loadMyAssociation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _association = Association.fromJson(await _api.get('/associations/me'));
      if (_association!.isActive) {
        await refreshStats(notify: false);
      }
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshStats({bool notify = true}) async {
    _stats = AssociationStats.fromJson(await _api.get('$_base/stats'));
    if (notify) notifyListeners();
  }

  /// Atualiza os contadores após uma ação; falha aqui não deve anular a ação já concluída
  Future<void> _refreshStatsSilently() async {
    try {
      await refreshStats();
    } on ApiException {
      // Mantém as estatísticas anteriores
    }
  }

  void clear() {
    _association = null;
    _stats = null;
    _error = null;
  }

  // ============= Dados da associação =============

  Future<void> updateAssociation(Map<String, dynamic> body) async {
    _association = Association.fromJson(await _api.put(_base, data: body));
    notifyListeners();
  }

  Future<void> updateLogo(XFile file) async {
    final bytes = await file.readAsBytes();
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: file.name),
    });
    _association = Association.fromJson(await _api.post('$_base/logo', data: form));
    notifyListeners();
  }

  Future<void> updateDeliveryRate(DeliveryRate rate) async {
    _association = Association.fromJson(await _api.put('$_base/delivery-rate', data: rate.toJson()));
    notifyListeners();
  }

  // ============= Associados =============

  Future<MemberPage> fetchMembers({MembershipStatus? status, String? query, int page = 0, int size = 20}) async {
    final data = await _api.get('$_base/members', query: {
      'status': status?.name,
      'q': query,
      'page': page,
      'size': size,
    });
    return MemberPage.fromJson(data);
  }

  Future<Member> createMember(Map<String, dynamic> body) async {
    final member = Member.fromJson(await _api.post('$_base/members', data: body));
    await _refreshStatsSilently();
    return member;
  }

  /// Executa uma ação de transição (approve, reject, suspend, reactivate, remove)
  Future<Member> memberAction(int membershipId, MemberAction action, {String? reason}) async {
    final data = await _api.post(
      '$_base/members/$membershipId/${action.path}',
      data: reason != null && reason.isNotEmpty ? {'reason': reason} : null,
    );
    await _refreshStatsSilently();
    return Member.fromJson(data);
  }

  // ============= Convites =============

  Future<List<Invite>> fetchInvites() async {
    final data = await _api.get('$_base/invites') as List;
    return data.map((e) => Invite.fromJson(e)).toList();
  }

  Future<Invite> createInvite({int? expiresInDays, int? maxUses}) async {
    final invite = Invite.fromJson(await _api.post('$_base/invites', data: {
      if (expiresInDays != null) 'expiresInDays': expiresInDays,
      if (maxUses != null) 'maxUses': maxUses,
    }));
    await _refreshStatsSilently();
    return invite;
  }

  Future<Invite> revokeInvite(int inviteId) async {
    final invite = Invite.fromJson(await _api.delete('$_base/invites/$inviteId'));
    await _refreshStatsSilently();
    return invite;
  }
}

/// Ações do gestor sobre um associado, conforme o status atual
enum MemberAction {
  approve('approve', 'Aprovar', false),
  reject('reject', 'Recusar', true),
  suspend('suspend', 'Suspender', true),
  reactivate('reactivate', 'Reativar', false),
  remove('remove', 'Desligar', true);

  final String path;
  final String label;
  final bool asksReason;
  const MemberAction(this.path, this.label, this.asksReason);

  static List<MemberAction> availableFor(MembershipStatus status) {
    switch (status) {
      case MembershipStatus.PENDING:
        return [approve, reject];
      case MembershipStatus.ACTIVE:
        return [suspend, remove];
      case MembershipStatus.SUSPENDED:
        return [reactivate, remove];
      default:
        return [];
    }
  }
}
