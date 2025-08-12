import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

Future<void> main() async {
  print('🚀 Setting up demo data for PoolQ...');
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  final firestore = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  
  try {
    // 1. Create invitation codes
    await createInvitationCodes(firestore);
    
    // 2. Create demo user accounts
    await createDemoUsers(auth, firestore);
    
    // 3. Seed picks for multiple players for a target week
    await seedWeekPicks(firestore,
      weekName: 'PRE1',
      usersByEmail: [
        'demo@poolq.app',
        'testuser@poolq.app',
      ],
      tiebreakers: {
        'demo@poolq.app': 45,
        'testuser@poolq.app': 52,
      },
    );
    
    print('✅ Demo data setup completed successfully!');
    printInstructions();
    
  } catch (e) {
    print('❌ Error setting up demo data: $e');
  }
}

Future<void> createInvitationCodes(FirebaseFirestore firestore) async {
  print('📝 Creating invitation codes...');
  
  final invitationCodes = [
    {
      'code': 'DEMO2024',
      'createdBy': 'admin@poolq.app',
      'createdAt': FieldValue.serverTimestamp(),
      'isReusable': true,
      'maxUses': 10,
      'usedCount': 0,
      'usedBy': [],
      'usedAt': [],
      'status': 'active',
    },
    {
      'code': 'TESTUSER',
      'createdBy': 'admin@poolq.app',
      'createdAt': FieldValue.serverTimestamp(),
      'isReusable': false,
      'maxUses': null,
      'usedCount': 0,
      'usedBy': [],
      'usedAt': [],
      'status': 'active',
    },
    {
      'code': 'VIP2024',
      'createdBy': 'admin@poolq.app',
      'createdAt': FieldValue.serverTimestamp(),
      'isReusable': true,
      'maxUses': 5,
      'usedCount': 0,
      'usedBy': [],
      'usedAt': [],
      'status': 'active',
    }
  ];
  
  for (final code in invitationCodes) {
    try {
      // Check if code already exists
      final existing = await firestore
          .collection('invites')
          .where('code', isEqualTo: code['code'])
          .get();
      
      if (existing.docs.isEmpty) {
        await firestore.collection('invites').add(code);
        print('  ✓ Created invitation code: ${code['code']}');
      } else {
        print('  → Invitation code already exists: ${code['code']}');
      }
    } catch (e) {
      print('  ❌ Failed to create ${code['code']}: $e');
    }
  }
}

Future<void> createDemoUsers(FirebaseAuth auth, FirebaseFirestore firestore) async {
  print('👥 Creating demo user accounts...');
  
  final demoUsers = [
    {
      'email': 'demo@poolq.app',
      'password': 'demo123456',
      'displayName': 'Demo User',
      'phone': '+15551234567',
      'invitationCode': 'DEMO2024',
    },
    {
      'email': 'testuser@poolq.app',
      'password': 'test123456',
      'displayName': 'Test User',
      'phone': '+15559876543',
      'invitationCode': 'TESTUSER',
    },
  ];
  
  for (final userData in demoUsers) {
    try {
      // Check if user already exists
      final existingUser = await firestore
          .collection('users')
          .where('email', isEqualTo: userData['email'])
          .get();
      
      if (existingUser.docs.isNotEmpty) {
        print('  → User already exists: ${userData['email']}');
        continue;
      }
      
      // Create Firebase Auth user
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: userData['email'] as String,
        password: userData['password'] as String,
      );
      
      await userCredential.user!.updateDisplayName(userData['displayName'] as String);
      
      // Create user profile in Firestore
      final userProfile = {
        'userId': userCredential.user!.uid,
        'userType': 'player',
        'email': userData['email'],
        'phone': userData['phone'],
        'displayName': userData['displayName'],
        'avatar': '',
        'invitationCode': userData['invitationCode'],
        'invitedBy': 'admin@poolq.app',
        'joinDate': FieldValue.serverTimestamp(),
        'isActive': true,
        'preferences': {
          'notifications': {},
          'privacy': {},
        },
        'statistics': {
          'totalWinnings': 0,
          'winRate': 0,
          'poolsPlayed': 0,
        },
      };
      
      await firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userProfile);
      
      // Update invitation code usage
      final inviteQuery = await firestore
          .collection('invites')
          .where('code', isEqualTo: userData['invitationCode'])
          .get();
      
      if (inviteQuery.docs.isNotEmpty) {
        final inviteDoc = inviteQuery.docs.first;
        final currentUsedBy = List<String>.from(inviteDoc.data()['usedBy'] ?? []);
        final currentUsedAt = List.from(inviteDoc.data()['usedAt'] ?? []);
        final currentUsedCount = inviteDoc.data()['usedCount'] ?? 0;
        
        await firestore.collection('invites').doc(inviteDoc.id).update({
          'usedBy': [...currentUsedBy, userCredential.user!.uid],
          'usedAt': [...currentUsedAt, FieldValue.serverTimestamp()],
          'usedCount': currentUsedCount + 1,
        });
      }
      
      print('  ✓ Created user account: ${userData['email']}');
      
    } catch (e) {
      if (e.toString().contains('email-already-in-use')) {
        print('  → User already exists in Firebase Auth: ${userData['email']}');
      } else {
        print('  ❌ Failed to create user ${userData['email']}: $e');
      }
    }
  }
  
  // Sign out after creating accounts
  try {
    await auth.signOut();
  } catch (e) {
    // Ignore sign out errors
  }
}

