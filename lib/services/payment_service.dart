import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:poolqapp/constants/payment_status.dart';
import 'package:poolqapp/services/app_config_service.dart';
import '../services/scoring_service.dart';

class PaymentService {
  // Singleton pattern
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Single source of truth for payment handles (all UIs must use these).
  static const String PAYPAL_EMAIL = 'poolq.payments@gmail.com';
  static const String ZELLE_EMAIL = 'poolq.payments@gmail.com';
  static const String CASHAPP_HANDLE = '\$PoolQPayments';
  static const String VENMO_URL = 'https://venmo.com/u/PoolQPayments';
  static const double ENTRY_FEE = 10.0;

  // Admin notification email
  static const String ADMIN_EMAIL = 'admin@poolq.com';

  /// Deterministic pick document id — one entry per user per week.
  static String pickDocumentId(String uid, String weekName) => '${uid}_$weekName';

  /// Save user picks and create pending payment entry
  Future<String> savePicksAndCreatePaymentEntry({
    required List<String> picks,
    required String tiebreaker,
    required String weekName,
  }) async {
    try {
      final user = _auth.currentUser;
      
      // Handle demo mode - create unique demo entries
      if (user == null || user.email == 'demo@poolq.com') {
        return await _saveDemoPicksEntry(picks: picks, tiebreaker: tiebreaker, weekName: weekName);
      }

      // Validate picks before saving
      final scoringService = ScoringService();
      final isValid = await scoringService.validatePicks(picks, weekName);
      if (!isValid) {
        throw Exception('Invalid picks. Please ensure you have selected exactly one team for each game.');
      }

      final config = AppConfigService();
      if (!config.isLoaded) {
        await config.load();
      }
      final autoVerify = config.preseasonFree && weekName.startsWith('PRE');
      final status =
          autoVerify ? PaymentStatus.autoVerified : PaymentStatus.pending;

      final docId = pickDocumentId(user.uid, weekName);
      final picksData = {
        'uid': user.uid,
        'displayName': user.displayName ?? 'Unknown',
        'photoURL': user.photoURL ?? '',
        'week': weekName,
        'picks': picks,
        'tiebreaker': int.tryParse(tiebreaker) ?? 0,
        'submittedAt': FieldValue.serverTimestamp(),
        'paymentStatus': status,
        'entryFee': autoVerify ? 0.0 : ENTRY_FEE,
        'isActive': true,
        'score': null,
        'rank': null,
        'tiebreakerDiff': null,
      };

      final batch = _firestore.batch();
      final pickRef = _firestore.collection('pickrecord').doc(docId);
      batch.set(pickRef, picksData, SetOptions(merge: true));

      final trackingRef = _firestore.collection('payment_tracking').doc(docId);
      batch.set(trackingRef, {
        'pickRecordId': docId,
        'uid': user.uid,
        'displayName': user.displayName ?? 'Unknown',
        'week': weekName,
        'amount': autoVerify ? 0.0 : ENTRY_FEE,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
        'adminVerified': autoVerify,
      }, SetOptions(merge: true));

      await batch.commit();

      if (!autoVerify) {
        await _sendAdminNotification(
          userDisplayName: user.displayName ?? 'Unknown',
          userEmail: user.email ?? '',
          weekName: weekName,
          pickRecordId: docId,
        );
      }

      return docId;
    } catch (e) {
      throw Exception('Failed to save picks: $e');
    }
  }

