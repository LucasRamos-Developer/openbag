import '../models/association/association_summary.dart';
import 'api_client.dart';

/// Associações ativas (lista pública), usada no cadastro do entregador e na escolha de parceiras do restaurante
Future<List<AssociationSummary>> fetchActiveAssociations(ApiClient api) async {
  final data = await api.get('/public/associations') as List;
  return [for (final a in data) AssociationSummary.fromJson(a)];
}
