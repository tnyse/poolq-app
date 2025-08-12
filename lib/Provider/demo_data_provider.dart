import 'package:flutter/material.dart';

class DemoDataProvider extends ChangeNotifier {
  // Demo user data
  Map<String, dynamic> demoUser = {
    'uid': 'demo-user-id',
    'email': 'demo@poolq.com',
    'displayName': 'Demo User',
    'phone': '+1234567890',
    'isAdmin': false,
    'isVerified': true,
    'createdAt': DateTime.now().toIso8601String(),
  };

  // Demo picks data
  List<Map<String, dynamic>> demoPicks = [
    {
      'id': 'demo-pick-1',
      'week': 'REG1',
      'user': 'demo@poolq.com',
      'gameId': 'PHI-DAL',
      'homeTeam': 'Philadelphia Eagles',
      'awayTeam': 'Dallas Cowboys',
      'selectedTeam': 'DAL',
      'selectedScore': 28,
      'opponentScore': 24,
      'status': 'submitted',
      'submittedAt': DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
      'score': 0,
    },
    {
      'id': 'demo-pick-2',
      'week': 'REG1',
      'user': 'demo@poolq.com',
      'gameId': 'KC-BAL',
      'homeTeam': 'Kansas City Chiefs',
      'awayTeam': 'Baltimore Ravens',
      'selectedTeam': 'KC',
      'selectedScore': 31,
      'opponentScore': 27,
      'status': 'submitted',
      'submittedAt': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
      'score': 0,
    },
  ];

  // Demo leaderboard data
  List<Map<String, dynamic>> demoLeaderboard = [
    {
      'user': 'demo@poolq.com',
      'displayName': 'Demo User',
      'score': 0,
      'picksSubmitted': 2,
      'rank': 1,
    },
    {
      'user': 'john@example.com',
      'displayName': 'John Doe',
      'score': 0,
      'picksSubmitted': 1,
      'rank': 2,
    },
    {
      'user': 'jane@example.com',
      'displayName': 'Jane Smith',
      'score': 0,
      'picksSubmitted': 0,
      'rank': 3,
    },
  ];

  // Demo payment data
  List<Map<String, dynamic>> demoPayments = [
    {
      'id': 'demo-payment-1',
      'user': 'demo@poolq.com',
      'amount': 25.00,
      'status': 'pending',
      'method': 'Venmo',
      'transactionId': 'demo-venmo-123',
      'submittedAt': DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
      'verifiedAt': null,
      'verifiedBy': null,
    },
  ];

  // Get demo user data
  Map<String, dynamic> getUserData() {
    return demoUser;
  }

  // Get demo picks
  List<Map<String, dynamic>> getPicks() {
    return demoPicks;
  }

  // Get demo leaderboard
  List<Map<String, dynamic>> getLeaderboard() {
    return demoLeaderboard;
  }

  // Get demo payments
  List<Map<String, dynamic>> getPayments() {
    return demoPayments;
  }

  // Add a demo pick
  void addPick(Map<String, dynamic> pick) {
    demoPicks.add(pick);
    notifyListeners();
  }

  // Update demo pick
  void updatePick(String pickId, Map<String, dynamic> updates) {
    final index = demoPicks.indexWhere((pick) => pick['id'] == pickId);
    if (index != -1) {
      demoPicks[index].addAll(updates);
      notifyListeners();
    }
  }

  // Add a demo payment
  void addPayment(Map<String, dynamic> payment) {
    demoPayments.add(payment);
    notifyListeners();
  }

  // Update demo payment status
  void updatePaymentStatus(String paymentId, String status, {String? verifiedBy}) {
    final index = demoPayments.indexWhere((payment) => payment['id'] == paymentId);
    if (index != -1) {
      demoPayments[index]['status'] = status;
      if (verifiedBy != null) {
        demoPayments[index]['verifiedBy'] = verifiedBy;
        demoPayments[index]['verifiedAt'] = DateTime.now().toIso8601String();
      }
      notifyListeners();
    }
  }
} 