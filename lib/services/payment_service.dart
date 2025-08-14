import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../services/scoring_service.dart';

class PaymentService {
  // Singleton pattern
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Payment methods configuration
  static const String PAYPAL_EMAIL = 'poolq.payments@gmail.com';
  static const String ZELLE_EMAIL = 'poolq.payments@gmail.com';
  static const String CASHAPP_HANDLE = '\$PoolQPayments';
  static const String VENMO_URL = 'https://venmo.com/u/PoolQPayments';
  static const double ENTRY_FEE = 10.0;

  // Admin notification email
  static const String ADMIN_EMAIL = 'admin@poolq.com';

  /// Save user picks and create pending payment entry
  Future<String> savePicksAndCreatePaymentEntry({
    required List<String> picks,
    required String tiebreaker,
    required String weekName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Validate picks before saving
      final scoringService = ScoringService();
      final isValid = await scoringService.validatePicks(picks, weekName);
      if (!isValid) {
        throw Exception('Invalid picks. Please ensure you have selected exactly one team for each game.');
      }

      // Create picks document with pending payment status
      final picksData = {
        'uid': user.uid,
        'displayName': user.displayName ?? 'Unknown',
        'photoURL': user.photoURL ?? '',
        'week': weekName,
        'picks': picks,
        'tiebreaker': int.tryParse(tiebreaker) ?? 0,
        'submittedAt': FieldValue.serverTimestamp(),
        'paymentStatus': 'pending', // pending, paid, verified, disqualified
        'entryFee': ENTRY_FEE,
        'isActive': true,
        'score': null,
        'rank': null,
        'tiebreakerDiff': null,
      };

      // Save to pickrecord collection
      DocumentReference docRef = await _firestore.collection('pickrecord').add(picksData);

      // Create payment tracking document
      await _firestore.collection('payment_tracking').doc(docRef.id).set({
        'pickRecordId': docRef.id,
        'uid': user.uid,
        'displayName': user.displayName ?? 'Unknown',
        'week': weekName,
        'amount': ENTRY_FEE,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'adminVerified': false,
      });

      // Send admin notification email
      await _sendAdminNotification(
        userDisplayName: user.displayName ?? 'Unknown',
        userEmail: user.email ?? '',
        weekName: weekName,
        pickRecordId: docRef.id,
      );

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save picks: $e');
    }
  }

  /// Get payment methods for display
  Map<String, dynamic> getPaymentMethods() {
    return {
      'venmo': {
        'name': 'Venmo',
        'identifier': VENMO_URL,
        'instructions': 'Send \$${ENTRY_FEE.toStringAsFixed(2)} via Venmo link and include your name in the note.'
      },
      'paypal': {
        'name': 'PayPal',
        'identifier': PAYPAL_EMAIL,
        'instructions': 'Send \$${ENTRY_FEE.toStringAsFixed(2)} to $PAYPAL_EMAIL\nUse "PoolQ Entry - [Your Name]" as the note',
      },
      'zelle': {
        'name': 'Zelle',
        'identifier': ZELLE_EMAIL,
        'instructions': 'Send \$${ENTRY_FEE.toStringAsFixed(2)} to $ZELLE_EMAIL\nUse "PoolQ Entry - [Your Name]" as the note',
      },
      'cashapp': {
        'name': 'Cash App',
        'identifier': CASHAPP_HANDLE,
        'instructions': 'Send \$${ENTRY_FEE.toStringAsFixed(2)} to $CASHAPP_HANDLE\nUse "PoolQ Entry - [Your Name]" as the note',
      },
    };
  }

  /// Copy payment information to clipboard
  Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Launch payment app URLs (simplified without url_launcher)
  Future<bool> launchPaymentApp(String paymentMethod) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    // For now, we'll just copy relevant information to clipboard
    String textToCopy = '';
    switch (paymentMethod.toLowerCase()) {
      case 'venmo':
        textToCopy = VENMO_URL;
        break;
      case 'paypal':
        textToCopy = PAYPAL_EMAIL;
        break;
      case 'cashapp':
        textToCopy = CASHAPP_HANDLE;
        break;
      case 'zelle':
        textToCopy = ZELLE_EMAIL;
        break;
    }

