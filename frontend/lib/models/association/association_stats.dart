/// Estatísticas do painel da associação
class AssociationStats {
  final int activeMembers;
  final int pendingRequests;
  final int suspendedMembers;
  final int availableNow;
  final int totalDeliveries;
  final int activeInvites;
  final Map<String, int> activeMembersByVehicleType;

  AssociationStats({
    required this.activeMembers,
    required this.pendingRequests,
    required this.suspendedMembers,
    required this.availableNow,
    required this.totalDeliveries,
    required this.activeInvites,
    required this.activeMembersByVehicleType,
  });

  factory AssociationStats.fromJson(Map<String, dynamic> json) {
    return AssociationStats(
      activeMembers: json['activeMembers'] ?? 0,
      pendingRequests: json['pendingRequests'] ?? 0,
      suspendedMembers: json['suspendedMembers'] ?? 0,
      availableNow: json['availableNow'] ?? 0,
      totalDeliveries: json['totalDeliveries'] ?? 0,
      activeInvites: json['activeInvites'] ?? 0,
      activeMembersByVehicleType: Map<String, int>.from(
        (json['activeMembersByVehicleType'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
      ),
    );
  }
}
