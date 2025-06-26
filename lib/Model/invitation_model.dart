import 'package:cloud_firestore/cloud_firestore.dart';

class InvitationModel {
  final String invitationId;
  final String code;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isReusable;  // New field to indicate if code can be used multiple times
  final int? maxUses;      // Changed to nullable int
  final int usedCount;    // New field to track how many times code has been used
  final List<String> usedBy;  // Changed to List to track multiple users
  final List<DateTime> usedAt; // Changed to List to track usage timestamps
  final String status;    // 'active', 'expired', 'maxed_out'
  final String? email;
  final String? phone;

  InvitationModel({
    required this.invitationId,
    required this.code,
    required this.createdBy,
    required this.createdAt,
    this.expiresAt,
    required this.isReusable,
    this.maxUses,
    required this.usedCount,
    required this.usedBy,
    required this.usedAt,
    required this.status,
    this.email,
    this.phone,
  });

  factory InvitationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return InvitationModel(
      invitationId: doc.id,
      code: data['code'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null ? (data['expiresAt'] as Timestamp).toDate() : null,
      isReusable: data['isReusable'] ?? false,
      maxUses: data['maxUses'],
      usedCount: data['usedCount'] ?? 0,
      usedBy: List<String>.from(data['usedBy'] ?? []),
      usedAt: (data['usedAt'] as List<dynamic>? ?? []).map((timestamp) => (timestamp as Timestamp).toDate()).toList(),
      status: data['status'] ?? 'active',
      email: data['email'],
      phone: data['phone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'isReusable': isReusable,
      'maxUses': maxUses,
      'usedCount': usedCount,
      'usedBy': usedBy,
      'usedAt': usedAt.map((date) => Timestamp.fromDate(date)).toList(),
      'status': status,
      'email': email,
      'phone': phone,
    };
  }

  bool get isValid {
    if (status != 'active') return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    if (!isReusable && usedCount > 0) return false;
    if (maxUses != null && usedCount >= maxUses!) return false;
    return true;
  }

  InvitationModel copyWith({
    String? invitationId,
    String? code,
    String? createdBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isReusable,
    int? maxUses,
    int? usedCount,
    List<String>? usedBy,
    List<DateTime>? usedAt,
    String? status,
    String? email,
    String? phone,
  }) {
    return InvitationModel(
      invitationId: invitationId ?? this.invitationId,
      code: code ?? this.code,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isReusable: isReusable ?? this.isReusable,
      maxUses: maxUses ?? this.maxUses,
      usedCount: usedCount ?? this.usedCount,
      usedBy: usedBy ?? this.usedBy,
      usedAt: usedAt ?? this.usedAt,
      status: status ?? this.status,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
} 