    if (textToCopy.isNotEmpty) {
      await copyToClipboard(textToCopy);
      return true;
    }
    return false;
  }

  /// Send admin notification (simplified - creates Firestore notification)
  Future<void> _sendAdminNotification({
    required String userDisplayName,
    required String userEmail,
    required String weekName,
    required String pickRecordId,
  }) async {
    try {
      // Create admin notification in Firestore instead of email
      await _firestore.collection('admin_notifications').add({
        'type': 'pending_payment',
        'userDisplayName': userDisplayName,
        'userEmail': userEmail,
        'week': weekName,
        'pickRecordId': pickRecordId,
        'entryFee': ENTRY_FEE,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'paymentMethods': {
          'paypal': PAYPAL_EMAIL,
          'zelle': ZELLE_EMAIL,
          'cashapp': CASHAPP_HANDLE,
        }
      });
      
      print('Admin notification created in Firestore for pick record: $pickRecordId');
    } catch (e) {
      print('Failed to send admin notification: $e');
      // Don't throw here - we don't want to fail the whole process if notification fails
    }
  }

  /// Check if user has pending payment for a week
  Future<bool> hasPendingPayment(String weekName) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final query = await _firestore
        .collection('pickrecord')
        .where('uid', isEqualTo: user.uid)
        .where('week', isEqualTo: weekName)
        .where('paymentStatus', isEqualTo: 'pending')
        .get();

    return query.docs.isNotEmpty;
  }

  /// Get user's payment status for a week
  Future<String?> getPaymentStatus(String weekName) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final query = await _firestore
        .collection('pickrecord')
        .where('uid', isEqualTo: user.uid)
        .where('week', isEqualTo: weekName)
        .orderBy('submittedAt', descending: true)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.data()['paymentStatus'] as String?;
    }
    return null;
  }

  /// Verify payment for a pick record (Admin function)
  Future<bool> verifyPayment(String pickRecordId, String adminId) async {
    try {
      debugPrint('Verifying payment for pick record: $pickRecordId');
      
      // Update pick record status
      await _firestore.collection('pickrecord').doc(pickRecordId).update({
        'paymentStatus': 'verified',
        'verifiedAt': FieldValue.serverTimestamp(),
        'verifiedBy': adminId,
      });

      // Update payment tracking
      await _firestore.collection('payment_tracking').doc(pickRecordId).update({
        'status': 'verified',
        'adminVerified': true,
        'verifiedAt': FieldValue.serverTimestamp(),
        'verifiedBy': adminId,
      });

      // Mark admin notification as read
      final notificationQuery = await _firestore
          .collection('admin_notifications')
          .where('pickRecordId', isEqualTo: pickRecordId)
          .where('type', isEqualTo: 'pending_payment')
          .get();

      for (var doc in notificationQuery.docs) {
        await doc.reference.update({'read': true});
      }

      debugPrint('Payment verified successfully for pick record: $pickRecordId');
      return true;
    } catch (e) {
      debugPrint('Error verifying payment: $e');
      return false;
    }
  }

  /// Reject payment for a pick record (Admin function)
  Future<bool> rejectPayment(String pickRecordId, String adminId, String reason) async {
    try {
      debugPrint('Rejecting payment for pick record: $pickRecordId');
      
      // Update pick record status
      await _firestore.collection('pickrecord').doc(pickRecordId).update({
        'paymentStatus': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': adminId,
        'rejectionReason': reason,
      });

      // Update payment tracking
      await _firestore.collection('payment_tracking').doc(pickRecordId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': adminId,
        'rejectionReason': reason,
      });

      // Mark admin notification as read
      final notificationQuery = await _firestore
          .collection('admin_notifications')
          .where('pickRecordId', isEqualTo: pickRecordId)
          .where('type', isEqualTo: 'pending_payment')
          .get();

      for (var doc in notificationQuery.docs) {
        await doc.reference.update({'read': true});
      }

      debugPrint('Payment rejected for pick record: $pickRecordId');
      return true;
    } catch (e) {
      debugPrint('Error rejecting payment: $e');
      return false;
    }
  }

  /// Get pending payments for admin review
  Future<List<Map<String, dynamic>>> getPendingPayments() async {
    try {
      final query = await _firestore
          .collection('pickrecord')
          .where('paymentStatus', isEqualTo: 'pending')
          .orderBy('submittedAt', descending: true)
          .get();

      List<Map<String, dynamic>> pendingPayments = [];
      
      for (var doc in query.docs) {
        final data = doc.data();
        pendingPayments.add({
          'pickRecordId': doc.id,
          'userId': data['uid'],
          'displayName': data['displayName'],
          'weekName': data['week'],
          'entryFee': data['entryFee'],
          'submittedAt': data['submittedAt'],
          'picks': data['picks'],
          'tiebreaker': data['tiebreaker'],
        });
      }

      return pendingPayments;
    } catch (e) {
      debugPrint('Error getting pending payments: $e');
      return [];
    }
  }
} 