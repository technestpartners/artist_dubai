import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:artist_dubai/l10n/app_localizations.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/responsive_helper.dart';
import '../../../../core/widgets/app_top_bar.dart';
import '../controllers/login_controller.dart';
import '../widgets/auth_error_banner_widget.dart';
import '../widgets/auth_text_field_widget.dart';
import '../widgets/login_header_widget.dart';
import '../widgets/login_submit_button_widget.dart';

/// Clean presentation view for User and Admin authentication.
/// Business logic and state management are fully delegated to [LoginController].
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final LoginController _controller;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = sl<LoginController>();
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final l10n = AppLocalizations.of(context);

    final session = await _controller.submitLogin(
      enterEmailMsg: l10n.enterEmail,
      enterValidEmailMsg: l10n.enterValidEmail,
      enterPasswordMsg: l10n.enterPassword,
      userNotFoundMsg: l10n.userNotAvailable,
    );

    if (session != null && mounted) {
      final currentL10n = AppLocalizations.of(context);
      if (session.isAdmin) {
        _showSnackBar(currentL10n.signedInAsAdmin);
        context.go(RouteNames.adminDashboard);
      } else {
        _showSnackBar(currentL10n.loginSuccess);
        if (context.canPop()) {
          context.pop(true);
        } else {
          context.go(RouteNames.home);
        }
      }
    }
  }

  void _showForgotPasswordDialog() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final emailController = TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isAr ? 'إعادة تعيين كلمة المرور' : 'Reset Password',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAr
                  ? 'أدخل بريدك الإلكتروني المسجل وسنرسل لك تعليمات إعادة تعيين كلمة المرور.'
                  : 'Enter your registered email address and we will send you password reset instructions.',
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF4A4A4A)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: isAr ? 'البريد الإلكتروني' : 'Email Address',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A2777),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final email = emailController.text.trim();
              Navigator.of(ctx).pop();
              if (email.isNotEmpty) {
                _showSnackBar(
                  isAr
                      ? 'تم إرسال رابط إعادة تعيين كلمة المرور إذا كان الحساب مسجلاً لدينا.'
                      : 'Password reset link sent if account is registered.',
                );
              }
            },
            child: Text(isAr ? 'إرسال الرابط' : 'Send Reset Link'),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rh = ResponsiveHelper.of(context);
    final hPad = rh.isWide ? rh.horizontalPadding : 16.0;

    return ChangeNotifierProvider<LoginController>.value(
      value: _controller,
      child: Consumer<LoginController>(
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
                        // 1. Navigation Header
                        LoginHeader(horizontalPadding: hPad),

                        // 2. Centered Login Card
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
                                  l10n.loginToYourAccount,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF1E1E1E),
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  l10n.welcomeBackLogin,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                if (state.generalError != null &&
                                    state.generalError!.isNotEmpty) ...[
                                  AuthErrorBanner(message: state.generalError!),
                                  const SizedBox(height: 16),
                                ],

                                // Email Input Field
                                AuthTextField(
                                  controller: _emailController,
                                  label: l10n.emailAddress,
                                  hintText: 'name@example.com',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  errorText: state.emailError,
                                  onChanged: (val) => _controller.setEmail(val),
                                ),
                                const SizedBox(height: 18),

                                // Password Input Field
                                AuthTextField(
                                  controller: _passwordController,
                                  label: l10n.passwordLabel,
                                  hintText: l10n.enterYourPassword,
                                  prefixIcon: Icons.lock_outline,
                                  obscureText: state.obscurePassword,
                                  errorText: state.passwordError,
                                  onChanged:
                                      (val) => _controller.setPassword(val),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      state.obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.black,
                                      size: 20,
                                    ),
                                    onPressed:
                                        _controller.togglePasswordVisibility,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Forgot Password Link
                                Align(
                                  alignment: AlignmentDirectional.centerEnd,
                                  child: TextButton(
                                    onPressed: _showForgotPasswordDialog,
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF6A2777),
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    ),
                                    child: Text(
                                      Localizations.localeOf(context).languageCode == 'ar'
                                          ? 'نسيت كلمة المرور؟'
                                          : 'Forgot password?',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Sign In Button
                                LoginSubmitButton(
                                  label: l10n.signIn,
                                  isLoading: state.isLoading,
                                  isEnabled: state.isFormValid,
                                  onPressed: _handleSignIn,
                                ),
                                const SizedBox(height: 24),

                                // Sign Up Link
                                Center(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap:
                                        () => context.go(
                                          RouteNames.register,
                                          extra: 'user',
                                        ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                        horizontal: 12,
                                      ),
                                      child: RichText(
                                        textAlign: TextAlign.center,
                                        text: TextSpan(
                                          style: const TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontSize: 13,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: l10n.dontHaveAccount,
                                            ),
                                            TextSpan(
                                              text: l10n.signUpFree,
                                              style: const TextStyle(
                                                color: Color(0xFF6A2777),
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
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
