import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cycle_provider.dart';
import '../theme/app_theme.dart';

/// Quick-log screen for Basal Body Temperature and Cervical Mucus.
///
/// Uses a temperature slider (35.5–38.0°C) and a visual CM selector
/// with 5 clinical categories. Data is persisted via [CycleProvider]
/// and feeds into the [MenstrualIntelligenceService] for ovulation
/// confirmation.
class BbtLogScreen extends StatefulWidget {
  const BbtLogScreen({super.key});

  @override
  State<BbtLogScreen> createState() => _BbtLogScreenState();
}

class _BbtLogScreenState extends State<BbtLogScreen> {
  double _bbt = 36.5;
  String? _selectedCm;
  bool _bbtChanged = false;

  static const List<Map<String, dynamic>> _cmOptions = [
    {
      'value': 'Dry',
      'label': 'Dry',
      'icon': Icons.wb_sunny_rounded,
      'description': 'No noticeable mucus',
      'color': Color(0xFFBDBDBD),
    },
    {
      'value': 'Sticky',
      'label': 'Sticky',
      'icon': Icons.water_drop_outlined,
      'description': 'Thick, pasty, crumbly',
      'color': Color(0xFFFFB74D),
    },
    {
      'value': 'Creamy',
      'label': 'Creamy',
      'icon': Icons.water_drop_rounded,
      'description': 'Lotion-like, white',
      'color': Color(0xFFFFD54F),
    },
    {
      'value': 'EggWhite',
      'label': 'Egg White',
      'icon': Icons.opacity_rounded,
      'description': 'Clear, stretchy, slippery',
      'color': Color(0xFF81C784),
    },
    {
      'value': 'Watery',
      'label': 'Watery',
      'icon': Icons.waves_rounded,
      'description': 'Thin, clear, wet',
      'color': Color(0xFF64B5F6),
    },
  ];

  @override
  void initState() {
    super.initState();
    final provider = context.read<CycleProvider>();
    if (provider.todayBbt != null) {
      _bbt = provider.todayBbt!;
      _bbtChanged = true;
    }
    _selectedCm = provider.todayCervicalMucus;
  }

  @override
  Widget build(BuildContext context) {
    final hasData = _bbtChanged || _selectedCm != null;

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
          'BBT & Cervical Mucus',
          style: TextStyle(
            color: AppTheme.textDark(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // ── BBT Section ────────────────────────────────
                Text(
                  'Basal Body Temperature',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Take your temperature first thing in the morning, before getting out of bed.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textLight(context),
                  ),
                ),
                const SizedBox(height: 16),

                // Temperature display
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(LunaraRadius.lg),
                    boxShadow: AppTheme.softShadow(context),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${_bbt.toStringAsFixed(2)}°C',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          color: _bbtColor,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _bbtLabel,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textLight(context),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: _bbtColor,
                          inactiveTrackColor:
                              _bbtColor.withOpacity(0.2),
                          thumbColor: _bbtColor,
                          overlayColor: _bbtColor.withOpacity(0.1),
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 10),
                        ),
                        child: Slider(
                          value: _bbt,
                          min: 35.5,
                          max: 38.0,
                          divisions: 50, // 0.05°C steps
                          onChanged: (value) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _bbt = value;
                              _bbtChanged = true;
                            });
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('35.50°C',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textLight(context))),
                          Text('38.00°C',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textLight(context))),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Cervical Mucus Section ──────────────────────
                Text(
                  'Cervical Mucus',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Observe throughout the day. Log the most fertile type noticed.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textLight(context),
                  ),
                ),
                const SizedBox(height: 16),

                ...List.generate(_cmOptions.length, (index) {
                  final option = _cmOptions[index];
                  final isSelected = _selectedCm == option['value'];
                  final color = option['color'] as Color;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _selectedCm = isSelected
                              ? null
                              : option['value'] as String;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withOpacity(0.15)
                              : AppTheme.cardColor(context),
                          borderRadius:
                              BorderRadius.circular(LunaraRadius.md),
                          border: Border.all(
                            color:
                                isSelected ? color : Colors.transparent,
                            width: 2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : AppTheme.softShadow(context),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: Icon(
                                option['icon'] as IconData,
                                color: color,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option['label'] as String,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? color
                                          : AppTheme.textDark(context),
                                    ),
                                  ),
                                  Text(
                                    option['description'] as String,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          AppTheme.textLight(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle_rounded,
                                  color: color, size: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // ── Save Button ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: hasData
                    ? () {
                        HapticFeedback.mediumImpact();
                        final provider = context.read<CycleProvider>();
                        if (_bbtChanged) {
                          provider.updateBbt(_bbt);
                        }
                        if (_selectedCm != null) {
                          provider.updateCervicalMucus(_selectedCm!);
                        }

                        final parts = <String>[];
                        if (_bbtChanged) {
                          parts.add('BBT: ${_bbt.toStringAsFixed(2)}°C');
                        }
                        if (_selectedCm != null) {
                          parts.add('CM: $_selectedCm');
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Logged ${parts.join(', ')}'),
                            backgroundColor:
                                LunaraColors.fertileGreen,
                          ),
                        );
                        Navigator.pop(context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LunaraColors.primary,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  hasData ? 'Save' : 'Select at least one',
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

  // ── Helpers ──────────────────────────────────────────────────────

  Color get _bbtColor {
    if (_bbt < 36.1) return const Color(0xFF64B5F6); // Low
    if (_bbt < 36.5) return const Color(0xFF81C784); // Normal pre-ov
    if (_bbt < 36.8) return const Color(0xFFFFB74D); // Thermal shift zone
    return const Color(0xFFEF5350); // Elevated
  }

  String get _bbtLabel {
    if (_bbt < 36.1) return 'Below typical range';
    if (_bbt < 36.5) return 'Pre-ovulatory range';
    if (_bbt < 36.8) return 'Possible thermal shift';
    return 'Post-ovulatory / elevated';
  }
}
