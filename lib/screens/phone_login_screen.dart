import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'otp_verification_screen.dart';
import '../widgets/custom_toast.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _showError(BuildContext context, String message) {
    CustomToast.show(context, message: message, icon: Icons.check_circle, backgroundColor: const Color(0xFF4CAF50));
  }

  Future<void> _submitPhone() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 7) {
      _showError(context, "Please enter a valid phone number (e.g. +1234567890)");
      return;
    }

    if (!phone.startsWith('+')) {
      _showError(context, "Please include your country code starting with '+'");
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
          child: CircularProgressIndicator(color: LunaraColors.primary)),
    );

    final error = await Provider.of<AuthProvider>(context, listen: false).signInWithOTP(phone);
    
    if (mounted) {
      Navigator.pop(context); // Hide loading
    }

    if (error == null) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(phone: phone),
          ),
        );
      }
    } else {
      if (mounted) {
        _showError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: const Text('Phone Sign In'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "What's your number?",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "We'll send you a 6-digit code to log you in.",
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
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
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: AppTheme.textDark(context), fontSize: 18),
                decoration: InputDecoration(
                  hintText: "+1234567890",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(Icons.phone_outlined,
                      color: LunaraColors.primary, size: 22),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppTheme.cardColor(context),
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _submitPhone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LunaraColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 8,
                  shadowColor: LunaraColors.primary.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Continue",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
