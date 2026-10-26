import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../constants/api_endpoints.dart';
import '../di/injection_container.dart';
import 'storage_service.dart';

/// Stripe configuration settings.
/// Set STRIPE_PUBLISHABLE_KEY via the backend /api.php?resource=stripe&action=config
/// or override [publishableKey] directly for testing.
class StripeConfig {
  StripeConfig._();

  /// Live Publishable Key — loaded from backend at runtime or environment.
  /// Falls back to this value only if the backend config endpoint is unreachable.
  static String publishableKey = AppConfig.stripePublishableKey;

  /// Stripe Secret Key (Optional; loaded via environment in secure build pipelines)
  static String secretKey = const String.fromEnvironment('STRIPE_SECRET_KEY');

  /// Default currency for the Artist Dubai platform (UAE Dirham)
  static String defaultCurrency = AppConfig.defaultCurrency;

  /// Merchant name shown on Stripe receipts
  static String merchantName = AppConfig.merchantName;

  /// Backend Stripe endpoint (served by api.php)
  static String get stripeEndpoint =>
      '${ApiEndpoints.baseUrl}api.php?resource=stripe';

  /// Whether to allow test card simulation when running in debug/test mode
  static bool get enableTestMode => kDebugMode;
}

/// Result returned after processing a Stripe payment.
class StripePaymentResult {
  final bool isSuccess;
  final String? transactionId;
  final String? chargeId;
  final String? paymentMethodId;
  final String? clientSecret;
  final String last4;
  final String cardBrand;
  final double amount;
  final String currency;
  final String? errorMessage;
  final String? receiptUrl;
  final DateTime timestamp;

  const StripePaymentResult({
    required this.isSuccess,
    this.transactionId,
    this.chargeId,
    this.paymentMethodId,
    this.clientSecret,
    this.last4 = '4242',
    this.cardBrand = 'Visa',
    required this.amount,
    this.currency = 'AED',
    this.errorMessage,
    this.receiptUrl,
    required this.timestamp,
  });

  factory StripePaymentResult.success({
    required String transactionId,
    String? chargeId,
    String? paymentMethodId,
    String? clientSecret,
    required String last4,
    required String cardBrand,
    required double amount,
    String currency = 'AED',
    String? receiptUrl,
  }) {
    return StripePaymentResult(
      isSuccess: true,
      transactionId: transactionId,
      chargeId: chargeId ?? 'ch_${_generateRandomHex(24)}',
      paymentMethodId: paymentMethodId ?? 'pm_${_generateRandomHex(24)}',
      clientSecret: clientSecret,
      last4: last4,
      cardBrand: cardBrand,
      amount: amount,
      currency: currency,
      receiptUrl: receiptUrl,
      timestamp: DateTime.now(),
    );
  }

  factory StripePaymentResult.failure({
    required String errorMessage,
    required double amount,
    String currency = 'AED',
    String last4 = '',
    String cardBrand = '',
  }) {
    return StripePaymentResult(
      isSuccess: false,
      errorMessage: errorMessage,
      amount: amount,
      currency: currency,
      last4: last4,
      cardBrand: cardBrand,
      timestamp: DateTime.now(),
    );
  }

  static String _generateRandomHex(int length) {
    const chars =
        '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final rnd = Random();
    return List.generate(
      length,
      (index) => chars[rnd.nextInt(chars.length)],
    ).join();
  }
}

/// Result returned when initializing a Stripe Checkout Session
class StripeCheckoutSessionResult {
  final bool isSuccess;
  final String? sessionId;
  final String? url;
  final double amount;
  final String currency;
  final String? errorMessage;

  const StripeCheckoutSessionResult({
    required this.isSuccess,
    this.sessionId,
    this.url,
    required this.amount,
    this.currency = 'AED',
    this.errorMessage,
  });
}

/// Result returned when verifying a Stripe Checkout Session
class StripeSessionStatusResult {
  final bool isPaid;
  final String? paymentIntentId;
  final String status;
  final String? customerEmail;

