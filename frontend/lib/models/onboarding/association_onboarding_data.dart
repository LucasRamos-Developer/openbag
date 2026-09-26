import 'package:image_picker/image_picker.dart';

/// Dados do cadastro de associação/cooperativa, montados a partir dos steps do wizard
/// (UserInfoStep → owner*, AssociationInfoStep → association*, AddressStep → address*)
class AssociationOnboardingData {
  final Map<String, dynamic> formData;
  final XFile? logoFile;

  AssociationOnboardingData(this.formData, {this.logoFile});

  /// Chaves que não vão para o rascunho local (senha e arquivo)
  static const _nonDraftKeys = {'ownerPassword', 'ownerConfirmPassword', 'logoFile'};

  static Map<String, dynamic> draftOf(Map<String, dynamic> formData) {
    return Map.fromEntries(
      formData.entries.where((e) => !_nonDraftKeys.contains(e.key) && e.value is! XFile),
    );
  }

  String? _text(String key) {
    final value = formData[key];
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Map<String, dynamic> toApiJson() {
    return {
      'manager': {
        'fullName': _text('ownerFullName'),
        'email': _text('ownerEmail'),
        'phoneNumber': _text('ownerPhoneNumber'),
        'password': formData['ownerPassword'],
      },
      'association': {
        'type': formData['associationType'] ?? 'ASSOCIATION',
        'companyName': _text('associationCompanyName'),
        'tradingName': _text('associationTradingName'),
        'cnpj': _text('associationCNPJ'),
        'description': _text('associationDescription'),
        'phoneNumber': _text('associationPhoneNumber'),
        'contactEmail': _text('associationContactEmail'),
      },
      'address': addressJson(formData),
    };
  }

  /// Endereço no formato do backend, a partir das chaves address* do AddressStep
  static Map<String, dynamic> addressJson(Map<String, dynamic> data) {
    return {
      'zipCode': data['addressZipCode'],
      'street': data['addressStreet'],
      'number': data['addressNumber'],
      'complement': data['addressComplement'],
      'neighborhood': data['addressNeighborhood'],
      'city': data['addressCity'],
      'state': data['addressState'],
      'latitude': data['addressLatitude'],
      'longitude': data['addressLongitude'],
    };
  }
}
