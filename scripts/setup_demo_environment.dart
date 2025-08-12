import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

Future<void> main() async {
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;

  try {
    print('Setting up demo environment...');

    // Create demo invitation code
    await firestore.collection('invites').doc('demo2024').set({
      'code': 'DEMO2024',
      'createdBy': 'admin@poolq.app',
      'createdAt': FieldValue.serverTimestamp(),
      'isReusable': true,
      'maxUses': 100, // Allow up to 100 demo accounts
      'usedCount': 0,
      'usedBy': [],
      'usedAt': [],
      'status': 'active',
      'description': 'Demo invitation code for testing purposes',
    });

    print('✅ Demo invitation code DEMO2024 created successfully');

    // Create some sample game results for testing
    await _createSampleGameResults(firestore);

    print('✅ Demo environment setup complete!');
    print('');
    print('Demo credentials:');
    print('Email: demo@poolq.com');
    print('Password: demo123456');
    print('Invitation Code: DEMO2024');
    print('');
    print('You can now use the "Create Demo Account" button to test the app.');

  } catch (e) {
    print('❌ Error setting up demo environment: $e');
  }
}

Future<void> _createSampleGameResults(FirebaseFirestore firestore) async {
  try {
    // Create sample game results for REG1 week
    final sampleGames = [
      {
        'weekName': 'REG1',
        'homeTeam': 'Kansas City Chiefs',
        'awayTeam': 'Baltimore Ravens',
        'homeTeamAbbr': 'KC',
        'awayTeamAbbr': 'BAL',
        'homeScore': 24,
        'awayScore': 21,
        'winner': 'KC',
        'gameDate': DateTime(2025, 9, 4, 20, 20), // Thursday night
        'status': 'final',
        'source': 'demo',
      },
      {
        'weekName': 'REG1',
        'homeTeam': 'Dallas Cowboys',
        'awayTeam': 'Philadelphia Eagles',
        'homeTeamAbbr': 'DAL',
        'awayTeamAbbr': 'PHI',
        'homeScore': 31,
        'awayScore': 28,
        'winner': 'DAL',
        'gameDate': DateTime(2025, 9, 7, 16, 25), // Sunday
        'status': 'final',
        'source': 'demo',
      },
      {
        'weekName': 'REG1',
        'homeTeam': 'Green Bay Packers',
        'awayTeam': 'Chicago Bears',
        'homeTeamAbbr': 'GB',
        'awayTeamAbbr': 'CHI',
        'homeScore': 27,
        'awayScore': 24,
        'winner': 'GB',
        'gameDate': DateTime(2025, 9, 8, 20, 15), // Monday night
        'status': 'final',
        'source': 'demo',
      },
    ];

    for (var game in sampleGames) {
      await firestore.collection('game_results').add({
        ...game,
        'gameDate': Timestamp.fromDate(game['gameDate'] as DateTime),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }

    print('✅ Sample game results created for REG1 week');

  } catch (e) {
    print('❌ Error creating sample game results: $e');
  }
} 