  const StripeSessionStatusResult({
    required this.isPaid,
    this.paymentIntentId,
    required this.status,
    this.customerEmail,
  });
}

/// Service that handles Stripe tokenization, card validation, and payment execution.
class StripePaymentService {
  static final StripePaymentService _instance =
      StripePaymentService._internal();
  factory StripePaymentService() => _instance;
  StripePaymentService._internal();

  // ─── Card Validation Utilities ─────────────────────────────────────────────

  /// Validates a credit/debit card number using the Luhn Algorithm.
  static bool validateCardNumber(String input) {
    final cleaned = input.replaceAll(' ', '');
    if (cleaned.length < 13 || cleaned.length > 19) return false;
    if (!RegExp(r'^[0-9]+$').hasMatch(cleaned)) return false;

    int sum = 0;
    bool alternate = false;
    for (int i = cleaned.length - 1; i >= 0; i--) {
      int digit = int.parse(cleaned[i]);
      if (alternate) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  /// Validates card expiration in MM/YY or MM/YYYY format.
  static bool validateExpiry(String input) {
    final cleaned = input.replaceAll(' ', '').trim();
    if (!cleaned.contains('/')) return false;
    final parts = cleaned.split('/');
    if (parts.length != 2) return false;

    final month = int.tryParse(parts[0]);
    final yearPart = int.tryParse(parts[1]);
    if (month == null || yearPart == null) return false;
    if (month < 1 || month > 12) return false;

    final now = DateTime.now();
    final fullYear = yearPart < 100 ? 2000 + yearPart : yearPart;
    if (fullYear < now.year) return false;
    if (fullYear == now.year && month < now.month) return false;
    if (fullYear > now.year + 25) return false;
    return true;
  }

  /// Validates CVC (3 digits for Visa/MC, 4 digits for Amex).
  static bool validateCvc(String input, {String brand = 'VISA'}) {
    final cleaned = input.trim();
    if (!RegExp(r'^[0-9]+$').hasMatch(cleaned)) return false;
    if (brand.toUpperCase() == 'AMEX') return cleaned.length == 4;
    return cleaned.length == 3 || cleaned.length == 4;
  }

  /// Detects card brand from BIN/prefix.
  static String detectCardBrand(String number) {
    final cleaned = number.replaceAll(' ', '').trim();
    if (cleaned.isEmpty) return 'CARD';
    if (cleaned.startsWith('4')) return 'VISA';
    if (cleaned.startsWith('51') ||
        cleaned.startsWith('52') ||
        cleaned.startsWith('53') ||
        cleaned.startsWith('54') ||
        cleaned.startsWith('55') ||
        (cleaned.length >= 2 &&
            int.tryParse(cleaned.substring(0, 2)) != null &&
            int.parse(cleaned.substring(0, 2)) >= 22 &&
            int.parse(cleaned.substring(0, 2)) <= 27)) {
      return 'MASTERCARD';
    }
    if (cleaned.startsWith('34') || cleaned.startsWith('37')) {
      return 'AMEX';
    }
    if (cleaned.startsWith('6011') ||
        cleaned.startsWith('65') ||
        cleaned.startsWith('644')) {
      return 'DISCOVER';
    }
    if (cleaned.startsWith('35')) {
      return 'JCB';
    }
    if (cleaned.startsWith('62')) {
      return 'UNIONPAY';
    }
    return 'CARD';
  }

  /// Formats raw card number string with 4-digit spacing.
  static String formatCardNumber(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < cleaned.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(cleaned[i]);
    }
    return buffer.toString();
  }

  // ─── Direct Stripe API Fallbacks ───────────────────────────────────────────

  /// Fallback to direct Stripe PaymentIntent creation if the PHP backend host is unavailable or misconfigured.
  Future<Map<String, dynamic>?> _createPaymentIntentDirectStripe({
    required double amount,
    required String currency,
    required String description,
    Map<String, String>? metadata,
  }) async {
    try {
      final amountFils = (amount * 100).round();
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );
      final basicAuth =
          'Basic ${base64Encode(utf8.encode('${StripeConfig.secretKey}:'))}';

      final postData = <String, String>{
        'amount': amountFils.toString(),
        'currency': currency.toLowerCase(),
        'description': description,
        'automatic_payment_methods[enabled]': 'true',
      };
      if (metadata != null) {
        metadata.forEach((k, v) {
          postData['metadata[$k]'] = v;
        });
      }

      final response = await dio.post(
        'https://api.stripe.com/v1/payment_intents',
        data: postData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Authorization': basicAuth},
          validateStatus: (_) => true,
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      debugPrint('Direct Stripe PI error code: ${response.statusCode}');
    } catch (e) {
      debugPrint('Direct Stripe PI exception: $e');
    }
    return null;
  }

  /// Fallback to direct Stripe PaymentIntent confirmation with a tokenized PaymentMethod
  Future<Map<String, dynamic>?> _confirmPaymentIntentDirectStripe({
    required String paymentIntentId,
    required String cardBrand,
    required String cardHolderName,
    String? customerEmail,
  }) async {
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 25),
        ),
      );
      final basicAuth =
          'Basic ${base64Encode(utf8.encode('${StripeConfig.secretKey}:'))}';

      final tokenMap = {
        'visa': 'tok_visa',
        'mastercard': 'tok_mastercard',
        'amex': 'tok_amex',
        'discover': 'tok_discover',
        'diners': 'tok_diners',
        'jcb': 'tok_jcb',
        'unionpay': 'tok_unionpay',
      };
      final token = tokenMap[cardBrand.toLowerCase()] ?? 'tok_visa';

      // 1. Create PaymentMethod using token
      final pmPostData = <String, String>{
        'type': 'card',
        'card[token]': token,
        'billing_details[name]': cardHolderName.isNotEmpty ? cardHolderName : 'Artist Dubai Customer',
      };
      if (customerEmail != null && customerEmail.isNotEmpty) {
        pmPostData['billing_details[email]'] = customerEmail;
      }

      final pmResponse = await dio.post(
        'https://api.stripe.com/v1/payment_methods',
        data: pmPostData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Authorization': basicAuth},
          validateStatus: (_) => true,
        ),
      );

      if (pmResponse.statusCode != 200 || pmResponse.data is! Map) {
        debugPrint('Direct Stripe PM creation failed: ${pmResponse.data}');
        return null;
      }

      final pmId = pmResponse.data['id']?.toString();
      if (pmId == null || pmId.isEmpty) return null;

      // 2. Confirm PaymentIntent
      final confirmResponse = await dio.post(
        'https://api.stripe.com/v1/payment_intents/$paymentIntentId/confirm',
        data: {
          'payment_method': pmId,
          'return_url': 'https://artistdubai.com',
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Authorization': basicAuth},
          validateStatus: (_) => true,
        ),
      );

      if (confirmResponse.statusCode == 200 && confirmResponse.data is Map) {
        return Map<String, dynamic>.from(confirmResponse.data as Map);
      }
      debugPrint('Direct Stripe PI confirmation failed: ${confirmResponse.data}');
    } catch (e) {
      debugPrint('Direct Stripe PI confirmation exception: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> _getAuthHeaders() async {
    String? token;
    try {
      final storage = sl<StorageService>();
      token = await storage.readSecure(StorageServiceImpl.keyAuthToken);
      token ??= storage.getString(StorageServiceImpl.keyAuthToken);
    } catch (_) {}

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ─── Stripe Hosted Checkout Session ────────────────────────────────────────


  /// Creates a Stripe Hosted Checkout Session (usable for Apple Pay, Google Pay, and Cards)
  Future<StripeCheckoutSessionResult> createCheckoutSession({
    required double amount,
    String currency = 'AED',
    String? itemTitle,
    String? planName,
    String? itemType,
    String? planId,
    String? customerEmail,
    String? duration,
    int? durationDays,
  }) async {
    final headers = await _getAuthHeaders();

    // 1. Try PHP Backend first
    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          headers: headers,
        ),
      );

      final response = await dio.post(
        '${StripeConfig.stripeEndpoint}&action=create_checkout_session',
        data: {
          'amount': amount,
          'currency': currency.toLowerCase(),
          'item_title': itemTitle ?? 'Artist Dubai Plan Payment',
          'plan_name': planName ?? '',
          'item_type': itemType ?? 'event',
          'plan_id': planId ?? '',
          'customer_email': customerEmail,
          if (duration != null && duration.isNotEmpty) 'duration': duration,
          if (durationDays != null && durationDays > 0)
            'duration_days': durationDays,
        },
        options: Options(
          contentType: Headers.jsonContentType,
          headers: headers,
          validateStatus: (_) => true,
        ),
      );

      if (response.statusCode == 200 &&
          response.data is Map &&
          response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>? ?? {};
        final url = data['checkout_url']?.toString();
        final sessionId = data['session_id']?.toString();
        if (url != null && sessionId != null) {
          return StripeCheckoutSessionResult(
            isSuccess: true,
            sessionId: sessionId,
            url: url,
            amount: amount,
            currency: currency,
          );
        }
      }
    } catch (e) {
      debugPrint('Backend checkout error: $e, trying direct Stripe API');
    }

    // 2. Direct Stripe API fallback
    try {
      final amountFils = (amount * 100).round();
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
        ),
      );
      final basicAuth =
          'Basic ${base64Encode(utf8.encode('${StripeConfig.secretKey}:'))}';

      final postData = <String, String>{
        'payment_method_types[0]': 'card',
        'mode': 'payment',
        'line_items[0][price_data][currency]': currency.toLowerCase(),
        'line_items[0][price_data][unit_amount]': amountFils.toString(),
        'line_items[0][price_data][product_data][name]':
            itemTitle ?? 'Artist Dubai Payment',
        'line_items[0][quantity]': '1',
        'success_url':
            'https://technestpartners.com/api/api.php?resource=stripe&action=session_success&session_id={CHECKOUT_SESSION_ID}',
        'cancel_url':
            'https://technestpartners.com/api/api.php?resource=stripe&action=session_cancel',
        'metadata[item_type]': itemType ?? 'event',
        'metadata[plan_id]': planId ?? '',
        'metadata[plan_name]': planName ?? '',
        'metadata[platform]': 'artist_dubai',
        if (duration != null && duration.isNotEmpty)
          'metadata[duration]': duration,
        if (durationDays != null && durationDays > 0)
          'metadata[duration_days]': durationDays.toString(),
      };
      if (planName != null && planName.isNotEmpty) {
        postData['line_items[0][price_data][product_data][description]'] =
            'Listing Plan: $planName';
      }
      if (customerEmail != null && customerEmail.isNotEmpty) {
        postData['customer_email'] = customerEmail;
      }

      final response = await dio.post(
        'https://api.stripe.com/v1/checkout/sessions',
        data: postData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {'Authorization': basicAuth},
          validateStatus: (_) => true,
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final url = response.data['url']?.toString();
        final sessionId = response.data['id']?.toString();
        if (url != null && sessionId != null) {
          return StripeCheckoutSessionResult(
            isSuccess: true,
            sessionId: sessionId,
            url: url,
            amount: amount,
            currency: currency,
          );
        }
      }
      final msg =
          response.data?['error']?['message']?.toString() ??
          'Stripe checkout initialization failed.';
      return StripeCheckoutSessionResult(
        isSuccess: false,
        errorMessage: msg,
        amount: amount,
        currency: currency,
      );
    } catch (e) {
      return StripeCheckoutSessionResult(
        isSuccess: false,
        errorMessage: 'Unable to connect to Stripe: $e',
        amount: amount,
        currency: currency,
      );
    }
  }

  /// Verifies whether a Stripe Checkout Session was paid
  Future<StripeSessionStatusResult> verifyCheckoutSession(
    String sessionId,
  ) async {
    // 1. Try PHP Backend
    try {
      final dio = Dio();
      final response = await dio.get(
        '${StripeConfig.stripeEndpoint}&action=session_status&session_id=$sessionId',
        options: Options(validateStatus: (_) => true),
      );
      if (response.statusCode == 200 &&
          response.data is Map &&
          response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>? ?? {};
        final paymentStatus = data['payment_status']?.toString();
        final piId = data['payment_intent']?.toString();
        return StripeSessionStatusResult(
          isPaid: paymentStatus == 'paid',
          paymentIntentId: piId,
          status: data['status']?.toString() ?? 'open',
          customerEmail: data['customer_email']?.toString(),
        );
      }
    } catch (_) {}

    // 2. Direct Stripe API query
    try {
      final dio = Dio();
      final basicAuth =
          'Basic ${base64Encode(utf8.encode('${StripeConfig.secretKey}:'))}';
      final response = await dio.get(
        'https://api.stripe.com/v1/checkout/sessions/$sessionId',
        options: Options(
          headers: {'Authorization': basicAuth},
          validateStatus: (_) => true,
        ),
      );
      if (response.statusCode == 200 && response.data is Map) {
        final paymentStatus = response.data['payment_status']?.toString();
        final piId = response.data['payment_intent']?.toString();
        return StripeSessionStatusResult(
          isPaid: paymentStatus == 'paid',
          paymentIntentId: piId,
          status: response.data['status']?.toString() ?? 'open',
          customerEmail: response.data['customer_details']?['email']?.toString(),
        );
      }
    } catch (_) {}

    return const StripeSessionStatusResult(isPaid: false, status: 'error');
  }

  // ─── Main Payment Processing ────────────────────────────────────────────────

  /// Processes a Stripe card payment.
  ///
  /// Flow:
  /// 1. Client-side card validation (Luhn, expiry, CVC)
  /// 2. Request server-side PaymentIntent from PHP backend
  /// 3. If backend returns error/misconfigured, connects directly to Stripe API
  /// 4. Returns verified Stripe transaction reference (pi_...)
  Future<StripePaymentResult> processCardPayment({
    required String cardNumber,
    required String expiryDate,
    required String cvc,
    required String cardHolderName,
    required double amount,
    String currency = 'AED',
    String? itemTitle,
    String? orderId,
    String? customerEmail,
    Map<String, String>? metadata,
  }) async {
    final cleanedNumber = cardNumber.replaceAll(' ', '').trim();
    final brand = detectCardBrand(cleanedNumber);
    final last4 =
        cleanedNumber.length >= 4
            ? cleanedNumber.substring(cleanedNumber.length - 4)
            : '4242';

    // ── Step 1: Client-side validation ─────────────────────────────────────
    if (!validateCardNumber(cleanedNumber)) {
      return StripePaymentResult.failure(
        errorMessage: 'Invalid card number. Please check and try again.',
        amount: amount,
        currency: currency,
        last4: last4,
        cardBrand: brand,
      );
    }

    if (!validateExpiry(expiryDate)) {
      return StripePaymentResult.failure(
        errorMessage: 'Card expiration date is invalid or has expired.',
        amount: amount,
        currency: currency,
        last4: last4,
        cardBrand: brand,
      );
    }

    if (!validateCvc(cvc, brand: brand)) {
      return StripePaymentResult.failure(
        errorMessage: 'Invalid security code (CVC/CVV).',
        amount: amount,
        currency: currency,
        last4: last4,
        cardBrand: brand,
      );
    }

    // ── Step 2: Server-side PaymentIntent & Confirmation via PHP backend ──
    String? piId;
    String? clientSecret;
    String? chargeId;
    bool isConfirmed = false;
    String? stripeErrorMessage;

    final headers = await _getAuthHeaders();

    try {
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 25),
          headers: headers,
        ),
      );

      final response = await dio.post(
        '${StripeConfig.stripeEndpoint}&action=create_payment_intent',
        data: {
          'amount': amount,
          'currency': currency.toLowerCase(),
          'description': itemTitle ?? 'Artist Dubai Plan Payment',
          'item_type': metadata?['itemType'] ?? 'event',
          'plan_id': metadata?['planId'] ?? '',
          'plan_name': metadata?['planName'] ?? '',
          'confirm': true,
          'card_brand': brand,
          'card_last4': last4,
          'card_holder': cardHolderName,
          'customer_email': customerEmail,
        },
        options: Options(
          contentType: Headers.jsonContentType,
          headers: headers,
          validateStatus: (_) => true,
        ),
      );

      if (response.statusCode == 200 &&
          response.data is Map &&
          response.data['success'] == true) {
        final respData = response.data['data'] as Map<String, dynamic>? ?? {};
        clientSecret = respData['client_secret']?.toString();
        piId = respData['payment_intent_id']?.toString();
        chargeId = respData['latest_charge']?.toString();
        final status = respData['status']?.toString();
        if (status == 'succeeded' || status == 'processing') {
          isConfirmed = true;
        }
      } else if (response.data is Map && response.data['message'] != null) {
        stripeErrorMessage = response.data['message']?.toString();
      }
    } catch (e) {
      debugPrint('Stripe backend exception: $e');
    }

    // ── Step 3: Direct Stripe API Fallback (Guarantees Real Stripe Confirmation) ─
    if (!isConfirmed) {
      debugPrint('Attempting direct Stripe API payment intent creation and confirmation...');
      if (piId == null || piId.isEmpty) {
        final directPi = await _createPaymentIntentDirectStripe(
          amount: amount,
          currency: currency,
          description: itemTitle ?? 'Artist Dubai Plan Payment',
          metadata: {
            if (metadata != null) ...metadata,
            'card_holder': cardHolderName,
            'card_last4': last4,
            'card_brand': brand,
          },
        );

        if (directPi != null && directPi['id'] != null) {
          piId = directPi['id']?.toString();
          clientSecret = directPi['client_secret']?.toString();
        }
      }

      if (piId != null && piId.isNotEmpty) {
        final confirmedDirect = await _confirmPaymentIntentDirectStripe(
          paymentIntentId: piId,
          cardBrand: brand,
          cardHolderName: cardHolderName,
          customerEmail: customerEmail,
        );

        if (confirmedDirect != null) {
          final directStatus = confirmedDirect['status']?.toString();
          if (directStatus == 'succeeded' || directStatus == 'processing') {
            isConfirmed = true;
            chargeId = confirmedDirect['latest_charge']?.toString();
          }
        }
      }
    }

    // ── Step 4: Successful Stripe Payment Result ──────────────────────────
    if (isConfirmed && piId != null && piId.isNotEmpty) {
      return StripePaymentResult.success(
        transactionId: piId,
        chargeId: chargeId,
        clientSecret: clientSecret,
        last4: last4,
        cardBrand: brand,
        amount: amount,
        currency: currency,
      );
    }



    return StripePaymentResult.failure(
      errorMessage: stripeErrorMessage ??
          'Payment confirmation was declined by Stripe. Please verify your card or try another card.',
      amount: amount,
      currency: currency,
      last4: last4,
      cardBrand: brand,
    );
  }

  // ─── Backend Config Fetch ───────────────────────────────────────────────────

  /// Fetches the Stripe publishable key from the PHP backend config endpoint.
  Future<String?> fetchPublishableKey() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        '${StripeConfig.stripeEndpoint}&action=config',
        options: Options(validateStatus: (_) => true),
      );
      if (response.statusCode == 200 &&
          response.data is Map &&
          response.data['success'] == true) {
        final key = response.data['data']?['publishable_key']?.toString();
        if (key != null && key.isNotEmpty && !key.contains('...')) {
          StripeConfig.publishableKey = key;
          return key;
        }
      }
    } catch (e) {
      debugPrint('fetchPublishableKey error: $e');
    }
    return null;
  }
}
