// lib/screens/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/cycle_provider.dart';
import '../widgets/custom_toast.dart';
import '../main.dart';
import 'onboarding_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  int _selectedAge = 25;
  String _selectedGender = 'Female';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  late AnimationController _entryController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic));

    _entryController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.5),
            radius: 1.5,
            colors: [
              LunaraColors.primary.withOpacity(0.08),
              AppTheme.background(context),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),

                          // Back button
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.cardColor(context),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(Icons.arrow_back_rounded,
                                  color: AppTheme.textDark(context)),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Welcome Section
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        LunaraColors.primary,
                                        LunaraColors.primaryDark
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: LunaraColors.primary
                                            .withOpacity(0.4),
                                        blurRadius: 25,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.favorite_rounded,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Join Lunara and start your wellness journey',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Name Input
                          _buildLabel("What's your name?"),
                          const SizedBox(height: 10),
                          _buildTextField(
                            controller: _nameController,
                            hint: 'Enter your name',
                            icon: Icons.person_outline_rounded,
                          ),

                          const SizedBox(height: 25),

                          // Email Input
                          _buildLabel("Email"),
                          const SizedBox(height: 10),
                          _buildTextField(
                            controller: _emailController,
                            hint: 'your@email.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ),

                          const SizedBox(height: 25),

                          // Password Input
                          _buildLabel("Password"),
                          const SizedBox(height: 10),
                          _buildPasswordField(
                            controller: _passwordController,
                            hint: 'At least 6 characters',
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
                            hint: 'Re-enter your password',
                            isVisible: _isConfirmPasswordVisible,
                            onToggle: () => setState(() =>
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible),
                          ),

                          const SizedBox(height: 30),

                          // Age Selector
                          _buildLabel('How old are you?'),
                          const SizedBox(height: 15),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.cardColor(context),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '$_selectedAge years',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: LunaraColors.primary,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        _buildAdjustButton(Icons.remove_rounded,
                                            () {
                                          if (_selectedAge > 13) {
                                            setState(() => _selectedAge--);
                                          }
                                        }),
                                        const SizedBox(width: 10),
                                        _buildAdjustButton(Icons.add_rounded,
                                            () {
                                          if (_selectedAge < 60) {
                                            setState(() => _selectedAge++);
                                          }
                                        }),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                SliderTheme(
                                  data: SliderThemeData(
                                    activeTrackColor: LunaraColors.primary,
                                    inactiveTrackColor: Colors.grey[200],
                                    thumbColor: LunaraColors.primary,
                                    overlayColor:
                                        LunaraColors.primary.withOpacity(0.2),
                                    trackHeight: 6,
                                  ),
                                  child: Slider(
                                    value: _selectedAge.toDouble(),
                                    min: 13,
                                    max: 60,
                                    divisions: 47,
                                    onChanged: (value) {
                                      HapticFeedback.selectionClick();
                                      setState(
                                          () => _selectedAge = value.round());
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Gender Selection
                          _buildLabel('I am...'),
                          const SizedBox(height: 15),
                          Row(
                            children: [
                              Expanded(
                                child: _buildGenderCard(
                                  'Female',
                                  Icons.female_rounded,
                                  LunaraColors.primary,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: _buildGenderCard(
                                  'Male',
                                  Icons.male_rounded,
                                  const Color(0xFF118AB2),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // Continue Button
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _signUp,
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
                            Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 10),
                            Icon(Icons.arrow_forward_rounded, size: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── HELPER WIDGETS ──────────────────────────────

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textDark(context),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: LunaraColors.primary),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textDark(context),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          prefixIcon:
              const Icon(Icons.lock_outline, color: LunaraColors.primary),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: Colors.grey,
            ),
            onPressed: onToggle,
          ),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textDark(context),
        ),
      ),
    );
  }

  Widget _buildGenderCard(String gender, IconData icon, Color color) {
    final isSelected = _selectedGender == gender;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedGender = gender);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                )
              : null,
          color: isSelected ? null : AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withOpacity(0.3)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(height: 10),
            Text(
              gender,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppTheme.textDark(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: LunaraColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: LunaraColors.primary,
          size: 20,
        ),
      ),
    );
  }

  // ─── SIGN UP LOGIC ───────────────────────────────

  void _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validation
    if (name.isEmpty || name.length > 50) {
      _showError('Please enter a valid name (1-50 characters)');
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (email.isEmpty || email.length > 255 || !emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email address');
      return;
    }

    if (password.length < 8 || password.length > 128) {
      _showError('Password must be between 8 and 128 characters');
      return;
    }
    if (password != confirmPassword) {
      _showError('Passwords do not match');
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

    try {
      // Call Supabase signup
      final error =
          await Provider.of<AuthProvider>(context, listen: false).signUp(
        email: email,
        password: password,
        name: name,
      );

      // ignore: use_build_context_synchronously
      if (mounted) Navigator.pop(context); // hide loading

      if (error == null) {
        // Save user info locally
        if (mounted) {
          final cycleProvider =
              Provider.of<CycleProvider>(context, listen: false);
          cycleProvider.updateUserName(name);
          cycleProvider.setAge(_selectedAge);
          cycleProvider.setUserGender(_selectedGender);
        }

        // Show success message
        if (mounted) {
          CustomToast.show(context, message: 'Account created successfully! 🎉', icon: Icons.check_circle, backgroundColor: const Color(0xFF4CAF50));
        }

        // Navigate to main app (InitialRouter handles assessment)
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            PageRouteBuilder(
              pageBuilder: (context, anim, secAnim) => const OnboardingScreen(),
              transitionsBuilder: (context, anim, secAnim, child) {
                return FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.95, end: 1.0).animate(anim),
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
            (route) => false,
          );
        }
      } else {
        // Show error from Supabase
        if (mounted) {
          if (error.toLowerCase().contains('already registered')) {
            _showError('Account already created');
          } else {
            _showError(error);
          }
        }
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      if (mounted) Navigator.pop(context);
      if (mounted) _showError('An error occurred: $e');
    }
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    CustomToast.show(context, message: message, icon: Icons.error_outline, backgroundColor: Colors.red[400]);
  }
}
