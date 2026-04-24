import 'dart:io';
import 'opening_hour.dart';
import 'layout_config.dart';

class RestaurantOnboardingData {
  // Owner data (Step 1 - opcional se usuário já estiver logado)
  String? ownerFullName;
  String? ownerEmail;
  String? ownerPhoneNumber;
  String? ownerPassword;

  // Restaurant data (Step 2)
  String? restaurantName;
  String? restaurantSlug;
  String? restaurantDescription;
  String? restaurantPhoneNumber;
  String? restaurantCNPJ;
  double? deliveryFee;
  double? minimumOrder;
  int? deliveryTimeMin;
  int? deliveryTimeMax;

  // Address data (Step 2)
  String? addressStreet;
  String? addressNumber;
  String? addressComplement;
  String? addressNeighborhood;
  String? addressCity;
  String? addressState;
  String? addressZipCode;
  double? addressLatitude;
  double? addressLongitude;

  // Opening hours (Step 2)
  List<OpeningHour> openingHours;

  // Layout and customization (Step 3)
  LayoutConfig layoutConfig;
  List<int> categoryIds;

  // Image files (Step 3) - não salvos no JSON
  File? logoFile;
  File? bannerFile;

  RestaurantOnboardingData({
    this.ownerFullName,
    this.ownerEmail,
    this.ownerPhoneNumber,
    this.ownerPassword,
    this.restaurantName,
    this.restaurantSlug,
    this.restaurantDescription,
    this.restaurantPhoneNumber,
    this.restaurantCNPJ,
    this.deliveryFee,
    this.minimumOrder,
    this.deliveryTimeMin,
    this.deliveryTimeMax,
    this.addressStreet,
    this.addressNumber,
    this.addressComplement,
    this.addressNeighborhood,
    this.addressCity,
    this.addressState,
    this.addressZipCode,
    this.addressLatitude,
    this.addressLongitude,
    List<OpeningHour>? openingHours,
    LayoutConfig? layoutConfig,
    List<int>? categoryIds,
    this.logoFile,
    this.bannerFile,
  })  : openingHours = openingHours ?? [],
        layoutConfig = layoutConfig ?? LayoutConfig.defaultConfig,
        categoryIds = categoryIds ?? [];

  // Converter para JSON (para persistência local)
  Map<String, dynamic> toJson() {
    return {
      if (ownerFullName != null) 'ownerFullName': ownerFullName,
      if (ownerEmail != null) 'ownerEmail': ownerEmail,
      if (ownerPhoneNumber != null) 'ownerPhoneNumber': ownerPhoneNumber,
      // Não salvamos a senha no JSON por segurança
      if (restaurantName != null) 'restaurantName': restaurantName,
      if (restaurantSlug != null) 'restaurantSlug': restaurantSlug,
      if (restaurantDescription != null) 'restaurantDescription': restaurantDescription,
      if (restaurantPhoneNumber != null) 'restaurantPhoneNumber': restaurantPhoneNumber,
      if (restaurantCNPJ != null) 'restaurantCNPJ': restaurantCNPJ,
      if (deliveryFee != null) 'deliveryFee': deliveryFee,
      if (minimumOrder != null) 'minimumOrder': minimumOrder,
      if (deliveryTimeMin != null) 'deliveryTimeMin': deliveryTimeMin,
      if (deliveryTimeMax != null) 'deliveryTimeMax': deliveryTimeMax,
      if (addressStreet != null) 'addressStreet': addressStreet,
      if (addressNumber != null) 'addressNumber': addressNumber,
      if (addressComplement != null) 'addressComplement': addressComplement,
      if (addressNeighborhood != null) 'addressNeighborhood': addressNeighborhood,
      if (addressCity != null) 'addressCity': addressCity,
      if (addressState != null) 'addressState': addressState,
      if (addressZipCode != null) 'addressZipCode': addressZipCode,
      if (addressLatitude != null) 'addressLatitude': addressLatitude,
      if (addressLongitude != null) 'addressLongitude': addressLongitude,
      'openingHours': openingHours.map((h) => h.toJson()).toList(),
      'layoutConfig': layoutConfig.toJson(),
      'categoryIds': categoryIds,
    };
  }

  factory RestaurantOnboardingData.fromJson(Map<String, dynamic> json) {
    return RestaurantOnboardingData(
      ownerFullName: json['ownerFullName'],
      ownerEmail: json['ownerEmail'],
      ownerPhoneNumber: json['ownerPhoneNumber'],
      restaurantName: json['restaurantName'],
      restaurantSlug: json['restaurantSlug'],
      restaurantDescription: json['restaurantDescription'],
      restaurantPhoneNumber: json['restaurantPhoneNumber'],
      restaurantCNPJ: json['restaurantCNPJ'],
      deliveryFee: json['deliveryFee']?.toDouble(),
      minimumOrder: json['minimumOrder']?.toDouble(),
      deliveryTimeMin: json['deliveryTimeMin'],
      deliveryTimeMax: json['deliveryTimeMax'],
      addressStreet: json['addressStreet'],
      addressNumber: json['addressNumber'],
      addressComplement: json['addressComplement'],
      addressNeighborhood: json['addressNeighborhood'],
      addressCity: json['addressCity'],
      addressState: json['addressState'],
      addressZipCode: json['addressZipCode'],
      addressLatitude: json['addressLatitude']?.toDouble(),
      addressLongitude: json['addressLongitude']?.toDouble(),
      openingHours: json['openingHours'] != null
          ? (json['openingHours'] as List).map((h) => OpeningHour.fromJson(h)).toList()
          : null,
      layoutConfig: json['layoutConfig'] != null
          ? LayoutConfig.fromJson(json['layoutConfig'])
          : null,
      categoryIds: json['categoryIds'] != null
          ? List<int>.from(json['categoryIds'])
          : null,
    );
  }

