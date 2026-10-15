import '../models/auth_session_model.dart';

/// Contract defining authentication operations.
abstract class AuthRepository {
  /// Authenticates the user with email and password, persisting session credentials.
  Future<AuthSession> login({required String email, required String password});

  /// Registers a new user or artist and establishes an authenticated session.
  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
  });

  /// Logs out the user and clears all cached auth tokens and user records.
  Future<void> logout();

  /// Retrieves the active authenticated session from local cache, if present.
  Future<AuthSession?> getCachedSession();

  /// Checks whether a valid session is currently stored.
  Future<bool> isLoggedIn();
}
