import 'package:cloud_firestore/cloud_firestore.dart';

class PickModel {
  final String pickId;
  final String userId;
  final String displayName;
  final String weekName;
  final List<String> picks;
  final int tiebreaker;
  final DateTime submittedAt;
  final String paymentStatus; // 'pending', 'paid', 'verified', 'disqualified'
  final double entryFee;
  final int? score;
  final int? rank;
  final bool isActive;
  final String? paymentReference;
  final DateTime? verifiedAt;
  final String? verifiedBy;

  PickModel({
    required this.pickId,
    required this.userId,
    required this.displayName,
    required this.weekName,
    required this.picks,
    required this.tiebreaker,
    required this.submittedAt,
    required this.paymentStatus,
    required this.entryFee,
    this.score,
    this.rank,
    required this.isActive,
    this.paymentReference,
    this.verifiedAt,
    this.verifiedBy,
  });

  factory PickModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PickModel(
      pickId: doc.id,
      userId: data['uid'] ?? '',
      displayName: data['displayName'] ?? '',
      weekName: data['week'] ?? '',
      picks: List<String>.from(data['picks'] ?? []),
      tiebreaker: data['tiebreaker'] ?? 0,
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      paymentStatus: data['paymentStatus'] ?? 'pending',
      entryFee: (data['entryFee'] ?? 10.0).toDouble(),
      score: data['score'],
      rank: data['rank'],
      isActive: data['isActive'] ?? true,
      paymentReference: data['paymentReference'],
      verifiedAt: data['verifiedAt'] != null ? (data['verifiedAt'] as Timestamp).toDate() : null,
      verifiedBy: data['verifiedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': userId,
      'displayName': displayName,
      'week': weekName,
      'picks': picks,
      'tiebreaker': tiebreaker,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'paymentStatus': paymentStatus,
      'entryFee': entryFee,
      'score': score,
      'rank': rank,
      'isActive': isActive,
      'paymentReference': paymentReference,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'verifiedBy': verifiedBy,
    };
  }

  PickModel copyWith({
    String? pickId,
    String? userId,
    String? displayName,
    String? weekName,
    List<String>? picks,
    int? tiebreaker,
    DateTime? submittedAt,
    String? paymentStatus,
    double? entryFee,
    int? score,
    int? rank,
    bool? isActive,
    String? paymentReference,
    DateTime? verifiedAt,
    String? verifiedBy,
  }) {
    return PickModel(
      pickId: pickId ?? this.pickId,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      weekName: weekName ?? this.weekName,
      picks: picks ?? this.picks,
      tiebreaker: tiebreaker ?? this.tiebreaker,
      submittedAt: submittedAt ?? this.submittedAt,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      entryFee: entryFee ?? this.entryFee,
      score: score ?? this.score,
      rank: rank ?? this.rank,
      isActive: isActive ?? this.isActive,
      paymentReference: paymentReference ?? this.paymentReference,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verifiedBy: verifiedBy ?? this.verifiedBy,
    );
  }

  bool get isValid => paymentStatus == 'verified' && isActive;
  bool get isPendingPayment => paymentStatus == 'pending';
  bool get isDisqualified => paymentStatus == 'disqualified';
} 