import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../../core/widgets/app_top_bar.dart';

class TermsView extends StatelessWidget {
  const TermsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppTopBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              InkWell(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(RouteNames.home);
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: Color(0xFF1E1E1E),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E1E1E),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'Terms and Conditions',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E1E1E),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 10),

              // Last Updated Date
              const Text(
                'Last updated: 22/8/2026',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 24),

              // Section: Agreement to Terms
              const Text(
                'Agreement to Terms',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'By accessing and using Dubai Artist, you accept and agree to be bound by the terms and provision of this agreement. These Terms and Conditions apply to all visitors, users and others who access or use the Service.',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF5F6368),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              // Section: Use License
              const Text(
                'Use License',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Permission is granted to temporarily download one copy of Dubai Artist materials for personal, non-commercial transitory viewing only. Under this license you may not:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF5F6368),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),

              // Bullet Points
              _buildBulletPoint('modify or copy the materials'),
              _buildBulletPoint(
                'use the materials for any commercial purpose or for any public display',
              ),
              _buildBulletPoint(
                'attempt to reverse engineer any software contained on the website',
              ),
              _buildBulletPoint(
                'remove any copyright or other proprietary notations from the materials',
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: -1),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0, left: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 7.0, right: 10.0),
            child: Icon(Icons.circle, size: 5.5, color: Color(0xFF757575)),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14.5,
                color: Color(0xFF5F6368),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
