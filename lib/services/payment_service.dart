import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class PaymentService {
  // Singleton pattern
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  // Initialize Stripe with publishable key
  Future<void> initializeStripe() async {
    // Ensure .env is loaded
    await dotenv.load(fileName: "assets/.env");
    
    // Get Stripe publishable key from environment
    final stripePublishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
    
    if (stripePublishableKey.isEmpty) {
      debugPrint('Error: Stripe publishable key is empty');
      return;
    }

    // Initialize Stripe
    Stripe.publishableKey = stripePublishableKey;
  }

  // Create payment intent
  Future<Map<String, dynamic>> createPaymentIntent(
    String amount,
    String currency,
  ) async {
    try {
      // Get Stripe secret key from environment
      final stripeSecretKey = dotenv.env['STRIPE_SECRET_KEY'] ?? '';
      
      if (stripeSecretKey.isEmpty) {
        throw Exception('Stripe secret key is empty');
      }

      // Create payment intent
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer $stripeSecretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': amount,
          'currency': currency,
          'payment_method_types[]': 'card',
        },
      );

      // Return response
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Error creating payment intent: $e');
      rethrow;
    }
  }

  // Process payment
  Future<bool> processPayment(String amount, String currency) async {
    try {
      // Create payment intent
      final paymentIntent = await createPaymentIntent(amount, currency);
      
      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'PoolQ',
          style: ThemeMode.light,
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();
      
      // Payment succeeded
      return true;
    } catch (e) {
      debugPrint('Error processing payment: $e');
      return false;
    }
  }
} 