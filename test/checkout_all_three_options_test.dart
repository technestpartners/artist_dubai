import 'package:flutter_test/flutter_test.dart';
import 'package:artist_dubai/core/config/app_config.dart';
import 'package:artist_dubai/core/services/stripe_payment_service.dart';

void main() {
  group('Payment & Checkout - All 3 Options E2E Verification', () {
    test('1. StripeConfig & Keys are configured and non-empty', () {
      expect(StripeConfig.publishableKey, isNotEmpty);
      expect(StripeConfig.publishableKey, startsWith('pk_test_'));
      expect(StripeConfig.secretKey, isNotEmpty);
      expect(StripeConfig.secretKey, startsWith('sk_'));
      expect(AppConfig.stripeSecretKey, endsWith('jkXy'));
    });

    test('2. Option 1 & 2 (Apple Pay & Stripe Link) - Checkout Session creates real Stripe session', () async {
      final service = StripePaymentService();
      final sessionResult = await service.createCheckoutSession(
        amount: 5250.0,
        currency: 'AED',
        itemTitle: 'Dubai Contemporary Art Fair 2026',
        planName: 'Platinum Plan',
        itemType: 'event',
        planId: 'platinum',
        customerEmail: 'info@i-mbu.com',
        duration: '30 Days',
        durationDays: 30,
      );

      expect(sessionResult.isSuccess, isTrue, reason: 'Checkout session should succeed');
      expect(sessionResult.url, isNotNull);
      expect(sessionResult.url, contains('checkout.stripe.com'));
      expect(sessionResult.sessionId, isNotNull);
      expect(sessionResult.sessionId, startsWith('cs_test_'));
      expect(sessionResult.amount, 5250.0);
      expect(sessionResult.currency, 'AED');
    });

    test('3. Option 3 (In-App Card Payment) - Direct card payment processes and succeeds', () async {
      final service = StripePaymentService();
      final cardResult = await service.processCardPayment(
        cardNumber: '4242 4242 4242 4242',
        expiryDate: '12 / 28',
        cvc: '123',
        cardHolderName: 'Allen',
        amount: 5250.0,
        currency: 'AED',
        itemTitle: 'Dubai Contemporary Art Fair 2026 (Platinum Plan)',
        customerEmail: 'info@i-mbu.com',
        metadata: {
          'itemType': 'event',
          'planId': 'platinum',
          'planName': 'Platinum Plan',
          'totalAmount': '5250.0',
        },
      );

      expect(cardResult.isSuccess, isTrue, reason: 'Card payment should succeed with test card');
      expect(cardResult.transactionId, isNotNull);
      expect(cardResult.transactionId, startsWith('pi_'));
      expect(cardResult.cardBrand, 'VISA');
      expect(cardResult.last4, '4242');
      expect(cardResult.amount, 5250.0);
      expect(cardResult.currency, 'AED');
    });
  });
}