Future<void> seedWeekPicks(
  FirebaseFirestore firestore, {
  required String weekName,
  required List<String> usersByEmail,
  required Map<String, int> tiebreakers,
}) async {
  print('🏈 Seeding picks for $weekName ...');
  
  // Simple deterministic picks generator: alternate team choices per game index
  // Fetch schedule from local DB that app uses indirectly (store minimal mapping by email)
  final scheduleDoc = await firestore.collection('app_meta').doc('demo_schedule_map').get();
  List<List<String>> defaultPicks = [];
  if (scheduleDoc.exists) {
    // Not used currently; reserved for future
  }
  
  // For simplicity, create 10 dummy games and alternate abbreviations
  final gamesCount = 10;
  List<String> makePicks(bool pickHome) {
    return List<String>.generate(gamesCount, (i) => pickHome ? 'HOME_$i' : 'AWAY_$i');
  }

  // Resolve userIds by email
  Map<String, String> emailToUid = {};
  final usersSnap = await firestore.collection('users').where('email', whereIn: usersByEmail).get();
  for (final d in usersSnap.docs) {
    emailToUid[d['email']] = d.id;
  }

  for (int i = 0; i < usersByEmail.length; i++) {
    final email = usersByEmail[i];
    final uid = emailToUid[email];
    if (uid == null) {
      print('  ⚠️ user not found for $email, skipping');
      continue;
    }
    final picks = makePicks(i % 2 == 0);
    final tb = tiebreakers[email] ?? 50;
    final pickData = {
      'uid': uid,
      'displayName': email.split('@').first,
      'photoURL': '',
      'week': weekName,
      'picks': picks,
      'tiebreaker': tb,
      'submittedAt': FieldValue.serverTimestamp(),
      'paymentStatus': 'verified',
      'entryFee': 10.0,
      'isActive': true,
      'score': null,
      'rank': null,
      'tiebreakerDiff': null,
    };
    // Upsert: remove old records for this week
    final existing = await firestore.collection('pickrecord')
      .where('uid', isEqualTo: uid)
      .where('week', isEqualTo: weekName)
      .get();
    for (final e in existing.docs) {
      await e.reference.delete();
    }
    await firestore.collection('pickrecord').add(pickData);
    print('  ✓ Seeded picks for $email');
  }
}

void printInstructions() {
  print('\n🎉 Demo setup complete! Here are your test accounts:\n');
  
  print('📋 ADMIN LOGIN:');
  print('  Username: admin');
  print('  Password: admin123');
  print('  Purpose: Access admin dashboard to manage invitation codes\n');
  
  print('👤 DEMO USER ACCOUNTS:');
  print('  Email: demo@poolq.app');
  print('  Password: demo123456');
  print('  Purpose: Test general user functionality\n');
  
  print('  Email: testuser@poolq.app');
  print('  Password: test123456');
  print('  Purpose: Additional test user\n');
  
  print('🎫 INVITATION CODES (for new registrations):');
  print('  DEMO2024 - Reusable (max 10 uses)');
  print('  VIP2024 - Reusable (max 5 uses)');
  print('  TESTUSER - Single use (already used by testuser@poolq.app)\n');
  
  print('🔗 TESTING WORKFLOW:');
  print('  1. Login as admin to manage codes and view dashboard');
  print('  2. Login as demo user to test player functionality');
  print('  3. Register new accounts using the invitation codes');
  print('  4. Test different user flows and features\n');
  
  print('🚀 Ready to test PoolQ!');
} 