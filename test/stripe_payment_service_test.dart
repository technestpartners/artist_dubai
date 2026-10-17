import 'package:flutter_test/flutter_test.dart';
import 'package:artist_dubai/core/services/stripe_payment_service.dart';

void main() {
  group('StripePaymentService Unit Tests', () {
    test('Validates Luhn algorithm for card numbers correctly', () {
      // Valid Visa test card
      expect(StripePaymentService.validateCardNumber('4242424242424242'), isTrue);
      // Valid formatted Visa test card
      expect(StripePaymentService.validateCardNumber('4242 4242 4242 4242'), isTrue);
      // Invalid length or non-digits
      expect(StripePaymentService.validateCardNumber('1234'), isFalse);
      expect(StripePaymentService.validateCardNumber('abcd efgh ijkl mnop'), isFalse);
    });

    test('Detects card brands accurately', () {
      expect(StripePaymentService.detectCardBrand('4242 4242 4242 4242'), 'VISA');
      expect(StripePaymentService.detectCardBrand('5500 0000 0000 0004'), 'MASTERCARD');
      expect(StripePaymentService.detectCardBrand('3782 822463 10005'), 'AMEX');
      expect(StripePaymentService.detectCardBrand(''), 'CARD');
    });

    test('Validates expiration date formats', () {
      expect(StripePaymentService.validateExpiry('12/28'), isTrue);
      expect(StripePaymentService.validateExpiry('12/2028'), isTrue);
      expect(StripePaymentService.validateExpiry('13/28'), isFalse);
      expect(StripePaymentService.validateExpiry('00/28'), isFalse);
      expect(StripePaymentService.validateExpiry('01/19'), isFalse); // past year
      expect(StripePaymentService.validateExpiry('invalid'), isFalse);
    });

    test('Validates CVC based on brand', () {
      expect(StripePaymentService.validateCvc('123', brand: 'VISA'), isTrue);
      expect(StripePaymentService.validateCvc('1234', brand: 'AMEX'), isTrue);
      expect(StripePaymentService.validateCvc('12', brand: 'VISA'), isFalse);
      expect(StripePaymentService.validateCvc('123', brand: 'AMEX'), isFalse);
    });

    test('Formats raw card numbers with 4-digit spacing', () {
      expect(
        StripePaymentService.formatCardNumber('4242424242424242'),
        '4242 4242 4242 4242',
      );
      expect(
        StripePaymentService.formatCardNumber('4242 4242 4242 4242'),
        '4242 4242 4242 4242',
      );
    });

    test('StripeCheckoutSessionResult and StripeSessionStatusResult model integrity', () {
      const sessionResult = StripeCheckoutSessionResult(
        isSuccess: true,
        sessionId: 'cs_test_123',
        url: 'https://checkout.stripe.com/pay/cs_test_123',
        amount: 2500.0,
        currency: 'AED',
      );
      expect(sessionResult.isSuccess, isTrue);
      expect(sessionResult.sessionId, 'cs_test_123');
      expect(sessionResult.url, contains('checkout.stripe.com'));
      expect(sessionResult.amount, 2500.0);
      expect(sessionResult.currency, 'AED');

      const statusResult = StripeSessionStatusResult(
        isPaid: true,
        paymentIntentId: 'pi_test_abc',
        status: 'complete',
        customerEmail: 'collector@dubai.ae',
      );
      expect(statusResult.isPaid, isTrue);
      expect(statusResult.paymentIntentId, 'pi_test_abc');
      expect(statusResult.customerEmail, 'collector@dubai.ae');
    });
  });
}