  // Converter para JSON para envio ao backend (formato esperado pela API)
  Map<String, dynamic> toApiJson({
    String? ownerFullNameOverride,
    String? ownerEmailOverride,
    String? ownerPhoneNumberOverride,
  }) {
    return {
      'owner': {
        'fullName': ownerFullNameOverride ?? ownerFullName,
        'email': ownerEmailOverride ?? ownerEmail,
        'phoneNumber': ownerPhoneNumberOverride ?? ownerPhoneNumber,
        if (ownerPassword != null) 'password': ownerPassword,
      },
      'restaurant': {
        'name': restaurantName,
        'slug': restaurantSlug,
        if (restaurantDescription != null) 'description': restaurantDescription,
        'phoneNumber': restaurantPhoneNumber,
        'cnpj': restaurantCNPJ,
        'deliveryFee': deliveryFee,
        'minimumOrder': minimumOrder,
        'deliveryTimeMin': deliveryTimeMin,
        'deliveryTimeMax': deliveryTimeMax,
        if (addressLatitude != null) 'latitude': addressLatitude,
        if (addressLongitude != null) 'longitude': addressLongitude,
      },
      'address': {
        'street': addressStreet,
        'number': addressNumber,
        if (addressComplement != null && addressComplement!.isNotEmpty)
          'complement': addressComplement,
        'neighborhood': addressNeighborhood,
        'city': addressCity,
        'state': addressState,
        'zipCode': addressZipCode,
        if (addressLatitude != null) 'latitude': addressLatitude,
        if (addressLongitude != null) 'longitude': addressLongitude,
      },
      'openingHours': openingHours.map((h) => h.toJson()).toList(),
      'layoutConfig': layoutConfig.toJson(),
      'categoryIds': categoryIds,
    };
  }

  RestaurantOnboardingData copyWith({
    String? ownerFullName,
    String? ownerEmail,
    String? ownerPhoneNumber,
    String? ownerPassword,
    String? restaurantName,
    String? restaurantSlug,
    String? restaurantDescription,
    String? restaurantPhoneNumber,
    String? restaurantCNPJ,
    double? deliveryFee,
    double? minimumOrder,
    int? deliveryTimeMin,
    int? deliveryTimeMax,
    String? addressStreet,
    String? addressNumber,
    String? addressComplement,
    String? addressNeighborhood,
    String? addressCity,
    String? addressState,
    String? addressZipCode,
    double? addressLatitude,
    double? addressLongitude,
    List<OpeningHour>? openingHours,
    LayoutConfig? layoutConfig,
    List<int>? categoryIds,
    File? logoFile,
    File? bannerFile,
  }) {
    return RestaurantOnboardingData(
      ownerFullName: ownerFullName ?? this.ownerFullName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      ownerPhoneNumber: ownerPhoneNumber ?? this.ownerPhoneNumber,
      ownerPassword: ownerPassword ?? this.ownerPassword,
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantSlug: restaurantSlug ?? this.restaurantSlug,
      restaurantDescription: restaurantDescription ?? this.restaurantDescription,
      restaurantPhoneNumber: restaurantPhoneNumber ?? this.restaurantPhoneNumber,
      restaurantCNPJ: restaurantCNPJ ?? this.restaurantCNPJ,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      minimumOrder: minimumOrder ?? this.minimumOrder,
      deliveryTimeMin: deliveryTimeMin ?? this.deliveryTimeMin,
      deliveryTimeMax: deliveryTimeMax ?? this.deliveryTimeMax,
      addressStreet: addressStreet ?? this.addressStreet,
      addressNumber: addressNumber ?? this.addressNumber,
      addressComplement: addressComplement ?? this.addressComplement,
      addressNeighborhood: addressNeighborhood ?? this.addressNeighborhood,
      addressCity: addressCity ?? this.addressCity,
      addressState: addressState ?? this.addressState,
      addressZipCode: addressZipCode ?? this.addressZipCode,
      addressLatitude: addressLatitude ?? this.addressLatitude,
      addressLongitude: addressLongitude ?? this.addressLongitude,
      openingHours: openingHours ?? this.openingHours,
      layoutConfig: layoutConfig ?? this.layoutConfig,
      categoryIds: categoryIds ?? this.categoryIds,
      logoFile: logoFile ?? this.logoFile,
      bannerFile: bannerFile ?? this.bannerFile,
    );
  }
}
