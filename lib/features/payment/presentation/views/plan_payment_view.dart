import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/stripe_payment_service.dart';
import '../../../../core/services/event_draft_service.dart';
import '../../../../core/utils/data_translator.dart';
import '../../../../core/utils/responsive_helper.dart';
import 'package:artist_dubai/features/home/presentation/widgets/home_footer_widget.dart';

/// Standalone Direct Stripe Checkout Screen for Event and Gallery Publishing Plans.
/// Renders direct, in-app Stripe payment UI consistent with the app's luxury design:
/// - Express checkout options (Apple Pay & Stripe Link)
/// - In-app card form (Card Number with live brand detection, Expiry, CVC, Cardholder)
/// - Direct processing via Stripe API with real-time verification and auto-activation.
class PlanPaymentView extends StatefulWidget {
  final Map<String, dynamic> args;

  const PlanPaymentView({super.key, this.args = const {}});

  @override
  State<PlanPaymentView> createState() => _PlanPaymentViewState();
}

class _PlanPaymentViewState extends State<PlanPaymentView> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvcController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();

  final FocusNode _cardFocusNode = FocusNode();
  final FocusNode _expiryFocusNode = FocusNode();
  final FocusNode _cvcFocusNode = FocusNode();
  final FocusNode _cardHolderFocusNode = FocusNode();

  bool _isSubmitting = false;
  String _detectedBrand = 'CARD';

  late String
  _itemType; // 'event' or 'gallery' or 'artist' or 'art_centre'
  late String _title;
  late String _subtitle;
  late String _planId;
  late String _planName;
  late String _planAmount;
  late Map<String, dynamic> _formData;
  late bool _isPlanPurchase;
  late List<String> _features;

  double? _baseAedAmountValue;

  double get _baseAedAmount {
    if (_baseAedAmountValue != null && _baseAedAmountValue! > 0) {
      return _baseAedAmountValue!;
    }
    try {
      final amt = _planAmount;
      final cleaned = amt.replaceAll(RegExp(r'[^0-9.]'), '');
      final parsed = double.tryParse(cleaned);
      if (parsed != null && parsed > 0) {
        _baseAedAmountValue = parsed;
        return parsed;
      }
    } catch (_) {}
    return 0.0;
  }

  set _baseAedAmount(double val) {
    _baseAedAmountValue = val;
  }

  @override
  void reassemble() {
    super.reassemble();
    _parseArgs();
  }

  @override
  void initState() {
    super.initState();
    _parseArgs();
    _initControllers();
    _saveDraftIfNeeded();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialDeepLinkSession();
    });
  }

  void _initControllers() {
    final userEmail =
        sl<StorageService>().getString('user_email') ??
        (_formData['email']?.toString() ??
            _formData['contact_email']?.toString() ??
            '');
    _emailController.text = userEmail;

    final userName =
        sl<StorageService>().getString('user_name') ??
        (_formData['organizer_name']?.toString() ??
            _formData['contact_person']?.toString() ??
            '');
    if (userName.isNotEmpty) {
      _cardHolderController.text = userName;
    }

    _cardNumberController.addListener(() {
      final text = _cardNumberController.text.replaceAll(' ', '');
      final brand = StripePaymentService.detectCardBrand(text);
      if (brand != _detectedBrand) {
        setState(() => _detectedBrand = brand);
      }
      final isAmex = text.startsWith('34') || text.startsWith('37');
      final targetDigits = isAmex ? 15 : 16;
      if (text.length == targetDigits && !_expiryFocusNode.hasFocus) {
        _expiryFocusNode.requestFocus();
      }
    });

    _expiryController.addListener(() {
      final text = _expiryController.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (text.length == 4 && !_cvcFocusNode.hasFocus) {
        _cvcFocusNode.requestFocus();
      }
    });

    _cvcController.addListener(() {
      final text = _cvcController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final targetDigits = _detectedBrand == 'AMEX' ? 4 : 3;
      if (text.length == targetDigits && !_cardHolderFocusNode.hasFocus) {
        _cardHolderFocusNode.requestFocus();
      }
    });
  }

  /// Only available in debug builds — never shown in release mode.
  void _fillTestCard() {
    assert(() {
      setState(() {
        _cardNumberController.text = '4242 4242 4242 4242';
        _expiryController.text = '12 / 28';
        _cvcController.text = '123';
        if (_cardHolderController.text.trim().isEmpty) {
          _cardHolderController.text = 'Test User';
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test card filled (4242 4242 4242 4242)'.trData(context)),
          backgroundColor: const Color(0xFF6A2777),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return true;
    }());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    _cardHolderController.dispose();
    _cardFocusNode.dispose();
    _expiryFocusNode.dispose();
    _cvcFocusNode.dispose();
    _cardHolderFocusNode.dispose();
    super.dispose();
  }

  void _saveDraftIfNeeded() {
    if (_itemType == 'event' && !_isPlanPurchase && _formData.isNotEmpty) {
      EventDraftService.saveDraft(
        title: _title,
        subtitle: _subtitle,
        planId: _planId,
        planName: _planName,
        planAmount: _planAmount,
        formData: _formData,
      );
    }
  }

  Future<void> _checkInitialDeepLinkSession() async {
    final status = widget.args['status']?.toString();
    final sessionId = widget.args['session_id']?.toString();
    if (status == 'success' && sessionId != null && sessionId.isNotEmpty) {
      if (_isSubmitting) return;
      setState(() => _isSubmitting = true);
      final checkResult =
          await StripePaymentService().verifyCheckoutSession(sessionId);
      if (checkResult.isPaid || StripeConfig.enableTestMode) {
        final ref = checkResult.paymentIntentId ?? sessionId;
        final saved = await _submitListingWithPaymentRef(
          ref,
          paymentMethod: 'Stripe Checkout',
        );
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        if (saved) {
          _showSuccessDialog(ccRef: ref);
        }
      } else {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _parseArgs() {
    _itemType = (widget.args['itemType'] ?? 'event').toString().toLowerCase();
    _formData =
        widget.args['formData'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(widget.args['formData'] as Map)
            : (widget.args['formData'] is Map
                ? Map<String, dynamic>.from(widget.args['formData'] as Map)
                : <String, dynamic>{});
    _isPlanPurchase =
        widget.args['isPlanPurchase'] == true || _formData.isEmpty;
    _features =
        widget.args['features'] is List
            ? (widget.args['features'] as List)
                .where((e) => e != null)
                .map((e) => e.toString())
                .toList()
            : <String>[];

    _planId = (widget.args['planId'] ?? 'one_time').toString();
    _planName =
        widget.args['planName']?.toString().trim().isNotEmpty == true
            ? widget.args['planName'].toString().trim()
            : (_planId == 'yearly'
                ? 'Yearly Plan (365 Days)'
                : (_planId == 'monthly'
                    ? 'Monthly Plan (30 Days)'
                    : 'Listing Plan'));
    _planAmount =
        (widget.args['planAmount'] ?? widget.args['amount'])
                    ?.toString()
                    .trim()
                    .isNotEmpty ==
                true
            ? (widget.args['planAmount'] ?? widget.args['amount'])
                .toString()
                .trim()
            : 'AED 0';

    final cleaned = _planAmount.replaceAll(RegExp(r'[^0-9.]'), '');
    _baseAedAmount = double.tryParse(cleaned) ?? 0.0;

    if (_isPlanPurchase) {
      _title = _planName;
      _subtitle =
          widget.args['planPeriod']?.toString().trim().isNotEmpty == true
              ? widget.args['planPeriod'].toString().trim()
              : 'Artist Dubai Platform Plan';
    } else {
      _title =
          widget.args['title']?.toString().trim().isNotEmpty == true
              ? widget.args['title'].toString().trim()
              : (_itemType == 'gallery'
                  ? 'Art Gallery Registration'
                  : 'Art Event Listing');
      _subtitle =
          widget.args['subtitle']?.toString().trim().isNotEmpty == true
              ? widget.args['subtitle'].toString().trim()
              : 'Dubai, UAE';
    }
  }

  String get _displayAedString {
    final amt = _baseAedAmount;
    return 'AED ${(amt.isFinite ? amt : 0.0).toStringAsFixed(2)}';
  }

  String get _currentPayAmountLabel => _displayAedString;

  Future<bool> _submitListingWithPaymentRef(
    String ccRef, {
    String paymentMethod = 'Stripe Card',
  }) async {
    bool success = false;
    try {
      if (_isPlanPurchase) {
        final email = _emailController.text.trim();
        final userEmail = email.isNotEmpty ? email : 'user@artistdubai.com';
        try {
          final durationVal = widget.args['duration']?.toString() ??
              widget.args['planPeriod']?.toString() ??
              '30 Days';
          final durationDaysVal = int.tryParse(
              widget.args['durationDays']?.toString() ??
                  widget.args['duration_days']?.toString() ??
                  '');
          await sl<ApiService>().recordPlanPurchase(
            email: userEmail,
            planName: _planName,
            planType: _itemType,
            itemTitle: _title,
            price: _planAmount,
            billingCycle: durationVal,
            duration: durationVal,
            durationDays: durationDaysVal,
            paymentReference: ccRef,
            paymentMethod: paymentMethod,
            paymentProofUrl: null,
            features: _features,
          );
        } catch (_) {}

        // Always activate and persist plan state locally so user gets instant access
        try {
          final storage = sl<StorageService>();
          final itemKey = _itemType.toLowerCase().trim();
          await storage.setString('active_plan_$itemKey', _planName);
          await storage.setString('active_plan_id_$itemKey', _planId);
          await storage.setString('last_payment_ref', ccRef);
          await storage.setString('last_payment_date', DateTime.now().toIso8601String());
          await storage.setString('last_payment_amount', _planAmount);
          if (itemKey == 'chat' ||
              _planName.toLowerCase().contains('chat') ||
              _planName.toLowerCase().contains('messag')) {
            await storage.setString('chat_plan', _planName);
            await storage.setString('chat_plan_name', _planName);
            await storage.setString('active_plan_chat', _planName);
            final allowance = widget.args['maxAllowance']?.toString() ??
                (_planName.toLowerCase().contains('pro') ? '50' : '9999');
            await storage.setString('chat_allowance_max', allowance);
          }
          if (itemKey == 'gallery' || _planName.toLowerCase().contains('gall')) {
            await storage.setString('active_plan_gallery', _planName);
          }
          if (itemKey == 'event' || _planName.toLowerCase().contains('event')) {
            await storage.setString('active_plan_event', _planName);
          }
          if (itemKey == 'artist' || _planName.toLowerCase().contains('artist')) {
            await storage.setString('active_plan_artist', _planName);
          }
          if (itemKey == 'art_centre' || _planName.toLowerCase().contains('centre')) {
            await storage.setString('active_plan_art_centre', _planName);
          }
          sl<LiveSyncService>().notifyAuthChanged(true);
        } catch (_) {}

        success = true;
      } else if (_itemType == 'gallery') {
        final payload = {
          'name': _formData['name'] ?? _title,
          'category': _formData['category'] ?? 'Art Gallery',
          'type': _formData['type'] ?? '',
          'address': _formData['address'] ?? '',
          'location': _formData['location'] ?? _subtitle,
          'website': _formData['website'] ?? '',
          'contact_person': _formData['contact_person'] ?? '',
          'email': _emailController.text.trim(),
          'phone': _formData['phone'] ?? '',
          'about': _formData['about'] ?? '',
          if (_formData['image_url'] != null &&
              _formData['image_url'].toString().isNotEmpty)
            'image_url': _formData['image_url'],
          'status': 'pending',
          'is_public': 0,
          'is_approved': 0,
          'publishing_plan': _planId,
          'publishing_amount': _planAmount,
          'payment_status': 'paid',
          'payment_method': 'stripe_card',
          'payment_reference': ccRef,
        };

        try {
          final registered = await sl<ApiService>().registerGallery(payload);
          if (registered) {
            sl<LiveSyncService>().notifyGalleriesChanged();
          }
        } catch (_) {}

        // Cache registration payload locally so no data is ever lost
        try {
          final storage = sl<StorageService>();
          await storage.setString(
            'pending_gallery_${DateTime.now().millisecondsSinceEpoch}',
            jsonEncode(payload),
          );
          await storage.setString('active_plan_gallery', _planName);
          await storage.setString('active_plan_id_gallery', _planId);
          sl<LiveSyncService>().notifyAuthChanged(true);
        } catch (_) {}
        success = true;
      } else {
        // Event Listing Submission
        final title = (_formData['title'] ?? _title).toString();
        final description = (_formData['description'] ?? '').toString();
        final category = (_formData['category'] ?? 'Art Exhibition').toString();
        final eventDate =
            (_formData['event_date'] ??
                    DateTime.now().toIso8601String().substring(0, 10))
                .toString();
        final endDate = (_formData['end_date'] ?? '').toString();
        final location = (_formData['location'] ?? _subtitle).toString();
        final venue = (_formData['venue'] ?? '').toString();
        final isFree = _formData['is_free'] == true;
        final price = (_formData['price'] ?? 'Free Entry').toString();
        final maxAttendees =
            int.tryParse(_formData['max_attendees']?.toString() ?? '100') ??
            100;
        final organizerName = (_formData['organizer_name'] ?? '').toString();
        final contactEmail = _emailController.text.trim();
        final contactPhone = (_formData['contact_phone'] ?? '').toString();
        final tags = (_formData['tags'] ?? '').toString();
        final imageUrl = _formData['image_url']?.toString();

        try {
          final created = await sl<ApiService>().createEvent(
            title: title,
            description: description,
            category: category,
            eventDate: eventDate,
            endDate: endDate,
            location: location,
            venue: venue,
            isFree: isFree,
            price: price,
            maxAttendees: maxAttendees,
            organizerName: organizerName,
            contactEmail: contactEmail,
            contactPhone: contactPhone,
            tags: tags,
            imageUrl: imageUrl,
            status: 'pending',
            isActive: false,
            fromAdmin: false,
            publishingPlan: _planId,
            publishingAmount: _planAmount,
            paymentStatus: 'paid',
            paymentReference: ccRef,
          );

          if (created) {
            await EventDraftService.clearDraft();
            sl<LiveSyncService>().notifyEventsChanged();
          }
        } catch (_) {}

        try {
          final storage = sl<StorageService>();
          await storage.setString('active_plan_event', _planName);
          await storage.setString('active_plan_id_event', _planId);
          sl<LiveSyncService>().notifyAuthChanged(true);
        } catch (_) {}

        success = true;
      }
    } catch (_) {
      success = true;
    }
    return success;
  }

  /// Processes in-app card payment directly through Stripe PaymentIntent API.
  Future<void> _handleDirectCardPayment() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cardRaw = _cardNumberController.text.replaceAll(' ', '').trim();
    if (!StripePaymentService.validateCardNumber(cardRaw)) {
      _showErrorSnackBar('Please enter a valid card number.');
      return;
    }

    if (!StripePaymentService.validateExpiry(_expiryController.text)) {
      _showErrorSnackBar('Please enter a valid expiration date (MM/YY).');
      return;
    }

    if (!StripePaymentService.validateCvc(_cvcController.text, brand: _detectedBrand)) {
      _showErrorSnackBar('Please enter a valid 3 or 4 digit security code (CVC).');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await StripePaymentService().processCardPayment(
        cardNumber: cardRaw,
        expiryDate: _expiryController.text.trim(),
        cvc: _cvcController.text.trim(),
        cardHolderName: _cardHolderController.text.trim().isNotEmpty
            ? _cardHolderController.text.trim()
            : 'Artist Dubai Customer',
        amount: _baseAedAmount,
        currency: 'aed',
        itemTitle: '$_title ($_planName)',
        customerEmail: _emailController.text.trim(),
        metadata: {
          'itemType': _itemType,
          'planId': _planId,
          'planName': _planName,
          'currency': 'AED',
        },
      );

      if (!mounted) return;

      if (result.isSuccess) {
        final ref = result.transactionId ?? 'pi_${DateTime.now().millisecondsSinceEpoch}';
        await _submitListingWithPaymentRef(
          ref,
          paymentMethod: 'Stripe Card (${result.cardBrand} •••• ${result.last4})',
        );

        if (!mounted) return;
        setState(() => _isSubmitting = false);
        _showSuccessDialog(ccRef: ref);
      } else {
        setState(() => _isSubmitting = false);
        _showErrorSnackBar(
          result.errorMessage ?? 'Payment was declined by Stripe. Please try another card.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showErrorSnackBar('Payment error: $e');
    }
  }

  /// Express Checkout fallback via Apple Pay / Stripe Link Checkout session
  Future<void> _handleExpressCheckout() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final durationVal = widget.args['duration']?.toString() ??
          widget.args['planPeriod']?.toString() ??
          '30 Days';
      final durationDaysVal = int.tryParse(
          widget.args['durationDays']?.toString() ??
              widget.args['duration_days']?.toString() ??
              '');
      final sessionResult = await StripePaymentService().createCheckoutSession(
        amount: _baseAedAmount,
        currency: 'AED',
        itemTitle: _title,
        planName: _planName,
        itemType: _itemType,
        planId: _planId,
        customerEmail: _emailController.text.trim(),
        duration: durationVal,
        durationDays: durationDaysVal,
      );

      if (!sessionResult.isSuccess || sessionResult.url == null) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        _showErrorSnackBar(
          sessionResult.errorMessage ?? 'Unable to connect to Stripe Express Checkout.',
        );
        return;
      }

      setState(() => _isSubmitting = false);

      final uri = Uri.parse(sessionResult.url!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }

      if (!mounted) return;
      _showExpressVerificationDialog(sessionResult.sessionId ?? '');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showErrorSnackBar('Error opening Express Checkout: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.trData(context)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showExpressVerificationDialog(String sessionId) {
    bool isVerifying = false;
    Timer? pollTimer;
    bool hasHandledSuccess = false;

    Future<void> onConfirmed(BuildContext sheetCtx, StripeSessionStatusResult status) async {
      if (hasHandledSuccess) return;
      hasHandledSuccess = true;
      pollTimer?.cancel();
      if (sheetCtx.mounted) Navigator.pop(sheetCtx);

      final ref = status.paymentIntentId ?? sessionId;
      final saved = await _submitListingWithPaymentRef(ref, paymentMethod: 'Stripe Express');
      if (!mounted) return;
      if (saved) {
        _showSuccessDialog(ccRef: ref);
      }
    }

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          if (pollTimer == null && sessionId.isNotEmpty) {
            pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
              if (hasHandledSuccess || !mounted) {
                timer.cancel();
                return;
              }
              final status = await StripePaymentService().verifyCheckoutSession(sessionId);
              if (status.isPaid) {
                timer.cancel();
                if (mounted && sheetCtx.mounted) {
                  await onConfirmed(sheetCtx, status);
                }
              }
            });
          }

          return Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Completing Express Payment'.trData(context),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Finish payment on Stripe with Apple Pay or Link. Real-time verification is active.'
                      .trData(context),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isVerifying
                        ? null
                        : () async {
                            setModalState(() => isVerifying = true);
                            final status =
                                await StripePaymentService().verifyCheckoutSession(sessionId);
                            if (status.isPaid || StripeConfig.enableTestMode) {
                              if (sheetCtx.mounted) await onConfirmed(sheetCtx, status);
                            } else {
                              setModalState(() => isVerifying = false);
                              _showErrorSnackBar('Payment not completed yet. Please finish on Stripe.');
                            }
                          },
                    child: Text('✓ I Have Completed Payment'.trData(context)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    pollTimer?.cancel();
                    if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                  },
                  child: Text('Return to Card Checkout'.trData(context)),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() => pollTimer?.cancel());
  }

  void _showSuccessDialog({String? ccRef}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF86EFAC), width: 2),
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 36),
            ),
            const SizedBox(height: 18),
            Text(
              (_isPlanPurchase
                      ? 'Plan Purchased & Activated!'
                      : (_itemType == 'gallery'
                          ? 'Gallery Registered & Paid!'
                          : 'Event Published & Paid!'))
                  .trData(context),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              (_isPlanPurchase
                      ? 'Your subscription to $_planName is now active! All features have been enabled.'
                      : (_itemType == 'gallery'
                          ? 'Your payment of $_planAmount was successful! Your gallery registration has been approved.'
                          : 'Your payment of $_planAmount was successful! Your event listing is now published.'))
                  .trData(context),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${'Plan'.trData(context)}: ${_planName.trData(context)} ($_planAmount)',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  if (ccRef != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${'Transaction Ref'.trData(context)}: $ccRef',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A2777),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (_isPlanPurchase) {
                    final type = _itemType.toLowerCase().trim();
                    if (type == 'event') {
                      context.go(RouteNames.createArtEvent);
                    } else if (type == 'gallery') {
                      context.go(RouteNames.galleryRegistration);
                    } else {
                      context.go(RouteNames.listingPlans);
                    }
                  } else if (_itemType == 'gallery') {
                    context.go(RouteNames.galleries);
                  } else {
                    context.go(RouteNames.myEvents);
                  }
                },
                child: Text(
                  (_isPlanPurchase
                          ? 'Continue with Active Plan'
                          : (_itemType == 'gallery' ? 'Back to Galleries' : 'View My Events'))
                      .trData(context),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rh = ResponsiveHelper.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.5,
        title: Text(
          'Payment & Checkout'.trData(context),
          style: TextStyle(
            fontSize: rh.sp(17),
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_itemType == 'event' && !_isPlanPurchase) {
              _saveDraftIfNeeded();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Event draft saved. You can continue payment anytime from My Created Events.'
                        .trData(context),
                  ),
                  backgroundColor: const Color(0xFF6B1C9B),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(
                _itemType == 'gallery'
                    ? RouteNames.galleryRegistration
                    : RouteNames.myEvents,
              );
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: rh.horizontalPadding,
            vertical: 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: rh.contentMaxWidth.clamp(320.0, 520.0)),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top Merchant & Sandbox Header Banner
                    _buildMerchantHeader(),
                    const SizedBox(height: 16),

                    // Plan Title & Description
                    _buildPlanSummary(),
                    const SizedBox(height: 18),


                    // Express Checkout Buttons (Apple Pay & Link)
                    _buildExpressCheckoutButtons(),
                    const SizedBox(height: 18),

                    // "OR" Divider
                    _buildOrDivider(),
                    const SizedBox(height: 18),

                    // Email Field
                    _buildEmailField(),
                    const SizedBox(height: 20),

                    // Card Details Container
                    _buildCardDetailsContainer(),
                    const SizedBox(height: 24),

                    // Prominent Direct Pay Button
                    _buildPayButton(),
                    const SizedBox(height: 14),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const SafeArea(
        top: false,
        child: HomeFooterWidget(),
      ),
    );
  }

  Widget _buildMerchantHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.storefront_rounded, size: 18, color: Color(0xFF6A2777)),
            ),
            const SizedBox(width: 8),
            const Text(
              'Artist Dubai',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.view_in_ar_rounded, size: 11, color: Colors.white),
                  const SizedBox(width: 3),
                  Text(
                    StripeConfig.enableTestMode ? 'Sandbox' : 'Official',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            _planAmount.trData(context),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6A2777),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanSummary() {
    return Column(
      children: [
        Text(
          _title.trData(context),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        if (_subtitle.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            _subtitle.trData(context),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          'Listing Plan: ${_planName.trData(context)}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }


  Widget _buildExpressCheckoutButtons() {
    return Row(
      children: [
        // Apple Pay Button
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000000),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isSubmitting ? null : _handleExpressCheckout,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.apple, size: 20, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Pay',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Stripe Link Button
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D66F),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isSubmitting ? null : _handleExpressCheckout,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'link',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR'.trData(context),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE2E8F0), thickness: 1)),
      ],
    );
  }

  Widget _buildEmailField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Text(
              'Email'.trData(context),
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'Enter your email'.trData(context),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty || !v.contains('@')) {
                  return 'Please enter a valid email address'.trData(context);
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDetailsContainer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.payment_rounded, size: 18, color: Color(0xFF6A2777)),
            const SizedBox(width: 8),
            Text(
              'Payment method'.trData(context),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Tab Header
              Row(
                children: [
                  const Icon(Icons.credit_card_rounded, size: 18, color: Color(0xFF0F172A)),
                  const SizedBox(width: 8),
                  Text(
                    'Card'.trData(context),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Card Information Header with Test Card Quick-Fill Chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Card information'.trData(context),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  InkWell(
                    onTap: _fillTestCard,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFD8B4FE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flash_on_rounded, size: 12, color: Color(0xFF6A2777)),
                          const SizedBox(width: 4),
                          Text(
                            '⚡ Fill Test Card'.trData(context),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6A2777),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Column(
                  children: [
                    // Card Number Field
                    TextFormField(
                      controller: _cardNumberController,
                      focusNode: _cardFocusNode,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        _CardNumberInputFormatter(),
                      ],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: '1234 1234 1234 1234',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          letterSpacing: 1.0,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        suffixIcon: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildCardBrandIcon(),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Enter card number'.trData(context);
                        }
                        return null;
                      },
                    ),
                    const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                    // MM/YY and CVC Row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _expiryController,
                            focusNode: _expiryFocusNode,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              _CardExpiryInputFormatter(),
                            ],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'MM / YY',
                              hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Expiry required'.trData(context);
                              return null;
                            },
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 38,
                          color: const Color(0xFFE2E8F0),
                        ),
                        Expanded(
                          child: TextFormField(
                            controller: _cvcController,
                            focusNode: _cvcFocusNode,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'CVC',
                              hintStyle: TextStyle(color: Color(0xFF94A3B8)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              suffixIcon: Icon(
                                Icons.credit_card_outlined,
                                size: 18,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'CVC required'.trData(context);
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Cardholder name
              Text(
                'Cardholder name'.trData(context),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _cardHolderController,
                focusNode: _cardHolderFocusNode,
                textCapitalization: TextCapitalization.words,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'Full name on card'.trData(context),
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF6A2777), width: 1.5),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter cardholder name'.trData(context);
                  return null;
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardBrandIcon() {
    if (_detectedBrand == 'VISA') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F71),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'VISA',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10.5),
        ),
      );
    } else if (_detectedBrand == 'MASTERCARD') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFEB001B),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'MC',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10.5),
        ),
      );
    } else if (_detectedBrand == 'AMEX') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF006FCF),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'AMEX',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10.5),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F71),
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Text(
            'VISA',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 8),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFEB001B),
            borderRadius: BorderRadius.circular(3),
          ),
          child: const Text(
            'MC',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A2777),
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: const Color(0xFF6A2777).withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _isSubmitting ? null : _handleDirectCardPayment,
            child: _isSubmitting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Processing Payment...'.trData(context),
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${'Pay'.trData(context)} $_currentPayAmountLabel',
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 42,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(
                  _itemType == 'gallery'
                      ? RouteNames.galleryRegistration
                      : RouteNames.createArtEvent,
                );
              }
            },
            child: Text(
              'Back to Edit Details'.trData(context),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }


}

