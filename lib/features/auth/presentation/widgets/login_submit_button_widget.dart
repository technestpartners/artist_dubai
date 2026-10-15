import 'package:flutter/material.dart';

/// Standard auth submit action button supporting loading spinner and validity state.
class LoginSubmitButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback? onPressed;

  const LoginSubmitButton({
    super.key,
    required this.label,
    required this.isLoading,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: (isLoading || !isEnabled) ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isEnabled ? const Color(0xFF6A2777) : const Color(0xFFA581AB),
          disabledBackgroundColor:
              isLoading ? const Color(0xFF6A2777) : const Color(0xFFA581AB),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: isEnabled ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child:
            isLoading
                ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
      ),
    );
  }
}
