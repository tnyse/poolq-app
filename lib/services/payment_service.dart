// All Stripe-related code has been removed from this service.
// If payment logic is needed in the future, implement here.

class PaymentService {
  // Singleton pattern
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();
} 