import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _acceptTerms = false;
  bool _isLoading = false;

  String? _fullNameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _termsError;

  bool get _isFormValid {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    return fullName.isNotEmpty &&
        email.isNotEmpty &&
        email.contains('@') &&
        email.contains('.') &&
        password.length >= 6 &&
        confirmPassword.isNotEmpty &&
        password == confirmPassword &&
        _acceptTerms;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onCreateAccount() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    setState(() {
      _fullNameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _termsError = null;
    });

    bool hasError = false;

    if (fullName.isEmpty) {
      _fullNameError = 'Full name is required';
      hasError = true;
    }

    if (email.isEmpty) {
      _emailError = 'Email address is required';
      hasError = true;
    } else if (!email.contains('@') || !email.contains('.')) {
      _emailError = 'Please enter a valid email address';
      hasError = true;
    }

    if (password.isEmpty) {
      _passwordError = 'Password is required';
      hasError = true;
    } else if (password.length < 6) {
      _passwordError = 'Password must be at least 6 characters';
      hasError = true;
    }

    if (confirmPassword.isEmpty) {
      _confirmPasswordError = 'Please confirm your password';
      hasError = true;
    } else if (password != confirmPassword) {
      _confirmPasswordError = 'Passwords do not match';
      hasError = true;
    }

    if (!_acceptTerms) {
      _termsError = 'Please accept the Privacy Policy and Terms of Service';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await sl<ApiService>().registerUser(
        name: fullName,
        email: email,
        password: password,
      );

      final storage = sl<StorageService>();
      if (res != null) {
        final user = res['user'] as Map<String, dynamic>? ?? {};
        await storage.setBool('is_logged_in', true);
        await storage.setString('user_name', user['full_name'] as String? ?? fullName);
        await storage.setString('user_email', user['email'] as String? ?? email);
        if (user['created_at'] != null) {
          await storage.setString('user_created_at', user['created_at'].toString());
        }
        if (res['token'] != null) {
          await storage.setString('auth_token', res['token'].toString());
        }

        if (mounted) {
          _showSnackBar('Account created successfully!');
          context.go(RouteNames.home);
        }
      } else {
        if (mounted) {
          _showSnackBar('Unable to register account. Please check your details.');
        }
      }
    } on ServerException catch (e) {
      if (mounted) {
        final msg = e.message;
        if (msg.toLowerCase().contains('email') || msg.toLowerCase().contains('already exist')) {
          setState(() => _emailError = msg);
        } else {
          _showSnackBar(msg);
        }
      }
    } on UnauthorizedException catch (e) {
      if (mounted) {
        _showSnackBar(e.message);
      }
    } on NetworkException catch (e) {
      if (mounted) {
        _showSnackBar(e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _emailError = 'An account with this email already exists.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFF6A2777),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildFieldError(String? error) {
    if (error == null || error.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6.0, left: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 14, color: Color(0xFFDC2626)),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    Widget? suffixIcon,
    String? errorText,
    bool isFilled = false,
  }) {
    final hasErr = errorText != null && errorText.isNotEmpty;
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF8C9BAE),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: hasErr
          ? const Color(0xFFFEF2F2)
          : (isFilled ? const Color(0xFFEDF2F9) : const Color(0xFFF9FAFB)),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6.0),
        borderSide: BorderSide(
          color: hasErr ? const Color(0xFFDC2626) : const Color(0xFF475569),
          width: 1.1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6.0),
        borderSide: BorderSide(
          color: hasErr ? const Color(0xFFDC2626) : const Color(0xFF475569),
          width: 1.1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6.0),
        borderSide: BorderSide(
          color: hasErr ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
          width: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: const AppTopBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Action Row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF1E1E1E),
                        size: 22,
                      ),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(RouteNames.home);
                        }
                      },
                    ),
                    InkWell(
                      onTap: () => context.go(RouteNames.home),
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.home_outlined,
                              color: Color(0xFF1E1E1E),
                              size: 20,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Home',
                              style: TextStyle(
                                color: Color(0xFF1E1E1E),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Centered Elevated Register Card
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 32.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Join Dubai's Artist Community",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Create Your Artist Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Full Name Field
                      const Text(
                        'Full Name',
                        style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _fullNameController,
                        onChanged: (_) {
                          setState(() {
                            _fullNameError = null;
                          });
                        },
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: 'Enter your full name',
                          errorText: _fullNameError,
                          isFilled: _fullNameController.text.isNotEmpty,
                        ),
                      ),
                      _buildFieldError(_fullNameError),
                      const SizedBox(height: 18),

                      // Email Field
                      const Text(
                        'Email',
                        style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) {
                          setState(() {
                            _emailError = null;
                          });
                        },
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: 'allenbaiyee@me.com',
                          errorText: _emailError,
                          isFilled: _emailController.text.isNotEmpty,
                        ),
                      ),
                      _buildFieldError(_emailError),
                      const SizedBox(height: 18),

                      // Password Field
                      const Text(
                        'Password',
                        style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        onChanged: (_) {
                          setState(() {
                            _passwordError = null;
                          });
                        },
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: '••••••••',
                          errorText: _passwordError,
                          isFilled: _passwordController.text.isNotEmpty,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFF475569),
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),
                      _buildFieldError(_passwordError),
                      const SizedBox(height: 18),

                      // Confirm Password Field
                      const Text(
                        'Confirm Password',
                        style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _confirmPasswordController,
                        obscureText: _obscurePassword,
                        onChanged: (_) {
                          setState(() {
                            _confirmPasswordError = null;
                          });
                        },
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: 'Confirm your password',
                          errorText: _confirmPasswordError,
                          isFilled: _confirmPasswordController.text.isNotEmpty,
                        ),
                      ),
                      _buildFieldError(_confirmPasswordError),
                      const SizedBox(height: 20),

                      // Terms & Conditions Enclosed Box
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14.0,
                          vertical: 14.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(
                            color: _termsError != null
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF475569),
                            width: 1.1,
                          ),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _acceptTerms = !_acceptTerms;
                                  if (_acceptTerms) {
                                    _termsError = null;
                                  }
                                });
                              },
                              child: Container(
                                width: 22,
                                height: 32,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3.0),
                                  border: Border.all(
                                    color: const Color(0xFF6A2777),
                                    width: 1.5,
                                  ),
                                  color: _acceptTerms
                                      ? const Color(0xFF6A2777)
                                      : Colors.transparent,
                                ),
                                child: _acceptTerms
                                    ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  text: 'I accept the ',
                                  style: const TextStyle(
                                    color: Color(0xFF374151),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: const TextStyle(
                                        color: Color(0xFF6A2777),
                                        fontWeight: FontWeight.w700,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          _showSnackBar(
                                            'Privacy Policy details',
                                          );
                                        },
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Terms of Service',
                                      style: const TextStyle(
                                        color: Color(0xFF6A2777),
                                        fontWeight: FontWeight.w700,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          _showSnackBar(
                                            'Terms of Service details',
                                          );
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildFieldError(_termsError),
                      const SizedBox(height: 24),

                      // Create Account Button
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _onCreateAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isFormValid
                                ? const Color(0xFF6A2777)
                                : const Color(0xFFA581AB),
                            foregroundColor: Colors.white,
                            elevation: _isFormValid ? 2 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign In Redirect
                      Center(
                        child: GestureDetector(
                          onTap: () => context.go(RouteNames.login),
                          child: const Text(
                            'Already have an account? Sign in',
                            style: TextStyle(
                              color: Color(0xFF6A2777),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}
