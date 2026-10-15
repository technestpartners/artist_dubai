import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/models/auth_session_model.dart';
import '../../domain/repositories/auth_repository.dart';

enum LoginStatus { initial, loading, success, failure }

class LoginState {
  final LoginStatus status;
  final String email;
  final String password;
  final bool obscurePassword;
  final String? emailError;
  final String? passwordError;
  final String? generalError;
  final AuthSession? session;

  const LoginState({
    this.status = LoginStatus.initial,
    this.email = '',
    this.password = '',
    this.obscurePassword = true,
    this.emailError,
    this.passwordError,
    this.generalError,
    this.session,
  });

  bool get isLoading => status == LoginStatus.loading;
  bool get isSuccess => status == LoginStatus.success;

  bool get isFormValid {
    final trimmedEmail = email.trim();
    final trimmedPassword = password.trim();
    return trimmedEmail.isNotEmpty &&
        trimmedEmail.contains('@') &&
        trimmedPassword.isNotEmpty;
  }

  LoginState copyWith({
    LoginStatus? status,
    String? email,
    String? password,
    bool? obscurePassword,
    String? emailError,
    String? passwordError,
    String? generalError,
    AuthSession? session,
    bool clearEmailError = false,
    bool clearPasswordError = false,
    bool clearGeneralError = false,
  }) {
    return LoginState(
      status: status ?? this.status,
      email: email ?? this.email,
      password: password ?? this.password,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
      passwordError:
          clearPasswordError ? null : (passwordError ?? this.passwordError),
      generalError:
          clearGeneralError ? null : (generalError ?? this.generalError),
      session: session ?? this.session,
    );
  }
}

class LoginController extends ChangeNotifier {
  final AuthRepository _authRepository;

  LoginState _state = const LoginState();
  LoginState get state => _state;

  LoginController({required AuthRepository authRepository})
    : _authRepository = authRepository;

  void setEmail(String value) {
    _state = _state.copyWith(
      email: value,
      clearEmailError: true,
      clearGeneralError: true,
    );
    notifyListeners();
  }

  void setPassword(String value) {
    _state = _state.copyWith(
      password: value,
      clearPasswordError: true,
      clearGeneralError: true,
    );
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _state = _state.copyWith(obscurePassword: !_state.obscurePassword);
    notifyListeners();
  }

  void clearErrors() {
    _state = _state.copyWith(
      clearEmailError: true,
      clearPasswordError: true,
      clearGeneralError: true,
    );
    notifyListeners();
  }

  bool validateInputs({
    required String enterEmailMsg,
    required String enterValidEmailMsg,
    required String enterPasswordMsg,
  }) {
    final email = _state.email.trim();
    final password = _state.password.trim();

    String? emailErr;
    String? passErr;
    bool hasErr = false;

    if (email.isEmpty) {
      emailErr = enterEmailMsg;
      hasErr = true;
    } else if (!email.contains('@') || !email.contains('.')) {
      emailErr = enterValidEmailMsg;
      hasErr = true;
    }

    if (password.isEmpty) {
      passErr = enterPasswordMsg;
      hasErr = true;
    }

    _state = _state.copyWith(
      emailError: emailErr,
      passwordError: passErr,
      clearEmailError: emailErr == null,
      clearPasswordError: passErr == null,
    );
    notifyListeners();

    return !hasErr;
  }

  Future<AuthSession?> submitLogin({
    required String enterEmailMsg,
    required String enterValidEmailMsg,
    required String enterPasswordMsg,
    required String userNotFoundMsg,
  }) async {
    final isValid = validateInputs(
      enterEmailMsg: enterEmailMsg,
      enterValidEmailMsg: enterValidEmailMsg,
      enterPasswordMsg: enterPasswordMsg,
    );

    if (!isValid) return null;

    _state = _state.copyWith(
      status: LoginStatus.loading,
      clearGeneralError: true,
    );
    notifyListeners();

    try {
      final session = await _authRepository.login(
        email: _state.email.trim(),
        password: _state.password.trim(),
      );

      _state = _state.copyWith(status: LoginStatus.success, session: session);
      notifyListeners();
      return session;
    } on ServerException catch (e) {
      _handleAuthError(e.message, fallbackUserNotFound: userNotFoundMsg);
      return null;
    } on UnauthorizedException catch (e) {
      _handleAuthError(e.message, fallbackUserNotFound: userNotFoundMsg);
      return null;
    } on NetworkException catch (e) {
      _state = _state.copyWith(
        status: LoginStatus.failure,
        generalError: e.message,
      );
      notifyListeners();
      return null;
    } catch (_) {
      _state = _state.copyWith(
        status: LoginStatus.failure,
        emailError: userNotFoundMsg,
      );
      notifyListeners();
      return null;
    }
  }

  void _handleAuthError(
    String message, {
    required String fallbackUserNotFound,
  }) {
    final lower = message.toLowerCase();
    if (lower.contains('password')) {
      _state = _state.copyWith(
        status: LoginStatus.failure,
        passwordError: message,
      );
    } else if (lower.contains('user') ||
        lower.contains('account') ||
        lower.contains('email') ||
        lower.contains('available')) {
      _state = _state.copyWith(
        status: LoginStatus.failure,
        emailError: message,
      );
    } else {
      _state = _state.copyWith(
        status: LoginStatus.failure,
        generalError: message,
      );
    }
    notifyListeners();
  }
}
