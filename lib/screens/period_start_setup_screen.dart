// lib/screens/period_start_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/cycle_provider.dart';
import 'body_metrics_screen.dart';

class PeriodStartSetupScreen extends StatefulWidget {
  const PeriodStartSetupScreen({super.key});

  @override
  State<PeriodStartSetupScreen> createState() => _PeriodStartSetupScreenState();
}

class _PeriodStartSetupScreenState extends State<PeriodStartSetupScreen>
    with TickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  int _cycleLength = 28;
  int _periodLength = 5;

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
              const Color(0xFFFF8989).withOpacity(0.08),
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
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF8989), Color(0xFFD8405B)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF8989).withOpacity(0.4),
                                blurRadius: 25,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 25),
                        const Text(
                          'Set Up Your Cycle',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF3E2723),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Help us understand your cycle better',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Last Period Date
                          _buildSectionTitle(
                              'When did your last period start?'),
                          const SizedBox(height: 15),
                          _buildDateSelector(),

                          const SizedBox(height: 30),

                          // Cycle Length
                          _buildSectionTitle('Average cycle length'),
                          const SizedBox(height: 10),
                          Text(
                            'Most cycles are between 21-35 days',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildCycleLengthSelector(),

                          const SizedBox(height: 30),

                          // Period Length
                          _buildSectionTitle('Period duration'),
                          const SizedBox(height: 10),
                          Text(
                            'How many days does your period usually last?',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildPeriodLengthSelector(),

                          const SizedBox(height: 40),
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
                        onPressed: _saveAndContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8989),
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: const Color(0xFFFF8989).withOpacity(0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Start Tracking',
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF3E2723),
      ),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now().subtract(const Duration(days: 60)),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFFFF8989),
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Color(0xFF3E2723),
                ),
              ),
              child: child!,
            );
          },
        );

        if (picked != null) {
          setState(() {
            _selectedDate = picked;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFF8989).withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8989).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: Color(0xFFFF8989),
                size: 24,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Date',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E2723),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 18,
              color: Color(0xFFFF8989),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCycleLengthSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_cycleLength days',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF8989),
                ),
              ),
              Row(
                children: [
                  _buildAdjustButton(Icons.remove_rounded, () {
                    if (_cycleLength > 21) {
                      setState(() => _cycleLength--);
                    }
                  }),
                  const SizedBox(width: 10),
                  _buildAdjustButton(Icons.add_rounded, () {
                    if (_cycleLength < 35) {
                      setState(() => _cycleLength++);
                    }
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFFFF8989),
              inactiveTrackColor: Colors.grey[200],
              thumbColor: const Color(0xFFFF8989),
              overlayColor: const Color(0xFFFF8989).withOpacity(0.2),
              trackHeight: 6,
            ),
            child: Slider(
              value: _cycleLength.toDouble(),
              min: 21,
              max: 35,
              divisions: 14,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                setState(() => _cycleLength = value.round());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodLengthSelector() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_periodLength days',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE57373),
                ),
              ),
              Row(
                children: [
                  _buildAdjustButton(Icons.remove_rounded, () {
                    if (_periodLength > 3) {
                      setState(() => _periodLength--);
                    }
                  }),
                  const SizedBox(width: 10),
                  _buildAdjustButton(Icons.add_rounded, () {
                    if (_periodLength < 7) {
                      setState(() => _periodLength++);
                    }
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFFE57373),
              inactiveTrackColor: Colors.grey[200],
              thumbColor: const Color(0xFFE57373),
              overlayColor: const Color(0xFFE57373).withOpacity(0.2),
              trackHeight: 6,
            ),
            child: Slider(
              value: _periodLength.toDouble(),
              min: 3,
              max: 7,
              divisions: 4,
              onChanged: (value) {
                HapticFeedback.selectionClick();
                setState(() => _periodLength = value.round());
              },
            ),
          ),
        ],
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
          color: const Color(0xFFFF8989).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: const Color(0xFFFF8989),
          size: 20,
        ),
      ),
    );
  }

  void _saveAndContinue() {
    HapticFeedback.mediumImpact();

    final cycleProvider = Provider.of<CycleProvider>(context, listen: false);

    // Save all the cycle information
    cycleProvider.updateLastPeriodDate(_selectedDate);
    cycleProvider.updateCycleLength(_cycleLength);
    cycleProvider.updatePeriodLength(_periodLength);

    // Navigate to body metrics screen
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim, secAnim) => const BodyMetricsScreen(),
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
    );
  }
}
