import 'package:flutter/widgets.dart';
import '../../../../core/utils/data_translator.dart';
import '../../../artists/domain/models/artist_model.dart';

/// Professional Domain Model for User and Profile
class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final bool isAdmin;
  final String? createdAt;
  final String? token;
  final ArtistModel? artistProfile;
  final String chatPlan;
  final int chatMaxAllowance;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.role = 'user',
    this.isAdmin = false,
    this.createdAt,
    this.token,
    this.artistProfile,
    this.chatPlan = 'Basic (Free)',
    this.chatMaxAllowance = 10,
  });

  String localizedName([BuildContext? context]) => fullName.trData(context);
  String localizedRole([BuildContext? context]) => role.trData(context);

  bool get isArtist => role.toLowerCase() == 'artist' || artistProfile != null;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final roleVal = json['role']?.toString().toLowerCase() ?? 'user';
    final isAdminVal = json['is_admin'] == true ||
        roleVal == 'admin' ||
        roleVal == 'superadmin' ||
        (json['email'] != null && json['email'].toString().toLowerCase().startsWith('admin@'));

    ArtistModel? parsedArtist;
    if (json['artist_profile'] is Map<String, dynamic>) {
      parsedArtist = ArtistModel.fromJson(json['artist_profile'] as Map<String, dynamic>);
    }

    return UserModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      fullName: json['full_name']?.toString() ?? json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: roleVal,
      isAdmin: isAdminVal,
      createdAt: json['created_at']?.toString(),
      token: json['token']?.toString(),
      artistProfile: parsedArtist,
      chatPlan: json['chat_plan']?.toString() ?? 'Basic (Free)',
      chatMaxAllowance: int.tryParse(json['chat_max_allowance']?.toString() ?? '10') ?? 10,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'email': email,
    'role': role,
    'is_admin': isAdmin,
    if (createdAt != null) 'created_at': createdAt,
    if (token != null) 'token': token,
    if (artistProfile != null) 'artist_profile': artistProfile!.toJson(),
    'chat_plan': chatPlan,
    'chat_max_allowance': chatMaxAllowance,
  };

  UserModel copyWith({
    int? id,
    String? fullName,
    String? email,
    String? role,
    bool? isAdmin,
    String? createdAt,
    String? token,
    ArtistModel? artistProfile,
    String? chatPlan,
    int? chatMaxAllowance,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt ?? this.createdAt,
      token: token ?? this.token,
      artistProfile: artistProfile ?? this.artistProfile,
      chatPlan: chatPlan ?? this.chatPlan,
      chatMaxAllowance: chatMaxAllowance ?? this.chatMaxAllowance,
    );
  }
}
