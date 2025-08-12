import 'package:cloud_firestore/cloud_firestore.dart';

class GameResultModel {
  final String gameId;
  final String weekName;
  final String homeTeam;
  final String awayTeam;
  final String homeTeamAbbr;
  final String awayTeamAbbr;
  final int? homeScore;
  final int? awayScore;
  final String? winner; // team abbreviation of winner
  final DateTime gameDate;
  final String status; // 'scheduled', 'in_progress', 'final', 'postponed'
  final DateTime? lastUpdated;
  final String? source; // 'espn', 'manual', 'local'

  GameResultModel({
    required this.gameId,
    required this.weekName,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeTeamAbbr,
    required this.awayTeamAbbr,
    this.homeScore,
    this.awayScore,
    this.winner,
    required this.gameDate,
    required this.status,
    this.lastUpdated,
    this.source,
  });

  factory GameResultModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return GameResultModel(
      gameId: doc.id,
      weekName: data['weekName'] ?? '',
      homeTeam: data['homeTeam'] ?? '',
      awayTeam: data['awayTeam'] ?? '',
      homeTeamAbbr: data['homeTeamAbbr'] ?? '',
      awayTeamAbbr: data['awayTeamAbbr'] ?? '',
      homeScore: data['homeScore'],
      awayScore: data['awayScore'],
      winner: data['winner'],
      gameDate: (data['gameDate'] as Timestamp).toDate(),
      status: data['status'] ?? 'scheduled',
      lastUpdated: data['lastUpdated'] != null ? (data['lastUpdated'] as Timestamp).toDate() : null,
      source: data['source'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weekName': weekName,
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'homeTeamAbbr': homeTeamAbbr,
      'awayTeamAbbr': awayTeamAbbr,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'winner': winner,
      'gameDate': Timestamp.fromDate(gameDate),
      'status': status,
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
      'source': source,
    };
  }

  bool get isFinal => status == 'final';
  bool get isInProgress => status == 'in_progress';
  bool get isScheduled => status == 'scheduled';
  
  int get totalScore => (homeScore ?? 0) + (awayScore ?? 0);
  
  String? get winnerAbbr {
    if (!isFinal || homeScore == null || awayScore == null) return null;
    return homeScore! > awayScore! ? homeTeamAbbr : awayTeamAbbr;
  }

  GameResultModel copyWith({
    String? gameId,
    String? weekName,
    String? homeTeam,
    String? awayTeam,
    String? homeTeamAbbr,
    String? awayTeamAbbr,
    int? homeScore,
    int? awayScore,
    String? winner,
    DateTime? gameDate,
    String? status,
    DateTime? lastUpdated,
    String? source,
  }) {
    return GameResultModel(
      gameId: gameId ?? this.gameId,
      weekName: weekName ?? this.weekName,
      homeTeam: homeTeam ?? this.homeTeam,
      awayTeam: awayTeam ?? this.awayTeam,
      homeTeamAbbr: homeTeamAbbr ?? this.homeTeamAbbr,
      awayTeamAbbr: awayTeamAbbr ?? this.awayTeamAbbr,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      winner: winner ?? this.winner,
      gameDate: gameDate ?? this.gameDate,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      source: source ?? this.source,
    );
  }
} 