/// Canonical payment status values for pickrecord / payment_tracking.
class PaymentStatus {
  static const String pending = 'pending';
  static const String sent = 'sent';
  static const String verified = 'verified';
  static const String rejected = 'rejected';
  static const String autoVerified = 'auto_verified';
  static const String disqualified = 'disqualified';

  static bool isEligible(String? status) =>
      status == verified || status == autoVerified;
}