  /// Player reports that external payment was sent.
  Future<void> reportPaymentSent(String pickRecordId) async {
    final batch = _firestore.batch();
    final pickRef = _firestore.collection('pickrecord').doc(pickRecordId);
    final trackingRef =
        _firestore.collection('payment_tracking').doc(pickRecordId);

    batch.set(
      pickRef,
      {
        'paymentStatus': PaymentStatus.sent,
        'paymentReportedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      trackingRef,
      {
        'status': PaymentStatus.sent,
        'paymentReportedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
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
        .where('paymentStatus', isEqualTo: PaymentStatus.pending)
        .get();

    return query.docs.isNotEmpty;
  }

  /// Get user's payment status for a week
  Future<String?> getPaymentStatus(String weekName) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore
        .collection('pickrecord')
        .doc(pickDocumentId(user.uid, weekName))
        .get();

    if (doc.exists) {
      return doc.data()?['paymentStatus'] as String?;
    }
    return null;
  }

  /// Verify payment for a pick record (Admin function)
  Future<bool> verifyPayment(String pickRecordId, String adminId) async {
    try {
      debugPrint('Verifying payment for pick record: $pickRecordId');
      
      // Update pick record status
      await _firestore.collection('pickrecord').doc(pickRecordId).update({
        'paymentStatus': PaymentStatus.verified,
        'verifiedAt': FieldValue.serverTimestamp(),
        'verifiedBy': adminId,
      });

      // Update payment tracking
      await _firestore.collection('payment_tracking').doc(pickRecordId).update({
        'status': PaymentStatus.verified,
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
        'paymentStatus': PaymentStatus.rejected,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': adminId,
        'rejectionReason': reason,
      });

      // Update payment tracking
      await _firestore.collection('payment_tracking').doc(pickRecordId).update({
        'status': PaymentStatus.rejected,
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
          .where('paymentStatus', whereIn: [
            PaymentStatus.pending,
            PaymentStatus.sent,
          ])
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

  /// Save demo picks entry with unique identifier for testing
  Future<String> _saveDemoPicksEntry({
    required List<String> picks,
    required String tiebreaker,
    required String weekName,
  }) async {
    try {
      // Create unique demo user data
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final demoNames = [
        'Alex Johnson', 'Casey Smith', 'Jordan Brown', 'Taylor Davis', 'Morgan Wilson',
        'Riley Martinez', 'Cameron Garcia', 'Avery Rodriguez', 'Quinn Anderson', 'Parker Lopez',
        'Sage Hernandez', 'Drew Gonzalez', 'Blake Clark', 'Emery Lewis', 'Finley Walker',
        'Hayden Hall', 'Kendall Allen', 'Logan Young', 'Peyton King', 'River Wright'
      ];
      
      final nameIndex = timestamp % demoNames.length;
      final demoName = '${demoNames[nameIndex]} #${(timestamp / 1000).round()}';
      final demoUid = 'demo_${timestamp}';

      // Vary the tiebreaker slightly for realistic testing
      final baseTiebreaker = int.tryParse(tiebreaker) ?? 0;
      final randomVariation = (timestamp % 21) - 10; // -10 to +10
      final finalTiebreaker = baseTiebreaker + randomVariation;

      // Create demo picks document with verified status for testing
      final picksData = {
        'uid': demoUid,
        'displayName': demoName,
        'photoURL': '',
        'week': weekName,
        'picks': picks,
        'tiebreaker': finalTiebreaker,
        'submittedAt': FieldValue.serverTimestamp(),
        'paymentStatus': PaymentStatus.verified,
        'entryFee': ENTRY_FEE,
        'isActive': true,
        'score': null,
        'rank': null,
        'tiebreakerDiff': null,
        'isDemoEntry': true,
      };

      // Unique demo docs (intentional for testing many entrants)
      final docRef = await _firestore.collection('pickrecord').add(picksData);

      await _firestore.collection('payment_tracking').doc(docRef.id).set({
        'pickRecordId': docRef.id,
        'uid': demoUid,
        'displayName': demoName,
        'week': weekName,
        'amount': ENTRY_FEE,
        'status': PaymentStatus.verified,
        'createdAt': FieldValue.serverTimestamp(),
        'adminVerified': true,
        'isDemoEntry': true,
      });

      print('Created demo entry: $demoName with picks: $picks, tiebreaker: $finalTiebreaker');
      return docRef.id;
    } catch (e) {
      print('Demo mode: Failed to save picks (expected without Firebase): $e');
      // Return a mock ID for demo mode
      return 'demo_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
} 