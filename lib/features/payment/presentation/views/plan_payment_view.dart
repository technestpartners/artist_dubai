import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/services/stripe_payment_service.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../admin/domain/models/payment_settings_model.dart';
import '../../../../core/utils/data_translator.dart';
import '../../../../core/utils/responsive_helper.dart';

/// Standalone Payment & Checkout Screen for Event and Gallery Publishing Plans.
/// Displays selected plan summary, Admin Payment QR code, Bank Transfer (IBAN)
/// details with 1-tap copy, transaction ID input, and receipt proof upload.
class PlanPaymentView extends StatefulWidget {
  final Map<String, dynamic> args;

  const PlanPaymentView({super.key, this.args = const {}});

  @override
  State<PlanPaymentView> createState() => _PlanPaymentViewState();
}

class _PlanPaymentViewState extends State<PlanPaymentView> {
  final TextEditingController _transactionIdController = TextEditingController();
  PaymentSettingsModel? _paymentSettings;
  StreamSubscription<PaymentSettingsModel>? _paymentSettingsSub;

  String? _receiptUrl;
  bool _isUploadingReceipt = false;
  bool _isSubmitting = false;

  int _selectedPaymentMethod = 0; // 0: Credit Card, 1: Bank Transfer & QR
  final _cardFormKey = GlobalKey<FormState>();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  bool _obscureCvv = true;
  bool _saveCard = true;

  late final String _itemType; // 'event' or 'gallery'
  late final String _title;
  late final String _subtitle;
  late final String _planId;
  late final String _planName;
  late final String _planAmount;
  late final Map<String, dynamic> _formData;

  @override
  void initState() {
    super.initState();
    _parseArgs();
    _loadPaymentSettings();
    _cardNumberController.addListener(() => setState(() {}));
    _cardHolderController.addListener(() => setState(() {}));
    _expiryController.addListener(() => setState(() {}));
    _cvvController.addListener(() => setState(() {}));
  }

