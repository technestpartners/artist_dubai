import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/live_sync_service.dart';
import '../../../../core/widgets/app_cached_image.dart';
import '../../../admin/domain/models/payment_settings_model.dart';

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
  }

  void _parseArgs() {
    _itemType = (widget.args['itemType'] ?? 'event').toString().toLowerCase();
    _title = widget.args['title']?.toString().trim().isNotEmpty == true
        ? widget.args['title'].toString().trim()
        : (_itemType == 'gallery' ? 'Art Gallery Registration' : 'Art Event Listing');
    _subtitle = widget.args['subtitle']?.toString().trim().isNotEmpty == true
        ? widget.args['subtitle'].toString().trim()
        : 'Dubai, UAE';
    _planId = (widget.args['planId'] ?? 'monthly').toString();
    _planName = widget.args['planName']?.toString().trim().isNotEmpty == true
        ? widget.args['planName'].toString().trim()
        : (_planId == 'weekly'
            ? 'Weekly Plan (7 Days)'
            : (_planId == 'yearly' ? 'Yearly Plan (365 Days)' : 'Monthly Plan (30 Days)'));
    _planAmount = widget.args['planAmount']?.toString().trim().isNotEmpty == true
        ? widget.args['planAmount'].toString().trim()
        : (_itemType == 'gallery'
            ? (_planId == 'monthly' ? 'AED 750' : (_planId == 'yearly' ? 'AED 6,500' : 'AED 200'))
            : (_planId == 'monthly' ? 'AED 500' : (_planId == 'yearly' ? 'AED 4,500' : 'AED 150')));
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
              const SnackBar(
                content: Text('Payment receipt attached successfully!'),
                backgroundColor: Color(0xFF6A2777),
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
            children: const [
              Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'No Payment Proof Attached',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          content: const Text(
            'You haven\'t attached a receipt screenshot or entered a transaction reference number.\n\nYou can attach your proof now for faster verification, or submit anyway as pending transfer.',
            style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF475569)),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _pickReceiptImage();
              },
              child: const Text('Attach Receipt', style: TextStyle(color: Color(0xFF6A2777), fontWeight: FontWeight.bold)),
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
              child: const Text('Submit Anyway'),
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
      _showSuccessDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to submit listing. Please verify your connection and try again.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccessDialog() {
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
                color: const Color(0xFFF3E8FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD8B4FE), width: 2),
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF6A2777), size: 36),
            ),
            const SizedBox(height: 18),
            Text(
              _itemType == 'gallery' ? 'Gallery Submitted for Review!' : 'Event Submitted for Review!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),
            Text(
              _itemType == 'gallery'
                  ? 'Your gallery registration and payment proof have been submitted. Once verified by our administration team, your gallery will appear publicly.'
                  : 'Your event listing and payment proof have been submitted. Our team will verify your transfer and publish your event within 24 hours.',
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
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, size: 18, color: Color(0xFF6A2777)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Plan: $_planName ($_planAmount)',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                    ),
                  ),
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
                  _itemType == 'gallery' ? 'Back to Galleries' : 'View My Events',
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
    final settings = _paymentSettings ?? PaymentSettingsModel.defaultSettings();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.5,
        title: const Text(
          'Payment & Checkout',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step Indicator Header
                  _buildStepHeader(),
                  const SizedBox(height: 16),

                  // Order & Plan Summary Card
                  _buildOrderSummaryCard(),
                  const SizedBox(height: 16),

                  // Admin Payment QR Code & Instructions
                  _buildQrCodeCard(settings),
                  const SizedBox(height: 16),

                  // Bank Transfer Information (IBAN Copy)
                  _buildBankDetailsCard(settings),
                  const SizedBox(height: 16),

                  // Verification Form (Txn ID & Receipt Upload)
                  _buildVerificationCard(),
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
              children: const [
                Text(
                  'Step 2 of 2: Payment & Verification',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF6A2777)),
                ),
                Text(
                  'Scan the QR code or transfer via IBAN, then attach your receipt',
                  style: TextStyle(fontSize: 11, color: Color(0xFF7E22CE)),
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
                  _itemType == 'gallery' ? 'GALLERY REGISTRATION' : 'EVENT PUBLISHING',
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
            _title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            _subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Selected Plan Duration:',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              Text(
                _planName,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Payable:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
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
            children: const [
              Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF6A2777), size: 22),
              SizedBox(width: 10),
              Text(
                'Scan QR to Pay',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
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
          const Text(
            'Scan using your UAE Banking app, Apple Pay, Google Pay, or QR reader',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.3),
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
            children: const [
              Icon(Icons.account_balance_rounded, color: Color(0xFF6A2777), size: 20),
              SizedBox(width: 8),
              Text(
                'Direct Bank Transfer Details',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
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
                      settings.instructions,
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
            '$label: ',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            ),
          ),
          if (isCopyable && value.isNotEmpty)
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied $label to clipboard!'),
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
                  children: const [
                    Icon(Icons.copy_rounded, size: 13, color: Color(0xFF6A2777)),
                    SizedBox(width: 4),
                    Text('Copy', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6A2777))),
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
            children: const [
              Icon(Icons.verified_outlined, color: Color(0xFF6A2777), size: 20),
              SizedBox(width: 8),
              Text(
                'Payment Verification & Proof',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Attach your transfer receipt screenshot and/or enter transaction ID for instant verification.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),

          // Transaction ID Field
          const Text(
            'Transaction Reference / ID (Optional)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _transactionIdController,
            decoration: InputDecoration(
              hintText: 'e.g. TXN-98472918 or Bank Ref #',
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Proof Attached',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                            ),
                            Text(
                              'Receipt screenshot ready for review',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: Color(0xFF166534)),
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attach Transfer Receipt',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
                            ),
                            Text(
                              'Upload screenshot (PNG, JPG up to 10MB)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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
                          ? 'Uploading...'
                          : (_receiptUrl != null ? 'Change Receipt Screenshot' : 'Upload Receipt Screenshot'),
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
            onPressed: _isSubmitting ? null : _onConfirmPressed,
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Confirm & Submit Listing ($_planAmount)',
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
            child: const Text('Back to Edit Details', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
