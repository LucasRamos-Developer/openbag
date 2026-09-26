import '../models/association/association.dart';
import 'api_client.dart';

/// Moderação de associações pelo ADMIN da plataforma
class AdminAssociationService {
  final ApiClient _api;

  AdminAssociationService(this._api);

  Future<List<Association>> fetchAssociations({AssociationStatus? status}) async {
    final data = await _api.get('/admin/associations', query: {'status': status?.name, 'size': 100});
    return (data['content'] as List).map((e) => Association.fromJson(e)).toList();
  }

  Future<Association> approve(int id) async =>
      Association.fromJson(await _api.post('/admin/associations/$id/approve'));

  Future<Association> reject(int id, String reason) async =>
      Association.fromJson(await _api.post('/admin/associations/$id/reject', data: {'reason': reason}));

  Future<Association> suspend(int id, {String? reason}) async => Association.fromJson(
      await _api.post('/admin/associations/$id/suspend', data: reason != null ? {'reason': reason} : null));
}