  void _parseArgs() {
    _itemType = (widget.args['itemType'] ?? 'event').toString().toLowerCase();
    _title = widget.args['title']?.toString().trim().isNotEmpty == true
        ? widget.args['title'].toString().trim()
        : (_itemType == 'gallery' ? 'Art Gallery Registration' : 'Art Event Listing');
    _subtitle = widget.args['subtitle']?.toString().trim().isNotEmpty == true
        ? widget.args['subtitle'].toString().trim()
        : 'Dubai, UAE';
    _planId = (widget.args['planId'] ?? 'six_month').toString();
    _planName = widget.args['planName']?.toString().trim().isNotEmpty == true
        ? widget.args['planName'].toString().trim()
        : (_planId == 'yearly'
            ? 'Yearly Plan (365 Days)'
            : (_planId == 'monthly' ? 'Monthly Plan (30 Days)' : '6 Months Plan (180 Days)'));
    _planAmount = widget.args['planAmount']?.toString().trim().isNotEmpty == true
        ? widget.args['planAmount'].toString().trim()
        : (_itemType == 'gallery'
            ? (_planId == 'yearly' ? 'AED 6,500' : (_planId == 'monthly' ? 'AED 750' : 'AED 3,800'))
            : (_planId == 'yearly' ? 'AED 4,500' : (_planId == 'monthly' ? 'AED 500' : 'AED 2,500')));
    _formData = widget.args['formData'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(widget.args['formData'] as Map)
        : (widget.args['formData'] is Map
            ? Map<String, dynamic>.from(widget.args['formData'] as Map)
            : <String, dynamic>{});
  }

  Future<void> _loadPaymentSettings() async {
    try {
      final settings = await sl<ApiService>().getPaymentSettings();
      if (mounted) {
        setState(() => _paymentSettings = settings);
      }
    } catch (_) {}

    try {
      _paymentSettingsSub = sl<LiveSyncService>().paymentSettingsStream.listen((settings) {
        if (mounted) {
          setState(() => _paymentSettings = settings);
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _paymentSettingsSub?.cancel();
    _transactionIdController.dispose();
    _cardHolderController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _pickReceiptImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        if (!mounted) return;
        setState(() => _isUploadingReceipt = true);
        final bytes = await picked.readAsBytes();
        final nameParts = picked.name.split('.');
        final ext = nameParts.length > 1 ? nameParts.last : 'jpg';
        final url = await sl<ApiService>().uploadImageBytes(bytes, ext: ext);
        if (mounted) {
          setState(() {
            _receiptUrl = url;
            _isUploadingReceipt = false;
          });
          if (url != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment receipt attached successfully!'.trData(context)),
                backgroundColor: const Color(0xFF6A2777),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isUploadingReceipt = false);
    }
  }

  void _onConfirmPressed() {
    final txnRef = _transactionIdController.text.trim();
    final hasProof = (_receiptUrl != null && _receiptUrl!.isNotEmpty) || txnRef.isNotEmpty;

    if (!hasProof) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No Payment Proof Attached'.trData(context),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          content: Text(
            'You haven\'t attached a receipt screenshot or entered a transaction reference number.\n\nYou can attach your proof now for faster verification, or submit anyway as pending transfer.'.trData(context),
            style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _pickReceiptImage();
              },
              child: Text('Attach Receipt'.trData(context), style: const TextStyle(color: Color(0xFF6A2777), fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A2777),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _submitPaymentAndListing();
              },
              child: Text('Submit Anyway'.trData(context)),
            ),
          ],
        ),
      );
    } else {
      _submitPaymentAndListing();
    }
  }

  Future<void> _submitPaymentAndListing() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final txnRef = _transactionIdController.text.trim();
    final hasProof = (_receiptUrl != null && _receiptUrl!.isNotEmpty) || txnRef.isNotEmpty;
    final paymentStatus = hasProof ? 'submitted' : 'unpaid';

    bool success = false;

    try {
      if (_itemType == 'gallery') {
        final payload = {
          'name': _formData['name'] ?? _title,
          'category': _formData['category'] ?? 'Art Gallery',
          'type': _formData['type'] ?? '',
          'address': _formData['address'] ?? '',
          'location': _formData['location'] ?? _subtitle,
          'website': _formData['website'] ?? '',
          'contact_person': _formData['contact_person'] ?? '',
          'email': _formData['email'] ?? '',
          'phone': _formData['phone'] ?? '',
          'about': _formData['about'] ?? '',
          if (_formData['image_url'] != null && _formData['image_url'].toString().isNotEmpty)
            'image_url': _formData['image_url'],
          'status': 'pending',
          'is_public': 0,
          'is_approved': 0,
          'publishing_plan': _planId,
          'publishing_amount': _planAmount,
          'payment_status': paymentStatus,
          if (_receiptUrl != null && _receiptUrl!.isNotEmpty) 'payment_proof_url': _receiptUrl!,
          if (txnRef.isNotEmpty) 'payment_reference': txnRef,
        };

        success = await sl<ApiService>().registerGallery(payload);
        if (success) {
          try {
            sl<LiveSyncService>().notifyGalleriesChanged();
          } catch (_) {}
        }
      } else {
        // Event Listing Submission
        final title = (_formData['title'] ?? _title).toString();
        final description = (_formData['description'] ?? '').toString();
        final category = (_formData['category'] ?? 'Art Exhibition').toString();
        final eventDate = (_formData['event_date'] ?? DateTime.now().toIso8601String().substring(0, 10)).toString();
        final endDate = (_formData['end_date'] ?? '').toString();
        final location = (_formData['location'] ?? _subtitle).toString();
        final venue = (_formData['venue'] ?? '').toString();
        final isFree = _formData['is_free'] == true;
        final price = (_formData['price'] ?? 'Free Entry').toString();
        final maxAttendees = int.tryParse(_formData['max_attendees']?.toString() ?? '100') ?? 100;
        final organizerName = (_formData['organizer_name'] ?? '').toString();
        final contactEmail = (_formData['contact_email'] ?? '').toString();
        final contactPhone = (_formData['contact_phone'] ?? '').toString();
        final tags = (_formData['tags'] ?? '').toString();
        final imageUrl = _formData['image_url']?.toString();

        success = await sl<ApiService>().createEvent(
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
          paymentStatus: paymentStatus,
          paymentProofUrl: _receiptUrl,
          paymentReference: txnRef.isNotEmpty ? txnRef : null,
        );

        if (success) {
          try {
            sl<LiveSyncService>().notifyEventsChanged();
          } catch (_) {}
        }
      }
    } catch (_) {
      success = false;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      _showSuccessDialog(isCreditCard: false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit listing. Please verify your connection and try again.'.trData(context)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _detectCardBrand(String number) {
    final cleaned = number.replaceAll(' ', '');
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
    return 'CARD';
  }

  Future<void> _handleCreditCardPayment() async {
    if (!_cardFormKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    // Extract numeric price from planAmount (e.g., 'AED 2,500' -> 2500.0)
    final cleanedAmountStr = _planAmount.replaceAll(RegExp(r'[^0-9.]'), '');
    final amount = double.tryParse(cleanedAmountStr) ?? 2500.0;

    // Process payment securely via Stripe Gateway
    final stripeResult = await StripePaymentService().processCardPayment(
      cardNumber: _cardNumberController.text,
      expiryDate: _expiryController.text,
      cvc: _cvvController.text,
      cardHolderName: _cardHolderController.text,
      amount: amount,
      currency: 'AED',
      itemTitle: _title,
      metadata: {
        'itemType': _itemType,
        'planId': _planId,
        'planName': _planName,
      },
    );

    if (!stripeResult.isSuccess) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((stripeResult.errorMessage ?? 'Payment authorization failed.').trData(context)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final ccRef = stripeResult.transactionId ?? 'pi_${DateTime.now().millisecondsSinceEpoch}';

    bool success = false;

    try {
      if (_itemType == 'gallery') {
        final payload = {
          'name': _formData['name'] ?? _title,
          'category': _formData['category'] ?? 'Art Gallery',
          'type': _formData['type'] ?? '',
          'address': _formData['address'] ?? '',
          'location': _formData['location'] ?? _subtitle,
          'website': _formData['website'] ?? '',
          'contact_person': _formData['contact_person'] ?? '',
          'email': _formData['email'] ?? '',
          'phone': _formData['phone'] ?? '',
          'about': _formData['about'] ?? '',
          if (_formData['image_url'] != null && _formData['image_url'].toString().isNotEmpty)
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

        success = await sl<ApiService>().registerGallery(payload);
        if (success) {
          try {
            sl<LiveSyncService>().notifyGalleriesChanged();
          } catch (_) {}
        }
      } else {
        // Event Listing Submission
        final title = (_formData['title'] ?? _title).toString();
        final description = (_formData['description'] ?? '').toString();
        final category = (_formData['category'] ?? 'Art Exhibition').toString();
        final eventDate = (_formData['event_date'] ?? DateTime.now().toIso8601String().substring(0, 10)).toString();
        final endDate = (_formData['end_date'] ?? '').toString();
        final location = (_formData['location'] ?? _subtitle).toString();
        final venue = (_formData['venue'] ?? '').toString();
        final isFree = _formData['is_free'] == true;
        final price = (_formData['price'] ?? 'Free Entry').toString();
        final maxAttendees = int.tryParse(_formData['max_attendees']?.toString() ?? '100') ?? 100;
        final organizerName = (_formData['organizer_name'] ?? '').toString();
        final contactEmail = (_formData['contact_email'] ?? '').toString();
        final contactPhone = (_formData['contact_phone'] ?? '').toString();
        final tags = (_formData['tags'] ?? '').toString();
        final imageUrl = _formData['image_url']?.toString();

        success = await sl<ApiService>().createEvent(
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

        if (success) {
          try {
            sl<LiveSyncService>().notifyEventsChanged();
          } catch (_) {}
        }
      }
    } catch (_) {
      success = false;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      _showSuccessDialog(isCreditCard: true, ccRef: ccRef);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment processed, but submission encountered an issue. Please try again.'.trData(context)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessDialog({bool isCreditCard = false, String? ccRef}) {
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
                color: isCreditCard ? const Color(0xFFDCFCE7) : const Color(0xFFF3E8FF),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCreditCard ? const Color(0xFF86EFAC) : const Color(0xFFD8B4FE),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: isCreditCard ? const Color(0xFF16A34A) : const Color(0xFF6A2777),
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              (isCreditCard
                      ? (_itemType == 'gallery' ? 'Gallery Registered & Paid!' : 'Event Published & Paid!')
                      : (_itemType == 'gallery' ? 'Gallery Submitted for Review!' : 'Event Submitted for Review!'))
                  .trData(context),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            Text(
              (isCreditCard
                      ? (_itemType == 'gallery'
                          ? 'Your credit card payment of $_planAmount was successful! Your art gallery registration has been approved and registered.'
                          : 'Your credit card payment of $_planAmount was successful! Your event listing has been registered and is now published.')
                      : (_itemType == 'gallery'
                          ? 'Your gallery registration and payment proof have been submitted. Once verified by our administration team, your gallery will appear publicly.'
                          : 'Your event listing and payment proof have been submitted. Our team will verify your transfer and publish your event within 24 hours.'))
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
                  Row(
                    children: [
                      const Icon(Icons.verified_user_outlined, size: 18, color: Color(0xFF6A2777)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${'Plan'.trData(context)}: ${_planName.trData(context)} ($_planAmount)',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                        ),
                      ),
                    ],
                  ),
                  if (ccRef != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 18, color: Color(0xFF16A34A)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${'Transaction Ref'.trData(context)}: $ccRef',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF16A34A)),
                          ),
                        ),
                      ],
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
                  if (_itemType == 'gallery') {
                    context.go(RouteNames.galleries);
                  } else {
                    context.go(RouteNames.myEvents);
                  }
                },
                child: Text(
                  (_itemType == 'gallery' ? 'Back to Galleries' : 'View My Events').trData(context),
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
    final settings = _paymentSettings ?? PaymentSettingsModel.defaultSettings();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.5,
        title: Text(
          'Payment & Checkout'.trData(context),
          style: TextStyle(fontSize: rh.sp(17), fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(_itemType == 'gallery' ? RouteNames.galleryRegistration : RouteNames.createArtEvent);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: rh.horizontalPadding, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: rh.contentMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step Indicator Header
                  _buildStepHeader(),
                  const SizedBox(height: 16),

                  // Order & Plan Summary Card
                  _buildOrderSummaryCard(),
                  const SizedBox(height: 16),

                  // Payment Method Selector (Credit Card vs Bank Transfer & QR)
                  _buildPaymentMethodSelector(),
                  const SizedBox(height: 16),

                  if (_selectedPaymentMethod == 0) ...[
                    // Credit Card Form and Live Card Preview
                    _buildCreditCardSection(),
                  ] else ...[
                    // Admin Payment QR Code & Instructions
                    _buildQrCodeCard(settings),
                    const SizedBox(height: 16),

                    // Bank Transfer Information (IBAN Copy)
                    _buildBankDetailsCard(settings),
                    const SizedBox(height: 16),

                    // Verification Form (Txn ID & Receipt Upload)
                    _buildVerificationCard(),
                  ],
                  const SizedBox(height: 24),

                  // Submit and Cancel Action Buttons
                  _buildActionButtons(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Color(0xFF6A2777),
              shape: BoxShape.circle,
            ),
            child: const Text(
              '2',
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step 2 of 2: Payment & Verification'.trData(context),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6A2777)),
                ),
                Text(
                  'Pay securely with credit card or transfer via bank IBAN & QR code'.trData(context),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF7E22CE)),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF6A2777)),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  (_itemType == 'gallery' ? 'GALLERY REGISTRATION' : 'EVENT PUBLISHING').trData(context),
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF6A2777), letterSpacing: 0.5),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, size: 14, color: Color(0xFFD97706)),
                    const SizedBox(width: 4),
                    Text(
                      _planAmount,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _title.trData(context),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            _subtitle.trData(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Selected Plan Duration:'.trData(context),
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              Text(
                _planName.trData(context),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Payable:'.trData(context),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
              Text(
                _planAmount,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF6A2777)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQrCodeCard(PaymentSettingsModel settings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF6A2777), size: 22),
              const SizedBox(width: 10),
              Text(
                'Scan QR to Pay'.trData(context),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6A2777).withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: settings.qrCodeUrl.isNotEmpty
                ? AppCachedImage(
                    imageUrl: settings.qrCodeUrl,
                    width: 170,
                    height: 170,
                    fit: BoxFit.contain,
                    errorWidget: const Center(
                      child: Icon(Icons.qr_code_2_rounded, size: 70, color: Color(0xFF94A3B8)),
                    ),
                  )
                : const Center(
                    child: Icon(Icons.qr_code_2_rounded, size: 70, color: Color(0xFF94A3B8)),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            'Scan using your UAE Banking app, Apple Pay, Google Pay, or QR reader'.trData(context),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetailsCard(PaymentSettingsModel settings) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_rounded, color: Color(0xFF6A2777), size: 20),
              const SizedBox(width: 8),
              Text(
                'Direct Bank Transfer Details'.trData(context),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildInfoRow('Bank Name', settings.bankName, Icons.account_balance_rounded),
          const SizedBox(height: 8),
          _buildInfoRow('Account Title', settings.accountName, Icons.person_rounded),
          const SizedBox(height: 8),
          _buildInfoRow('IBAN / Account #', settings.accountNumber, Icons.tag_rounded, isCopyable: true),
          if (settings.instructions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      settings.instructions.trData(context),
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF92400E), height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {bool isCopyable = false}) {
    final trLabel = label.trData(context);
    final trValue = isCopyable ? value : value.trData(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Text(
            '$trLabel: ',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
          Expanded(
            child: Text(
              trValue,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textDirection: isCopyable ? TextDirection.ltr : null,
              textAlign: isCopyable ? TextAlign.start : null,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
          ),
          if (isCopyable && value.isNotEmpty)
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied $trLabel to clipboard!'.trData(context)),
                    backgroundColor: const Color(0xFF6A2777),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.copy_rounded, size: 13, color: Color(0xFF6A2777)),
                    const SizedBox(width: 4),
                    Text('Copy'.trData(context), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6A2777))),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_outlined, color: Color(0xFF6A2777), size: 20),
              const SizedBox(width: 8),
              Text(
                'Payment Verification & Proof'.trData(context),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Attach your transfer receipt screenshot and/or enter transaction ID for instant verification.'.trData(context),
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          // Transaction ID Field
          Text(
            'Transaction Reference / ID (Optional)'.trData(context),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _transactionIdController,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.black),
            cursorColor: const Color(0xFF6A2777),
            decoration: InputDecoration(
              hintText: 'e.g. TXN-98472918 or Bank Ref #'.trData(context),
              hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.receipt_long_rounded, size: 18, color: Color(0xFF64748B)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          ),
          const SizedBox(height: 14),

          // Receipt Upload Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _receiptUrl != null ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _receiptUrl != null ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (_receiptUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AppCachedImage(
                          imageUrl: _receiptUrl!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorWidget: const Icon(Icons.receipt_rounded, color: Color(0xFF16A34A)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Proof Attached'.trData(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                            ),
                            Text(
                              'Receipt screenshot ready for review'.trData(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF166534)),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.upload_file_rounded, color: Color(0xFF6A2777), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attach Transfer Receipt'.trData(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                            ),
                            Text(
                              'Upload screenshot (PNG, JPG up to 10MB)'.trData(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: TextButton.icon(
                    onPressed: _isUploadingReceipt ? null : _pickReceiptImage,
                    icon: _isUploadingReceipt
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6A2777)),
                          )
                        : Icon(
                            _receiptUrl != null ? Icons.refresh_rounded : Icons.add_photo_alternate_rounded,
                            size: 16,
                            color: const Color(0xFF6A2777),
                          ),
                    label: Text(
                      _isUploadingReceipt
                          ? 'Uploading...'.trData(context)
                          : (_receiptUrl != null
                              ? 'Change Receipt Screenshot'.trData(context)
                              : 'Upload Receipt Screenshot'.trData(context)),
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF6A2777)),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFF3E8FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isCreditCard = _selectedPaymentMethod == 0;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A2777),
              foregroundColor: Colors.white,
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _isSubmitting
                ? null
                : (isCreditCard ? _handleCreditCardPayment : _onConfirmPressed),
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
                        isCreditCard
                            ? 'Processing payment securely...'.trData(context)
                            : 'Submitting listing...'.trData(context),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isCreditCard ? Icons.lock_rounded : Icons.check_circle_outline_rounded,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCreditCard
                            ? '${'Pay'.trData(context)} $_planAmount ${'with Card'.trData(context)}'
                            : '${'Confirm & Submit Listing'.trData(context)} ($_planAmount)',
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 44,
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
                context.go(_itemType == 'gallery' ? RouteNames.galleryRegistration : RouteNames.createArtEvent);
              }
            },
            child: Text('Back to Edit Details'.trData(context), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.payment_rounded, size: 18, color: Color(0xFF6A2777)),
            const SizedBox(width: 8),
            Text(
              'Payment Method'.trData(context),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Option 1: Credit / Debit Card
            Expanded(
              child: _buildPaymentMethodTab(
                index: 0,
                title: 'Credit / Debit Card'.trData(context),
                subtitle: 'Visa, Mastercard, AMEX'.trData(context),
                icon: Icons.credit_card_rounded,
                isRecommended: true,
              ),
            ),
            const SizedBox(width: 10),
            // Option 2: Bank Transfer & QR
            Expanded(
              child: _buildPaymentMethodTab(
                index: 1,
                title: 'Bank & QR'.trData(context),
                subtitle: 'IBAN & Receipt Proof'.trData(context),
                icon: Icons.account_balance_rounded,
                isRecommended: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTab({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isRecommended,
  }) {
    final isSelected = _selectedPaymentMethod == index;

    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFBF7FD) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF6A2777) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF6A2777).withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFEDE9FE) : const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 18,
                    color: isSelected ? const Color(0xFF6A2777) : const Color(0xFF64748B),
                  ),
                ),
                if (isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE9FE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'INSTANT'.trData(context),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6A2777),
                      ),
                    ),
                  )
                else
                  Icon(
                    isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                    size: 18,
                    color: isSelected ? const Color(0xFF6A2777) : const Color(0xFFCBD5E1),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isSelected ? const Color(0xFF6A2777) : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCardSection() {
    final cardBrand = _detectCardBrand(_cardNumberController.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live Credit Card Visual Display
        _buildCreditCardPreview(cardBrand),
        const SizedBox(height: 14),

        // Accepted Brands & SSL bar
        _buildAcceptedBrandsBar(),
        const SizedBox(height: 14),

        // Card Details Form Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Form(
            key: _cardFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.credit_score_rounded, size: 18, color: Color(0xFF6A2777)),
                    const SizedBox(width: 8),
                    Text(
                      'Card Details'.trData(context),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Cardholder Name
                _buildFieldLabel('Cardholder Name'.trData(context)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _cardHolderController,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  cursorColor: const Color(0xFF6A2777),
                  decoration: _cardInputDecoration(
                    hint: 'Full name on card'.trData(context),
                    prefixIcon: Icons.person_outline_rounded,
                    hasValue: _cardHolderController.text.trim().isNotEmpty,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter the name on your card'.trData(context);
                    }
                    if (val.trim().length < 3) {
                      return 'Name is too short'.trData(context);
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Card Number
                _buildFieldLabel('Card Number'.trData(context)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _cardNumberController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: 1.5,
                  ),
                  cursorColor: const Color(0xFF6A2777),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                    _CardNumberInputFormatter(),
                  ],
                  decoration: _cardInputDecoration(
                    hint: '0000 0000 0000 0000',
                    prefixIcon: Icons.credit_card_rounded,
                    hasValue: _cardNumberController.text.trim().isNotEmpty,
                    suffix: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _buildBrandBadge(cardBrand),
                    ),
                  ),
                  validator: (val) {
                    final cleaned = (val ?? '').replaceAll(' ', '');
                    if (cleaned.isEmpty) {
                      return 'Please enter your card number'.trData(context);
                    }
                    if (cleaned.length < 15) {
                      return 'Please enter a valid 16-digit card number'.trData(context);
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Expiry and CVV Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Expiry Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Expiry Date'.trData(context)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _expiryController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              letterSpacing: 1.2,
                            ),
                            cursorColor: const Color(0xFF6A2777),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                              _CardExpiryInputFormatter(),
                            ],
                            decoration: _cardInputDecoration(
                              hint: 'MM/YY',
                              prefixIcon: Icons.calendar_today_rounded,
                              hasValue: _expiryController.text.trim().isNotEmpty,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Required'.trData(context);
                              }
                              final parts = val.split('/');
                              if (parts.length != 2) return 'MM/YY';
                              final month = int.tryParse(parts[0]);
                              if (month == null || month < 1 || month > 12) {
                                return 'Invalid Month'.trData(context);
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // CVV / CVC
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Security Code (CVV)'.trData(context)),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _cvvController,
                            keyboardType: TextInputType.number,
                            obscureText: _obscureCvv,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              letterSpacing: 2.0,
                            ),
                            cursorColor: const Color(0xFF6A2777),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            decoration: _cardInputDecoration(
                              hint: 'CVV',
                              prefixIcon: Icons.lock_outline_rounded,
                              hasValue: _cvvController.text.trim().isNotEmpty,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscureCvv ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 18,
                                  color: const Color(0xFF64748B),
                                ),
                                onPressed: () => setState(() => _obscureCvv = !_obscureCvv),
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Required'.trData(context);
                              }
                              if (val.trim().length < 3) {
                                return '3-4 digits'.trData(context);
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Save Card Checkbox
                InkWell(
                  onTap: () => setState(() => _saveCard = !_saveCard),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: Checkbox(
                            value: _saveCard,
                            activeColor: const Color(0xFF6A2777),
                            checkColor: Colors.white,
                            fillColor: WidgetStateProperty.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return const Color(0xFF6A2777);
                              }
                              return Colors.white;
                            }),
                            side: const BorderSide(
                              color: Color(0xFF6A2777),
                              width: 1.8,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            onChanged: (val) => setState(() => _saveCard = val ?? true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Save card securely for 1-click renewals & future listings'.trData(context),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Security Info Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF635BFF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'stripe',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Guaranteed safe & secure checkout powered by Stripe'.trData(context),
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                        ),
                      ),
                      const Icon(Icons.lock_rounded, size: 16, color: Color(0xFF16A34A)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreditCardPreview(String cardBrand) {
    final rawNumber = _cardNumberController.text.trim();
    final displayNum = rawNumber.isEmpty ? '•••• •••• •••• ••••' : rawNumber;
    final displayName = _cardHolderController.text.trim().isEmpty
        ? 'CARDHOLDER NAME'
        : _cardHolderController.text.trim().toUpperCase();
    final displayExp = _expiryController.text.trim().isEmpty ? 'MM/YY' : _expiryController.text.trim();

    return Container(
      width: double.infinity,
      height: 195,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2E1065),
            Color(0xFF6A2777),
            Color(0xFF4C1D95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A2777).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Chip + Contactless + Brand
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Gold Chip
                  Container(
                    width: 36,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCD34D),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFF59E0B), width: 1),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Row(
                            children: [
                              const Spacer(),
                              Container(width: 1, color: const Color(0xFFD97706)),
                              const Spacer(),
                              Container(width: 1, color: const Color(0xFFD97706)),
                              const Spacer(),
                            ],
                          ),
                        ),
                        Center(
                          child: Container(
                            width: 18,
                            height: 12,
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFD97706), width: 0.8),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Contactless Wave
                  Transform.rotate(
                    angle: 1.5708,
                    child: const Icon(Icons.wifi_rounded, color: Colors.white70, size: 20),
                  ),
                ],
              ),
              _buildCardBrandVisual(cardBrand),
            ],
          ),

          // Middle: Card Number
          Text(
            displayNum,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              letterSpacing: 2.2,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),

          // Bottom: Name + Expiry
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CARDHOLDER'.trData(context),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 9,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'EXPIRES'.trData(context),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 9,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayExp,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardBrandVisual(String brand) {
    String text = brand;
    Color textColor = const Color(0xFF6A2777);

    if (brand == 'VISA') {
      text = 'VISA';
      textColor = const Color(0xFF1A1F71);
    } else if (brand == 'MASTERCARD') {
      text = 'Mastercard';
      textColor = const Color(0xFFEB001B);
    } else if (brand == 'AMEX') {
      text = 'AMEX';
      textColor = const Color(0xFF006FCF);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          fontStyle: brand == 'VISA' ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }

  Widget _buildAcceptedBrandsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildMiniBrandBadge('VISA', const Color(0xFF1A1F71)),
              const SizedBox(width: 6),
              _buildMiniBrandBadge('Mastercard', const Color(0xFFEB001B)),
              const SizedBox(width: 6),
              _buildMiniBrandBadge('AMEX', const Color(0xFF006FCF)),
              const SizedBox(width: 6),
              _buildMiniBrandBadge('Apple Pay', const Color(0xFF0F172A)),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded, size: 13, color: Color(0xFF16A34A)),
              const SizedBox(width: 4),
              Text(
                '256-bit SSL'.trData(context),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBrandBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  Widget _buildBrandBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFD8B4FE)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6A2777),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
    );
  }

  InputDecoration _cardInputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffix,
    bool hasValue = false,
  }) {
    final bool filled = hasValue;
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
      prefixIcon: Icon(
        prefixIcon,
        size: 19,
        color: filled ? const Color(0xFF6A2777) : const Color(0xFF64748B),
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: filled ? const Color(0xFFFAF5FF) : const Color(0xFFF8FAFC),
      focusColor: const Color(0xFFFAF5FF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: filled ? const Color(0xFFD8B4FE) : const Color(0xFFE2E8F0),
          width: filled ? 1.2 : 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF6A2777), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }
}

/// Auto format card number as 0000 0000 0000 0000
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(' ', '');
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

/// Auto format expiry date as MM/YY
class _CardExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll('/', '');
    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex == 2 && nonZeroIndex != text.length) {
        buffer.write('/');
      }
    }
    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
