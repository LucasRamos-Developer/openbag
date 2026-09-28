import '../association/association.dart' show parseDate;
import '../association/member.dart' show MembershipStatus;
import 'social_link.dart';
import 'vehicle.dart';

/// Associação do entregador como aparece no perfil e na placa de verificação
class CourierAssociation {
  final int organizationId;
  final String name;
  final String? logoUrl;
  final int? memberNumber;
  final MembershipStatus status;
  final bool verified;

  CourierAssociation({
    required this.organizationId,
    required this.name,
    this.logoUrl,
    this.memberNumber,
    required this.status,
    required this.verified,
  });

  factory CourierAssociation.fromJson(Map<String, dynamic> json) => CourierAssociation(
        organizationId: json['organizationId'],
        name: json['name'] ?? '',
        logoUrl: json['logoUrl'],
        memberNumber: json['memberNumber'],
        status: MembershipStatus.fromName(json['status']),
        verified: json['verified'] ?? false,
      );
}

/// Perfil do entregador logado
class CourierProfile {
  final int id;
  final String slug;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? photoUrl;
  final String? bio;
  final bool showWorkHistory;
  final List<SocialLink> socialLinks;
  final Vehicle? activeVehicle;
  final double rating;
  final int totalReviews;
  final int totalDeliveries;
  final DateTime? memberSince;
  final CourierAssociation? association;

  CourierProfile({
    required this.id,
    required this.slug,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.photoUrl,
    this.bio,
    required this.showWorkHistory,
    required this.socialLinks,
    this.activeVehicle,
    required this.rating,
    this.totalReviews = 0,
    required this.totalDeliveries,
    this.memberSince,
    this.association,
  });

  factory CourierProfile.fromJson(Map<String, dynamic> json) => CourierProfile(
        id: json['id'],
        slug: json['slug'] ?? '',
        fullName: json['fullName'] ?? '',
        email: json['email'] ?? '',
        phoneNumber: json['phoneNumber'],
        photoUrl: json['photoUrl'],
        bio: json['bio'],
        showWorkHistory: json['showWorkHistory'] ?? true,
        socialLinks: [for (final l in (json['socialLinks'] as List? ?? [])) SocialLink.fromJson(l)],
        activeVehicle: json['activeVehicle'] != null ? Vehicle.fromJson(json['activeVehicle']) : null,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        totalReviews: json['totalReviews'] ?? 0,
        totalDeliveries: json['totalDeliveries'] ?? 0,
        memberSince: parseDate(json['memberSince']),
        association: json['association'] != null ? CourierAssociation.fromJson(json['association']) : null,
      );
}
