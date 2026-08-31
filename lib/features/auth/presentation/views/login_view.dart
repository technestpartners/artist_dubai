import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;

  bool get _isLoginFormValid {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    return email.isNotEmpty && email.contains('@') && password.isNotEmpty;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    bool hasError = false;

    if (email.isEmpty) {
      _emailError = 'Please enter your email address';
      hasError = true;
    } else if (!email.contains('@') || !email.contains('.')) {
      _emailError = 'Please enter a valid email address';
      hasError = true;
    }

    if (password.isEmpty) {
      _passwordError = 'Please enter your password';
      hasError = true;
    }

    if (hasError) {
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userData = await sl<ApiService>().login(email, password);
      final storage = sl<StorageService>();

      if (userData != null) {
        final user = userData['user'] as Map<String, dynamic>? ?? {};
        final userEmail = (user['email'] as String? ?? email).trim().toLowerCase();
        final role = (user['role'] as String? ?? (userEmail.contains('admin') ? 'admin' : 'user')).toLowerCase();
        final isAdmin = role == 'admin' ||
            user['is_admin'] == true ||
            userEmail == 'admin@artistdubai.com' ||
            userEmail == 'admin@dubaiart.ae' ||
            userEmail == 'admin@admin.com';

        await storage.setBool('is_logged_in', true);
        await storage.setBool('is_admin', isAdmin);
        await storage.setString('user_role', role);
        await storage.setString('user_email', user['email'] as String? ?? email);
        await storage.setString('user_name', user['full_name'] as String? ?? (isAdmin ? 'Admin' : 'User'));
        if (user['created_at'] != null) {
          await storage.setString('user_created_at', user['created_at'].toString());
        }
        if (userData['token'] != null) {
          await storage.setString('auth_token', userData['token'].toString());
        }

        if (mounted) {
          if (isAdmin) {
            _showSnackBar('Signed in as Admin!');
            context.go(RouteNames.adminDashboard);
          } else {
            _showSnackBar('Signed in successfully!');
            context.go(RouteNames.artists);
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _emailError = 'User is not available. Please create an account first.';
          });
        }
      }
    } on ServerException catch (e) {
      if (mounted) {
        final msg = e.message;
        final lower = msg.toLowerCase();
        if (lower.contains('password')) {
          setState(() => _passwordError = msg);
        } else if (lower.contains('user') || lower.contains('account') || lower.contains('email') || lower.contains('available')) {
          setState(() => _emailError = msg);
        } else {
          _showSnackBar(msg);
        }
      }
    } on UnauthorizedException catch (e) {
      if (mounted) {
        final msg = e.message;
        final lower = msg.toLowerCase();
        if (lower.contains('password')) {
          setState(() => _passwordError = msg);
        } else {
          setState(() => _emailError = msg);
        }
      }
    } on NetworkException catch (e) {
      if (mounted) {
        _showSnackBar(e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _emailError = 'User is not available. Please create an account first.';
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
    required IconData icon,
    Widget? suffixIcon,
    String? errorText,
  }) {
    final hasErr = errorText != null && errorText.isNotEmpty;
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: hasErr ? const Color(0xFFDC2626) : Colors.black,
        size: 20,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: hasErr ? const Color(0xFFFEF2F2) : const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: hasErr ? const Color(0xFFDC2626) : const Color(0xFFE5E7EB),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: hasErr ? const Color(0xFFDC2626) : const Color(0xFFE5E7EB),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: hasErr ? const Color(0xFFDC2626) : const Color(0xFF6A2777),
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
              // Top Action Row (Back Arrow and Home button)
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

              // Centered Elevated Login Card
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
                        'Login to Your Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF1E1E1E),
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Welcome back! Enter your credentials to access your account',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Email Field
                      const Text(
                        'Email Address',
                        style: TextStyle(
                          color: Color(0xFF374151),
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
                          hintText: 'name@example.com',
                          icon: Icons.email_outlined,
                          errorText: _emailError,
                        ),
                      ),
                      _buildFieldError(_emailError),
                      const SizedBox(height: 18),

                      // Password Field
                      const Text(
                        'Password',
                        style: TextStyle(
                          color: Color(0xFF374151),
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
                          hintText: 'Enter your password',
                          icon: Icons.lock_outline,
                          errorText: _passwordError,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.black,
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
                      const SizedBox(height: 24),

                      // Sign In Button
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _onSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isLoginFormValid
                                ? const Color(0xFF6A2777)
                                : const Color(0xFFA581AB),
                            foregroundColor: Colors.white,
                            elevation: _isLoginFormValid ? 2 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign Up Redirect
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 13,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go(RouteNames.register),
                            child: const Text(
                              'Sign Up',
                              style: TextStyle(
                                color: Color(0xFF6A2777),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
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
