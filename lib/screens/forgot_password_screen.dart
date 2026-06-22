// File: lib/screens/forgot_password_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

import '../theme/app_theme.dart';
import '../widgets/custom_toast.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Wavy Header
            Stack(
              children: [
                ClipPath(
                  clipper: LoginWaveClipper(),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    color: LunaraColors.primary,
                  ),
                ),
                // Back Button
                Positioned(
                  top: 50,
                  left: 20,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),

            // 2. Main Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Don't worry! It happens. Please enter the email associated with your account and we'll send you a reset link.",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email Input Field
                  const Text(
                    "Email ID",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: "Enter your email",
                      prefixIcon: Icon(Icons.alternate_email,
                          color: Colors.grey, size: 20),
                      contentPadding: EdgeInsets.symmetric(vertical: 15),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: LunaraColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _sendResetEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LunaraColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                        shadowColor: LunaraColors.primary,
                      ),
                      child: const Text(
                        "Send Reset Link",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendResetEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      CustomToast.show(context, message: 'Please enter a valid email address', icon: Icons.error_outline, backgroundColor: Colors.orange[400]);
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: LunaraColors.primary),
      ),
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check if email is actually registered in the database
    final isRegistered = await authProvider.checkEmailExists(email);

    if (!isRegistered) {
      if (mounted) Navigator.pop(context); // hide loading
      if (mounted) {
        CustomToast.show(
          context, 
          message: 'This email is not registered. Please sign up first.', 
          icon: Icons.error_outline, 
          backgroundColor: Colors.red[400]
        );
      }
      return;
    }

    final error = await authProvider.resetPassword(email);

    // ignore: use_build_context_synchronously
    if (mounted) Navigator.pop(context); // hide loading

    if (error == null) {
      // Success
      if (mounted) {
        CustomToast.show(context, message: 'Password reset link sent! Check your email 📧', icon: Icons.check_circle, backgroundColor: const Color(0xFF4CAF50));
        Navigator.pop(context); // go back to login
      }
    } else {
      // Error
      if (mounted) {
        CustomToast.show(context, message: error, icon: Icons.error_outline, backgroundColor: Colors.red[400]);
      }
    }
  }
}

// Reusing the Wave Clipper for consistency
class LoginWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);

    var firstControlPoint = Offset(size.width / 3.5, size.height);
    var firstEndPoint = Offset(size.width / 1.8, size.height - 40);

    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint =
        Offset(size.width - (size.width / 4), size.height - 90);
    var secondEndPoint = Offset(size.width, size.height - 20);

    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
