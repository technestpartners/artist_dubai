import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../controllers/register_controller.dart';
import '../widgets/auth_error_banner_widget.dart';
import '../widgets/login_header_widget.dart';

/// Clean presentation view for User and Artist registration.
/// Business logic and state management are fully delegated to [RegisterController].
class RegisterView extends StatefulWidget {
  const RegisterView({super.key, this.initialRole = 'user'});

  final String initialRole;

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final RegisterController _controller;
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = sl<RegisterController>(param1: widget.initialRole);
    _controller.addListener(_onControllerStateChanged);
  }

  void _onControllerStateChanged() {
    if (!mounted) return;
    final generalErr = _controller.state.generalError;
    if (generalErr != null && generalErr.isNotEmpty) {
      _showSnackBar(generalErr);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerStateChanged);
    _controller.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateAccount() async {
    final session = await _controller.submitRegistration();
    if (session != null && mounted) {
      final l10n = AppLocalizations.of(context);
      if (_controller.state.selectedRole == 'user') {
        _showSnackBar(l10n.accountCreatedEnthusiast);
        if (context.canPop()) {
          context.pop(true);
        } else {
          context.go(RouteNames.events);
        }
      } else {
        _showSnackBar(l10n.accountCreatedArtist);
        context.go(RouteNames.artistRegistration);
      }
    }
  }

  Widget _buildPasswordStrengthIndicator(String password) {
    if (password.isEmpty) return const SizedBox.shrink();
    int score = 0;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) score++;

    double percent = (score / 5.0).clamp(0.2, 1.0);
    Color color;
    String label;
    if (score <= 1) {
      color = const Color(0xFFDC2626);
      label = 'Weak';
    } else if (score <= 2) {
      color = const Color(0xFFF97316);
      label = 'Fair';
    } else if (score <= 3) {
      color = const Color(0xFFEAB308);
      label = 'Good';
    } else {
      color = const Color(0xFF16A34A);
      label = 'Strong';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: const Color(0xFFE5E7EB),
              color: color,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Password strength: $label',
            style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
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

  Widget _buildFieldLabel(String label, {bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: RichText(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Color(0xFF1F2937),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          children:
              isRequired
                  ? const [
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ]
                  : null,
        ),
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
      fillColor:
          hasErr
              ? const Color(0xFFFEF2F2)
              : (isFilled ? const Color(0xFFEDF2F9) : const Color(0xFFF9FAFB)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
    final l10n = AppLocalizations.of(context);
    final rh = ResponsiveHelper.of(context);

    return ChangeNotifierProvider<RegisterController>.value(
      value: _controller,
      child: Consumer<RegisterController>(
        builder: (context, controller, _) {
          final state = controller.state;
          return Scaffold(
            backgroundColor: const Color(0xFF6B1C9B),
            appBar: const AppTopBar(backgroundColor: Colors.white),
            body: SafeArea(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: rh.isWide ? 520.0 : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Action Row
                        LoginHeader(horizontalPadding: rh.horizontalPadding),

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
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
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
                                Text(
                                  l10n.registerAccountTitle,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF111827),
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.registerAccountSubtitle,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                if (state.generalError != null &&
                                    state.generalError!.isNotEmpty) ...[
                                  AuthErrorBanner(message: state.generalError!),
                                  const SizedBox(height: 16),
                                ],

                                // 1. Full Name Field
                                _buildFieldLabel(l10n.fullName),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _fullNameController,
                                  onChanged:
                                      (val) => _controller.setFullName(val),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: _buildInputDecoration(
                                    hintText: l10n.enterFullName,
                                    errorText: state.fullNameError,
                                    isFilled:
                                        _fullNameController.text.isNotEmpty,
                                  ),
                                ),
                                AuthErrorBanner(errorText: state.fullNameError),
                                const SizedBox(height: 18),

                                // 2. Email Field
                                _buildFieldLabel(l10n.email),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  onChanged: (val) => _controller.setEmail(val),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: _buildInputDecoration(
                                    hintText: 'allenbaiyee@me.com',
                                    errorText: state.emailError,
                                    isFilled: _emailController.text.isNotEmpty,
                                  ),
                                ),
                                AuthErrorBanner(errorText: state.emailError),
                                const SizedBox(height: 18),

                                // 3. Password Field
                                _buildFieldLabel(l10n.passwordLabel),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: state.obscurePassword,
                                  onChanged:
                                      (val) => _controller.setPassword(val),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: _buildInputDecoration(
                                    hintText: '••••••••',
                                    errorText: state.passwordError,
                                    isFilled:
                                        _passwordController.text.isNotEmpty,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        state.obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: const Color(0xFF475569),
                                        size: 20,
                                      ),
                                      onPressed:
                                          _controller.togglePasswordVisibility,
                                    ),
                                  ),
                                ),
                                AuthErrorBanner(errorText: state.passwordError),
                                _buildPasswordStrengthIndicator(_passwordController.text),
                                const SizedBox(height: 18),

                                // 4. Confirm Password Field
                                _buildFieldLabel(l10n.confirmPasswordLabel),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _confirmPasswordController,
                                  obscureText: state.obscurePassword,
                                  onChanged:
                                      (val) =>
                                          _controller.setConfirmPassword(val),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: _buildInputDecoration(
                                    hintText: l10n.enterConfirmPassword,
                                    errorText: state.confirmPasswordError,
                                    isFilled:
                                        _confirmPasswordController
                                            .text
                                            .isNotEmpty,
                                  ),
                                ),
                                AuthErrorBanner(
                                  errorText: state.confirmPasswordError,
                                ),
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
                                      color:
                                          state.termsError != null
                                              ? const Color(0xFFDC2626)
                                              : const Color(0xFF475569),
                                      width: 1.1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap:
                                            () => _controller.setAcceptTerms(
                                              !state.acceptTerms,
                                            ),
                                        child: Container(
                                          width: 22,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              3.0,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFF6A2777),
                                              width: 1.5,
                                            ),
                                            color:
                                                state.acceptTerms
                                                    ? const Color(0xFF6A2777)
                                                    : Colors.transparent,
                                          ),
                                          child:
                                              state.acceptTerms
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
                                            text: l10n.acceptTermsPrefix,
                                            style: const TextStyle(
                                              color: Color(0xFF374151),
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            children: [
                                              TextSpan(
                                                text: l10n.privacyPolicy,
                                                style: const TextStyle(
                                                  color: Color(0xFF6A2777),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                recognizer:
                                                    TapGestureRecognizer()
                                                      ..onTap = () {
                                                        _showSnackBar(
                                                          l10n.privacyPolicyDetails,
                                                        );
                                                      },
                                              ),
                                              TextSpan(text: l10n.andWord),
                                              TextSpan(
                                                text: l10n.termsOfService,
                                                style: const TextStyle(
                                                  color: Color(0xFF6A2777),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                recognizer:
                                                    TapGestureRecognizer()
                                                      ..onTap = () {
                                                        _showSnackBar(
                                                          l10n.termsOfServiceDetails,
                                                        );
                                                      },
                                              ),
                                              const TextSpan(
                                                text: ' *',
                                                style: TextStyle(
                                                  color: Color(0xFFDC2626),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AuthErrorBanner(errorText: state.termsError),
                                const SizedBox(height: 24),

                                // Create Account Button
                                SizedBox(
                                  height: 44,
                                  child: ElevatedButton(
                                    onPressed:
                                        state.isLoading
                                            ? null
                                            : _handleCreateAccount,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          state.isFormValid
                                              ? const Color(0xFF6A2777)
                                              : const Color(0xFFA581AB),
                                      foregroundColor: Colors.white,
                                      elevation: state.isFormValid ? 2 : 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          6.0,
                                        ),
                                      ),
                                    ),
                                    child:
                                        state.isLoading
                                            ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                            : Text(
                                              l10n.createAccount,
                                              style: const TextStyle(
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
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => context.go(RouteNames.login),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        '${l10n.alreadyHaveAccount}  ${l10n.signInNow}',
                                        style: const TextStyle(
                                          color: Color(0xFF6A2777),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
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
              ),
            ),
            bottomNavigationBar: null,
          );
        },
      ),
    );
  }
}
