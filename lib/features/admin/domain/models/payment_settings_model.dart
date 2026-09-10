class PaymentSettingsModel {
  final int id;
  final String qrCodeUrl;
  final String accountName;
  final String accountNumber;
  final String bankName;
  final String instructions;
  final bool isActive;
  final String? updatedAt;

  const PaymentSettingsModel({
    required this.id,
    required this.qrCodeUrl,
    required this.accountName,
    required this.accountNumber,
    required this.bankName,
    required this.instructions,
    this.isActive = true,
    this.updatedAt,
  });

  factory PaymentSettingsModel.fromJson(Map<String, dynamic> json) {
    return PaymentSettingsModel(
      id: int.tryParse(json['id']?.toString() ?? '1') ?? 1,
      qrCodeUrl: (json['qr_code_url'] ?? json['qr_code'] ?? '').toString().trim(),
      accountName: (json['account_name'] ?? 'Artist Dubai Cultural Services LLC').toString().trim(),
      accountNumber: (json['account_number'] ?? json['iban'] ?? 'AE28 0330 0000 0001 2345 678').toString().trim(),
      bankName: (json['bank_name'] ?? 'Emirates NBD, Dubai').toString().trim(),
      instructions: (json['instructions'] ??
          'Please scan the QR code with your banking app or transfer via IBAN. Once completed, enter the transaction reference and upload your receipt screenshot.')
          .toString().trim(),
      isActive: json['is_active'] == null ||
          json['is_active'] == 1 ||
          json['is_active'] == '1' ||
          json['is_active'] == true,
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'qr_code_url': qrCodeUrl,
    'account_name': accountName,
    'account_number': accountNumber,
    'bank_name': bankName,
    'instructions': instructions,
    'is_active': isActive ? 1 : 0,
    if (updatedAt != null) 'updated_at': updatedAt,
  };

  PaymentSettingsModel copyWith({
    int? id,
    String? qrCodeUrl,
    String? accountName,
    String? accountNumber,
    String? bankName,
    String? instructions,
    bool? isActive,
    String? updatedAt,
  }) {
    return PaymentSettingsModel(
      id: id ?? this.id,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      accountName: accountName ?? this.accountName,
      accountNumber: accountNumber ?? this.accountNumber,
      bankName: bankName ?? this.bankName,
      instructions: instructions ?? this.instructions,
      isActive: isActive ?? this.isActive,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static PaymentSettingsModel defaultSettings() {
    return const PaymentSettingsModel(
      id: 1,
      qrCodeUrl: 'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=iban%3AAE280330000000012345678%26name%3DArtistDubai',
      accountName: 'Artist Dubai Cultural Services LLC',
      accountNumber: 'AE28 0330 0000 0001 2345 678',
      bankName: 'Emirates NBD, Dubai',
      instructions: 'Please scan the QR code with your mobile banking or payment app, or transfer directly via IBAN. Once paid, enter your transaction reference number and upload the receipt screenshot.',
      isActive: true,
    );
  }
}
