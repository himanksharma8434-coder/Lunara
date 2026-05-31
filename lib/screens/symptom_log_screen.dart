// lib/screens/symptom_log_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'bbt_log_screen.dart';

class SymptomLogScreen extends StatefulWidget {
  const SymptomLogScreen({super.key});

  @override
  State<SymptomLogScreen> createState() => _SymptomLogScreenState();
}

class _SymptomLogScreenState extends State<SymptomLogScreen> {
  final Set<String> _selectedSymptoms = {};

  final List<Map<String, dynamic>> _symptoms = [
    {
      'name': 'Cramps',
      'icon': Icons.flash_on_rounded,
      'color': LunaraColors.primary
    },
    {
      'name': 'Headache',
      'icon': Icons.psychology_rounded,
      'color': LunaraColors.warning
    },
    {
      'name': 'Fatigue',
      'icon': Icons.battery_0_bar_rounded,
      'color': const Color(0xFFBA68C8)
    },
    {
      'name': 'Bloating',
      'icon': Icons.expand_rounded,
      'color': LunaraColors.ovulationBlue
    },
    {
      'name': 'Mood Swings',
      'icon': Icons.mood_rounded,
      'color': const Color(0xFFFFD54F)
    },
    {
      'name': 'Nausea',
      'icon': Icons.sick_rounded,
      'color': LunaraColors.fertileGreen
    },
    {
      'name': 'Back Pain',
      'icon': Icons.airline_seat_recline_normal_rounded,
      'color': const Color(0xFFE57373)
    },
    {
      'name': 'Breast Tenderness',
      'icon': Icons.favorite_rounded,
      'color': LunaraColors.primary
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: AppTheme.textDark(context)),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Log Symptoms',
          style: TextStyle(
              color: AppTheme.textDark(context), fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  'What are you experiencing today?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _symptoms.map((symptom) {
                    final isSelected =
                        _selectedSymptoms.contains(symptom['name']);
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          if (isSelected) {
                            _selectedSymptoms.remove(symptom['name']);
                          } else {
                            _selectedSymptoms.add(symptom['name']);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? symptom['color'].withOpacity(0.2)
                              : AppTheme.cardColor(context),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? symptom['color']
                                : Colors.grey.shade300,
                            width: 2,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: symptom['color'].withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              symptom['icon'],
                              color: symptom['color'],
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              symptom['name'],
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? symptom['color']
                                    : AppTheme.textDark(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Advanced Clinical Tracking',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Log clinical markers for higher fertility precision.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                _buildAdvancedTrackingCard(
                  context,
                  'BBT & Cervical Mucus',
                  'Confirmed ovulation requires daily logging',
                  Icons.biotech_rounded,
                  LunaraColors.ovulationBlue,
                ),
                const SizedBox(height: 100), // Space for bottom button
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _selectedSymptoms.isEmpty
                    ? null
                    : () {
                        HapticFeedback.mediumImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${_selectedSymptoms.length} symptom(s) logged'),
                            backgroundColor: const Color(0xFF06D6A0),
                          ),
                        );
                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: LunaraColors.primary,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  _selectedSymptoms.isEmpty
                      ? 'Select Symptoms'
                      : 'Save ${_selectedSymptoms.length} Symptom(s)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildAdvancedTrackingCard(BuildContext context, String title,
      String subtitle, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BbtLogScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark(context),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}
