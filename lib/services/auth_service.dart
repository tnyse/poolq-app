import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:poolqapp/Model/user_model.dart';
import 'package:poolqapp/Model/invitation_model.dart';
import 'dart:developer' as developer;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  void _logError(String message, [dynamic error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: 'AuthService',
      error: error,
      stackTrace: stackTrace,
      level: 1000, // Error level
    );
  }

  void _logInfo(String message) {
    developer.log(
      message,
      name: 'AuthService',
      level: 500, // Info level
    );
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in
  bool get isUserLoggedIn => currentUser != null;

  // Validate invitation code
  Future<InvitationModel?> validateInvitationCode(String code) async {
    try {
      final normalized = code.trim();
      _logInfo('Validating invitation code: $normalized');

      // Prefer exact match, then uppercase (DEMO2024), then lowercase.
      DocumentSnapshot? matched;
      for (final candidate in {
        normalized,
        normalized.toUpperCase(),
        normalized.toLowerCase(),
      }) {
        final querySnapshot = await _firestore
            .collection('invites')
            .where('code', isEqualTo: candidate)
            .limit(1)
            .get();
        if (querySnapshot.docs.isNotEmpty) {
          matched = querySnapshot.docs.first;
          break;
        }
      }

      if (matched == null) {
        _logError('No matching invite found for code: $normalized');
        return null;
      }

      final invitation = InvitationModel.fromFirestore(matched);
      
      if (!invitation.isValid) {
        String errorReason = '';
        if (invitation.status != 'active') errorReason += '\n- Status is not active';
        if (invitation.expiresAt != null && DateTime.now().isAfter(invitation.expiresAt!)) 
          errorReason += '\n- Code has expired';
        if (!invitation.isReusable && invitation.usedCount > 0) 
          errorReason += '\n- Code is not reusable and has been used';
        if (invitation.maxUses != null && invitation.usedCount >= invitation.maxUses!) 
          errorReason += '\n- Code has reached maximum uses';
        
        _logError('Invalid invitation code. Reasons:$errorReason');
        return null;
      }

      _logInfo('Invitation validated successfully: ${invitation.code}');
      return invitation;
    } on FirebaseAuthException catch (e, stackTrace) {
      _logError('Firebase error validating invitation code', e, stackTrace);
      return null;
    } catch (e, stackTrace) {
      _logError('Error validating invitation code', e, stackTrace);
      return null;
    }
  }

  // Register with invitation code
  Future<UserModel?> registerWithInvitation({
    required String email,
    required String password,
    required String phone,
    required String displayName,
    required String invitationCode,
  }) async {
    try {
      _logInfo('Starting registration process for email: $email');
      
      // Validate invitation code
      final invitation = await validateInvitationCode(invitationCode);
      if (invitation == null) {
        _logError('Registration failed: Invalid invitation code');
        throw Exception('Invalid or expired invitation code');
      }

      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        _logError('Registration failed: Firebase user creation returned null');
        throw Exception('Failed to create user');
      }

      // Update display name in Firebase Auth
      await userCredential.user!.updateDisplayName(displayName);

      // Create user profile
      final userModel = UserModel(
        userId: userCredential.user!.uid,
        userType: 'player',
        email: email,
        phone: phone.trim().isEmpty ? '' : phone,
        displayName: displayName,
        avatar: '',
        invitationCode: invitation.code,
        invitedBy: invitation.createdBy,
        joinDate: DateTime.now(),
        isActive: true,
        preferences: {
          'notifications': {},
          'privacy': {},
        },
        statistics: {
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

      // Save user profile to Firestore
      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userModel.toMap());
      
      // Update invitation usage
      final updatedUsedBy = [...invitation.usedBy, userCredential.user!.uid];
      final updatedUsedAt = [...invitation.usedAt, DateTime.now()];
      final updatedUsedCount = invitation.usedCount + 1;
      
      // Determine new status
      String newStatus = invitation.status;
      if (invitation.maxUses != null && updatedUsedCount >= invitation.maxUses!) {
        newStatus = 'maxed_out';
        _logInfo('Invitation code ${invitation.code} has reached maximum uses');
      }

      // Update invitation document
      await _firestore.collection('invites').doc(invitation.invitationId).update({
        'usedBy': updatedUsedBy,
        'usedAt': updatedUsedAt.map((date) => Timestamp.fromDate(date)).toList(),
        'usedCount': updatedUsedCount,
        'status': newStatus,
      });

      _logInfo('Registration completed successfully for user: ${userModel.userId}');
      return userModel;
    } on FirebaseAuthException catch (e, stackTrace) {
      _logError('Registration failed (FirebaseAuthException)', e, stackTrace);
      throw Exception(e.message ?? 'Registration failed');
    } catch (e, stackTrace) {
      _logError('Registration failed', e, stackTrace);
      throw Exception(e.toString());
    }
  }

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword(String email, String password) async {
    try {
      _logInfo('Attempting sign in for email: $email');
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        _logError('Sign in failed: Firebase returned null user');
        throw Exception('Failed to sign in');
      }

      final doc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!doc.exists) {
        _logError('Sign in failed: User document not found in Firestore');
        throw Exception('User profile not found');
      }

      final userModel = UserModel.fromFirestore(doc);
      
      if (!userModel.isActive) {
        _logError('Sign in failed: User account is inactive');
        throw Exception('Account is inactive. Please contact support.');
      }

      _logInfo('Sign in successful for user: ${userModel.userId}');
      return userModel;
    } on FirebaseAuthException catch (e, stackTrace) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during sign in.';
      }
      _logError('Sign in failed: ${e.code}', e, stackTrace);
      throw Exception(errorMessage);
    } catch (e, stackTrace) {
      _logError('Unexpected error during sign in', e, stackTrace);
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _logInfo('Attempting sign out');
      await _auth.signOut();
      _logInfo('Sign out successful');
    } catch (e, stackTrace) {
      _logError('Error during sign out', e as Error, stackTrace);
      throw Exception('Failed to sign out. Please try again.');
    }
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc =
          await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        return null;
      }

      return UserModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Delete user account
  Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      // Get user data from Firestore before deletion
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final invitationCode = userData['invitationCode'] as String?;

        // If there's an invitation code, update its status back to active
        if (invitationCode != null) {
          final inviteQuery = await _firestore
              .collection('invites')
              .where('code', isEqualTo: invitationCode)
              .limit(1)
              .get();

          if (inviteQuery.docs.isNotEmpty) {
            await _firestore.collection('invites').doc(inviteQuery.docs.first.id).update({
              'status': 'active',
              'usedBy': null,
              'usedAt': null,
            });
          }
        }

        // Delete user document from Firestore
        await _firestore.collection('users').doc(user.uid).delete();
      }

      // Delete user from Firebase Auth
      await user.delete();
      
      // Sign out after deletion
      await _auth.signOut();
    } catch (e) {
      print('Error deleting user account: $e');
      rethrow;
    }
  }
} 