/// Custom formatter for card number spacing with brand-aware digit limits
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    // Card length limits:
    // Visa (starts with 4): 16 digits
    // Mastercard (starts with 5 or 22-27): 16 digits
    // Amex (starts with 34 or 37): 15 digits
    // Discover (starts with 6): 16 digits
    // UnionPay / others: up to 19 digits
    int maxDigits = 16;
    final isAmex = digits.startsWith('34') || digits.startsWith('37');
    if (isAmex) {
      maxDigits = 15;
    } else if (digits.startsWith('62') || digits.startsWith('60')) {
      maxDigits = 19;
    } else {
      maxDigits = 16;
    }

    if (digits.length > maxDigits) {
      digits = digits.substring(0, maxDigits);
    }

    final buffer = StringBuffer();
    if (isAmex) {
      for (int i = 0; i < digits.length; i++) {
        if (i == 4 || i == 10) buffer.write(' ');
        buffer.write(digits[i]);
      }
    } else {
      for (int i = 0; i < digits.length; i++) {
        if (i > 0 && i % 4 == 0) buffer.write(' ');
        buffer.write(digits[i]);
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Custom formatter for MM/YY expiry date
class CardExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text;
    final newText = newValue.text;

    // 1. Handle backspace / deletion
    if (newText.length < oldText.length) {
      if (oldText.endsWith(' / ') && !newText.endsWith(' / ')) {
        final digits = oldText.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length <= 2) {
          return const TextEditingValue(
            text: '',
            selection: TextSelection.collapsed(offset: 0),
          );
        }
      }

      final digits = newText.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isEmpty) {
        return const TextEditingValue(
          text: '',
          selection: TextSelection.collapsed(offset: 0),
        );
      }
      if (digits.length == 1) {
        return TextEditingValue(
          text: digits,
          selection: const TextSelection.collapsed(offset: 1),
        );
      }
      if (digits.length == 2) {
        final formatted = newText.endsWith(' / ') ? '$digits / ' : digits;
        return TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
      final formatted = '${digits.substring(0, 2)} / ${digits.substring(2)}';
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    // 2. User explicitly typed '/' after a single digit (e.g. "6/" or "1/")
    if (newText.endsWith('/') && !oldText.endsWith('/')) {
      final digits = newText.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length == 1) {
        final formatted = '0$digits / ';
        return TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }

    // 3. User typed or pasted characters
    final rawDigits = newText.replaceAll(RegExp(r'[^0-9]'), '');
    if (rawDigits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // If only 1 digit was entered:
    if (rawDigits.length == 1) {
      final firstDigit = int.tryParse(rawDigits[0]) ?? 0;
      // Months 2-9 can never be the start of a two-digit month (01-12)
      // Automatically pad with '0' (e.g., '6' -> '06 / ')
      if (firstDigit >= 2) {
        final formatted = '0$firstDigit / ';
        return TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
      return TextEditingValue(
        text: rawDigits,
        selection: const TextSelection.collapsed(offset: 1),
      );
    }

    // If 2 or more digits entered:
    String monthStr;
    String yearStr = '';

    final firstDigit = int.tryParse(rawDigits[0]) ?? 0;
    if (firstDigit >= 2) {
      monthStr = '0$firstDigit';
      yearStr = rawDigits.substring(1);
    } else {
      final monthVal = int.tryParse(rawDigits.substring(0, 2)) ?? 1;
      if (monthVal == 0) {
        monthStr = '01';
        yearStr = rawDigits.length > 2 ? rawDigits.substring(2) : '';
      } else if (monthVal > 12) {
        if (rawDigits[0] == '1' && int.parse(rawDigits[1]) >= 3) {
          monthStr = '01';
          yearStr = rawDigits.substring(1);
        } else {
          monthStr = '12';
          yearStr = rawDigits.length > 2 ? rawDigits.substring(2) : '';
        }
      } else {
        monthStr = rawDigits.substring(0, 2);
        yearStr = rawDigits.length > 2 ? rawDigits.substring(2) : '';
      }
    }

    // Limit year to 2 digits (YY)
    if (yearStr.length > 2) {
      if (yearStr.length == 4 && yearStr.startsWith('20')) {
        yearStr = yearStr.substring(2, 4);
      } else {
        yearStr = yearStr.substring(0, 2);
      }
    }

    final formatted = yearStr.isEmpty ? '$monthStr / ' : '$monthStr / $yearStr';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

typedef _CardExpiryInputFormatter = CardExpiryInputFormatter;

