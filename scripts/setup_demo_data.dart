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