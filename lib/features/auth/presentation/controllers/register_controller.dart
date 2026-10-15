import 'package:flutter/foundation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/models/auth_session_model.dart';
import '../../domain/repositories/auth_repository.dart';

enum RegisterStatus { initial, loading, success, failure }

class RegisterState {
  final RegisterStatus status;
  final String fullName;
  final String email;
  final String password;
  final String confirmPassword;
  final String selectedRole;
  final bool acceptTerms;
  final bool obscurePassword;
  final String? fullNameError;
  final String? emailError;
  final String? passwordError;
  final String? confirmPasswordError;
  final String? termsError;
  final String? generalError;
  final AuthSession? session;

  const RegisterState({
    this.status = RegisterStatus.initial,
    this.fullName = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.selectedRole = 'user',
    this.acceptTerms = false,
    this.obscurePassword = true,
    this.fullNameError,
    this.emailError,
    this.passwordError,
    this.confirmPasswordError,
    this.termsError,
    this.generalError,
    this.session,
  });

  bool get isLoading => status == RegisterStatus.loading;
  bool get isSuccess => status == RegisterStatus.success;

  bool get isFormValid {
    final name = fullName.trim();
    final em = email.trim();
    final pass = password.trim();
    final confPass = confirmPassword.trim();

    return name.isNotEmpty &&
        em.isNotEmpty &&
        em.contains('@') &&
        em.contains('.') &&
        pass.length >= 6 &&
        confPass.isNotEmpty &&
        pass == confPass &&
        acceptTerms;
  }

  RegisterState copyWith({
    RegisterStatus? status,
    String? fullName,
    String? email,
    String? password,
    String? confirmPassword,
    String? selectedRole,
    bool? acceptTerms,
    bool? obscurePassword,
    String? fullNameError,
    String? emailError,
    String? passwordError,
    String? confirmPasswordError,
    String? termsError,
    String? generalError,
    AuthSession? session,
    bool clearFullNameError = false,
    bool clearEmailError = false,
    bool clearPasswordError = false,
    bool clearConfirmPasswordError = false,
    bool clearTermsError = false,
    bool clearGeneralError = false,
  }) {
    return RegisterState(
      status: status ?? this.status,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      selectedRole: selectedRole ?? this.selectedRole,
      acceptTerms: acceptTerms ?? this.acceptTerms,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      fullNameError:
          clearFullNameError ? null : (fullNameError ?? this.fullNameError),
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
      passwordError:
          clearPasswordError ? null : (passwordError ?? this.passwordError),
      confirmPasswordError:
          clearConfirmPasswordError
              ? null
              : (confirmPasswordError ?? this.confirmPasswordError),
      termsError: clearTermsError ? null : (termsError ?? this.termsError),
      generalError:
          clearGeneralError ? null : (generalError ?? this.generalError),
      session: session ?? this.session,
    );
  }
}

class RegisterController extends ChangeNotifier {
  final AuthRepository _authRepository;

  RegisterState _state;
  RegisterState get state => _state;

  RegisterController({
    required AuthRepository authRepository,
    String initialRole = 'user',
  }) : _authRepository = authRepository,
       _state = RegisterState(
         selectedRole:
             initialRole.toLowerCase() == 'artist' ? 'artist' : 'user',
       );

  void setFullName(String val) {
    _state = _state.copyWith(
      fullName: val,
      clearFullNameError: true,
      clearGeneralError: true,
    );
    notifyListeners();
  }

  void setEmail(String val) {
    _state = _state.copyWith(
      email: val,
      clearEmailError: true,
      clearGeneralError: true,
    );
    notifyListeners();
  }

  void setPassword(String val) {
    _state = _state.copyWith(
      password: val,
      clearPasswordError: true,
      clearGeneralError: true,
    );
    notifyListeners();
  }

  void setConfirmPassword(String val) {
    _state = _state.copyWith(
      confirmPassword: val,
      clearConfirmPasswordError: true,
      clearGeneralError: true,
    );
    notifyListeners();
  }

  void setRole(String role) {
    _state = _state.copyWith(selectedRole: role);
    notifyListeners();
  }

  void setAcceptTerms(bool accept) {
    _state = _state.copyWith(acceptTerms: accept, clearTermsError: true);
    notifyListeners();
  }

  void togglePasswordVisibility() {
    _state = _state.copyWith(obscurePassword: !_state.obscurePassword);
    notifyListeners();
  }

  bool validateInputs() {
    final name = _state.fullName.trim();
    final em = _state.email.trim();
    final pass = _state.password.trim();
    final confPass = _state.confirmPassword.trim();

    String? nameErr;
    String? emailErr;
    String? passErr;
    String? confPassErr;
    String? termsErr;
    bool hasErr = false;

    if (name.isEmpty) {
      nameErr = 'Full name is required';
      hasErr = true;
    }

    if (em.isEmpty) {
      emailErr = 'Email address is required';
      hasErr = true;
    } else if (!em.contains('@') || !em.contains('.')) {
      emailErr = 'Please enter a valid email address';
      hasErr = true;
    }

    if (pass.isEmpty) {
      passErr = 'Password is required';
      hasErr = true;
    } else if (pass.length < 6) {
      passErr = 'Password must be at least 6 characters';
      hasErr = true;
    }

    if (confPass.isEmpty) {
      confPassErr = 'Please confirm your password';
      hasErr = true;
    } else if (pass != confPass) {
      confPassErr = 'Passwords do not match';
      hasErr = true;
    }

    if (!_state.acceptTerms) {
      termsErr = 'Please accept the Privacy Policy and Terms of Service';
      hasErr = true;
    }

    _state = _state.copyWith(
      fullNameError: nameErr,
      emailError: emailErr,
      passwordError: passErr,
      confirmPasswordError: confPassErr,
      termsError: termsErr,
      clearFullNameError: nameErr == null,
      clearEmailError: emailErr == null,
      clearPasswordError: passErr == null,
      clearConfirmPasswordError: confPassErr == null,
      clearTermsError: termsErr == null,
    );
    notifyListeners();

    return !hasErr;
  }

  Future<AuthSession?> submitRegistration() async {
    if (!validateInputs()) return null;

    _state = _state.copyWith(
      status: RegisterStatus.loading,
      clearGeneralError: true,
    );
    notifyListeners();

    try {
      final session = await _authRepository.register(
        fullName: _state.fullName.trim(),
        email: _state.email.trim(),
        password: _state.password.trim(),
        role: _state.selectedRole,
      );

      _state = _state.copyWith(
        status: RegisterStatus.success,
        session: session,
      );
      notifyListeners();
      return session;
    } on ServerException catch (e) {
      _handleRegisterError(e.message);
      return null;
    } on UnauthorizedException catch (e) {
      _handleRegisterError(e.message);
      return null;
    } on NetworkException catch (e) {
      _state = _state.copyWith(
        status: RegisterStatus.failure,
        generalError: e.message,
      );
      notifyListeners();
      return null;
    } catch (e) {
      _state = _state.copyWith(
        status: RegisterStatus.failure,
        generalError:
            'Registration failed. Please check your connection and try again.',
      );
      notifyListeners();
      return null;
    }
  }

  void _handleRegisterError(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('email') ||
        lower.contains('already') ||
        lower.contains('exists')) {
      _state = _state.copyWith(status: RegisterStatus.failure, emailError: msg);
    } else if (lower.contains('password')) {
      _state = _state.copyWith(
        status: RegisterStatus.failure,
        passwordError: msg,
      );
    } else {
      _state = _state.copyWith(
        status: RegisterStatus.failure,
        generalError: msg,
      );
    }
    notifyListeners();
  }
}
