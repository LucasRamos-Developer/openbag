import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../core/ui/ui.dart';
import '../../models/courier/courier_profile.dart';
import '../../models/courier/courier_public.dart';
import '../../models/courier/vehicle_type.dart';
import '../../utils/formatters.dart';
import 'courier_avatar.dart';

/// Dados exibidos na placa de verificação (na tela, no PDF e no perfil público)
class VerificationBadgeData {
  final String slug;
  final String fullName;
  final String? photoUrl;
  final String? associationName;
  final String? associationLogoUrl;
  final int? memberNumber;
  final bool verified;
  final VehicleType? vehicleType;
  final String? vehicleDescription;
  final String? plate;
  final DateTime? memberSince;

  const VerificationBadgeData({
    required this.slug,
    required this.fullName,
    this.photoUrl,
    this.associationName,
    this.associationLogoUrl,
    this.memberNumber,
    required this.verified,
    this.vehicleType,
    this.vehicleDescription,
    this.plate,
    this.memberSince,
  });

  factory VerificationBadgeData.fromProfile(CourierProfile profile) {
    final association = profile.association;
    final vehicle = profile.activeVehicle;
    return VerificationBadgeData(
      slug: profile.slug,
      fullName: profile.fullName,
      photoUrl: profile.photoUrl,
      associationName: association?.name,
      associationLogoUrl: association?.logoUrl,
      memberNumber: association?.memberNumber,
      verified: association?.verified ?? false,
      vehicleType: vehicle?.type,
      vehicleDescription: vehicle?.description,
      plate: vehicle?.plate,
      memberSince: profile.memberSince,
    );
  }

  factory VerificationBadgeData.fromPublic(CourierPublic courier) {
    final association = courier.association;
    final vehicle = courier.vehicle;
    return VerificationBadgeData(
      slug: courier.slug,
      fullName: courier.fullName,
      photoUrl: courier.photoUrl,
      associationName: association?.name,
      associationLogoUrl: association?.logoUrl,
      memberNumber: association?.memberNumber,
      verified: association?.verified ?? false,
      vehicleType: vehicle?.type,
      vehicleDescription: [vehicle?.model, vehicle?.color].whereType<String>().join(' · '),
      plate: vehicle?.maskedPlate,
      memberSince: courier.memberSince,
    );
  }

  String get publicUrl => AppConstants.appUrl('/e/$slug');

  String get vehicleLine => [
        if (vehicleType != null) vehicleType!.label,
        if (vehicleDescription?.isNotEmpty == true) vehicleDescription!,
        if (plate != null) plate!,
      ].join(' · ');
}

/// Placa de verificação do entregador: foto, nome, associação, veículo e QR code para o perfil público
class VerificationBadgeCard extends StatelessWidget {
  final VerificationBadgeData data;
  final bool showQrCode;

  const VerificationBadgeCard({super.key, required this.data, this.showQrCode = true});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final statusColor = data.verified ? AppColors.primary : AppColors.warningDarker;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: statusColor,
            child: Row(
              children: [
                Icon(data.verified ? Icons.verified : Icons.hourglass_top, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.verified ? 'Entregador verificado' : 'Verificação pendente',
                    style: textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                Text('OpenBag', style: textTheme.labelLarge?.copyWith(color: Colors.white)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CourierAvatar(photoUrl: data.photoUrl, name: data.fullName, size: 112),
                const SizedBox(height: 12),
                Text(
                  data.fullName,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (data.associationName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      data.associationName!,
                      if (data.memberNumber != null) 'Associado nº ${data.memberNumber}',
                    ].join(' · '),
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.textBody),
                  ),
                ],
                if (data.vehicleLine.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(data.vehicleType?.icon ?? Icons.local_shipping_outlined, size: 20, color: AppColors.textBody),
                      const SizedBox(width: 8),
                      Flexible(child: Text(data.vehicleLine, style: textTheme.bodyMedium)),
                    ],
                  ),
                ],
                if (data.memberSince != null) ...[
                  const SizedBox(height: 4),
                  Text('No OpenBag desde ${formatDate(data.memberSince)}',
                      style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                ],
                if (showQrCode) ...[
                  const SizedBox(height: 20),
                  AppQrCode(data: data.publicUrl, size: 168),
                  const SizedBox(height: 8),
                  Text('Escaneie para ver o perfil', style: textTheme.bodySmall),
                  SelectableText(
                    data.publicUrl.replaceFirst(RegExp(r'^https?://'), ''),
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
