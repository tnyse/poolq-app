import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String userType;
  final String email;
  final String phone;
  final String displayName;
  final String avatar;
  final String invitationCode;
  final String invitedBy;
  final DateTime joinDate;
  final bool isActive;
  final Map<String, dynamic> preferences;
  final Map<String, dynamic> statistics;

  UserModel({
    required this.userId,
    required this.userType,
    required this.email,
    required this.phone,
    required this.displayName,
    required this.avatar,
    required this.invitationCode,
    required this.invitedBy,
    required this.joinDate,
    required this.isActive,
    required this.preferences,
    required this.statistics,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      userType: data['userType'] ?? 'player',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      displayName: data['displayName'] ?? '',
      avatar: data['avatar'] ?? '',
      invitationCode: data['invitationCode'] ?? '',
      invitedBy: data['invitedBy'] ?? '',
      joinDate: (data['joinDate'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      preferences: data['preferences'] ?? {
        'notifications': {},
        'privacy': {},
      },
      statistics: data['statistics'] ?? {
        'totalWinnings': 0,
        'winRate': 0.0,
        'pickPct': 0.0,
        'podiumRate': 0.0,
        'poolsPlayed': 0,
        'crowns': 0,
        'runnerUps': 0,
        'thirds': 0,
        'correctPicks': 0,
        'totalPicks': 0,
        'isReigningChampion': false,
      },
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userType': userType,
      'email': email,
      'phone': phone,
      'displayName': displayName,
      'avatar': avatar,
      'invitationCode': invitationCode,
      'invitedBy': invitedBy,
      'joinDate': Timestamp.fromDate(joinDate),
      'isActive': isActive,
      'preferences': preferences,
      'statistics': statistics,
    };
  }

  UserModel copyWith({
    String? userId,
    String? userType,
    String? email,
    String? phone,
    String? displayName,
    String? avatar,
    String? invitationCode,
    String? invitedBy,
    DateTime? joinDate,
    bool? isActive,
    Map<String, dynamic>? preferences,
    Map<String, dynamic>? statistics,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      invitationCode: invitationCode ?? this.invitationCode,
      invitedBy: invitedBy ?? this.invitedBy,
      joinDate: joinDate ?? this.joinDate,
      isActive: isActive ?? this.isActive,
      preferences: preferences ?? this.preferences,
      statistics: statistics ?? this.statistics,
    );
  }
} 