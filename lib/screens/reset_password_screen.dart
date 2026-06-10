// lib/screens/reset_password_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_toast.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top gradient header
            ClipPath(
              clipper: _WaveClipper(),
              child: Container(
                height: 260,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      LunaraColors.primary,
                      LunaraColors.primaryDark,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: 50,
                      right: 30,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 120,
                      left: 40,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Header text
                    Positioned(
                      top: 70,
                      left: 30,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.lock_reset_rounded,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "Set New Password",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              "Choose a strong password for your account",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Form content
            SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Info card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: LunaraColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: LunaraColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: LunaraColors.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Your new password must be at least 6 characters long.",
                                style: TextStyle(
                                  color: LunaraColors.primaryDark,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // New Password
                      _buildLabel("New Password"),
                      const SizedBox(height: 10),
                      _buildPasswordField(
                        controller: _passwordController,
                        hint: "Enter new password",
                        isVisible: _isPasswordVisible,
                        onToggle: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible),
                      ),

                      const SizedBox(height: 25),

                      // Confirm Password
                      _buildLabel("Confirm Password"),
                      const SizedBox(height: 10),
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        hint: "Re-enter new password",
                        isVisible: _isConfirmPasswordVisible,
                        onToggle: () => setState(() =>
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible),
                      ),

                      const SizedBox(height: 40),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _resetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LunaraColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: LunaraColors.primary.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 22),
                              SizedBox(width: 10),
                              Text(
                                "Update Password",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
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
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: AppTheme.textDark(context),
        fontSize: 14,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        style: TextStyle(color: AppTheme.textDark(context)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.lock_outline,
              color: LunaraColors.primary, size: 22),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.grey,
              size: 22,
            ),
            onPressed: onToggle,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  void _resetPassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validation
    if (password.isEmpty || password.length < 6) {
      _showError("Password must be at least 6 characters");
      return;
    }
    if (password != confirmPassword) {
      _showError("Passwords do not match");
      return;
    }

    HapticFeedback.mediumImpact();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: LunaraColors.primary),
      ),
    );

    final error = await Provider.of<AuthProvider>(context, listen: false)
        .updatePassword(password);

    if (mounted) Navigator.pop(context); // hide loading

    if (error == null) {
      // Success
      if (mounted) {
        CustomToast.show(context, message: 'Password updated successfully!', icon: Icons.check_circle, backgroundColor: const Color(0xFF4CAF50));

        // Sign out so they log in with the new password
        await Provider.of<AuthProvider>(context, listen: false).logout();
      }
    } else {
      if (mounted) _showError(error);
    }
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    CustomToast.show(context, message: message, icon: Icons.error_outline, backgroundColor: Colors.red[400]);
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.65);
    var firstControlPoint = Offset(size.width * 0.25, size.height * 0.85);
    var firstEndPoint = Offset(size.width * 0.5, size.height * 0.75);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);
    var secondControlPoint = Offset(size.width * 0.75, size.height * 0.65);
    var secondEndPoint = Offset(size.width, size.height * 0.7);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
