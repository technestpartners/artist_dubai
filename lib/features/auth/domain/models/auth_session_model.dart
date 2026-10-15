import 'user_model.dart';

/// Domain representation of an authenticated user session.
class AuthSession {
  final UserModel user;
  final String token;
  final bool isAdmin;
  final bool hasArtistProfile;
  final String? artistProfileId;
  final String? artistProfileName;

  const AuthSession({
    required this.user,
    required this.token,
    required this.isAdmin,
    this.hasArtistProfile = false,
    this.artistProfileId,
    this.artistProfileName,
  });

  bool get isArtist => user.isArtist || hasArtistProfile;
}
