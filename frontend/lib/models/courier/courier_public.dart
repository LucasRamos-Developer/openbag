import '../association/association.dart' show parseDate;
import 'courier_profile.dart';
import 'social_link.dart';
import 'vehicle_type.dart';

/// Perfil público do entregador (/e/:slug)
class CourierPublic {
  final String slug;
  final String fullName;
  final String? photoUrl;
  final String? bio;
  final List<SocialLink> socialLinks;
  final DateTime? memberSince;
  final double rating;
  final int totalReviews;
  final int totalDeliveries;
  final CourierAssociation? association;
  final PublicVehicle? vehicle;

  CourierPublic({
    required this.slug,
    required this.fullName,
    this.photoUrl,
    this.bio,
    required this.socialLinks,
    this.memberSince,
    required this.rating,
    required this.totalReviews,
    required this.totalDeliveries,
    this.association,
    this.vehicle,
  });

  factory CourierPublic.fromJson(Map<String, dynamic> json) => CourierPublic(
        slug: json['slug'],
        fullName: json['fullName'] ?? '',
        photoUrl: json['photoUrl'],
        bio: json['bio'],
        socialLinks: [for (final l in (json['socialLinks'] as List? ?? [])) SocialLink.fromJson(l)],
        memberSince: parseDate(json['memberSince']),
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        totalReviews: json['totalReviews'] ?? 0,
        totalDeliveries: json['totalDeliveries'] ?? 0,
        association: json['association'] != null ? CourierAssociation.fromJson(json['association']) : null,
        vehicle: json['vehicle'] != null ? PublicVehicle.fromJson(json['vehicle']) : null,
      );
}

class PublicVehicle {
  final VehicleType type;
  final String? model;
  final String? color;
  final String? maskedPlate;

  PublicVehicle({required this.type, this.model, this.color, this.maskedPlate});

  factory PublicVehicle.fromJson(Map<String, dynamic> json) => PublicVehicle(
        type: VehicleType.fromName(json['type']),
        model: json['model'],
        color: json['color'],
        maskedPlate: json['maskedPlate'],
      );
}
