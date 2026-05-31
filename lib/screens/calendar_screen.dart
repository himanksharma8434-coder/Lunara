// lib/screens/calendar_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cycle_provider.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with TickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

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
    final cycleProvider = Provider.of<CycleProvider>(context);
    final textColor = Theme.of(context).colorScheme.onSurface;
    final cardColor = Theme.of(context).colorScheme.surfaceContainerHighest;

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.5),
          radius: 1.5,
          colors: [
            LunaraColors.primary.withOpacity(0.06),
            LunaraColors.background,
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
                // Premium Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cycleProvider.cycleOwnerName} Calendar',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            DateFormat('MMMM yyyy').format(_focusedMonth),
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _showCycleStatsDialog(cycleProvider);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.insights_rounded,
                                size: 22,
                                color: LunaraColors.textDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() {
                                _focusedMonth = DateTime.now();
                                _selectedDate = DateTime.now();
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.today_rounded,
                                size: 22,
                                color: LunaraColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Month Navigation
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildNavButton(
                        Icons.chevron_left_rounded,
                        () {
                          setState(() {
                            _focusedMonth = DateTime(
                              _focusedMonth.year,
                              _focusedMonth.month - 1,
                            );
                          });
                        },
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_focusedMonth),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      _buildNavButton(
                        Icons.chevron_right_rounded,
                        () {
                          setState(() {
                            _focusedMonth = DateTime(
                              _focusedMonth.year,
                              _focusedMonth.month + 1,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                // Calendar Legend
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLegendItem('Period', const Color(0xFFE57373)),
                      _buildLegendItem('Fertile', const Color(0xFFFFD54F)),
                      _buildLegendItem('Ovulation', const Color(0xFFBA68C8)),
                      _buildLegendItem('Luteal', const Color(0xFF90CAF9)),
                      _buildLegendItem('Today', const Color(0xFF118AB2)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Calendar Grid
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Weekday Headers
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                              .map((day) => SizedBox(
                                    width: 40,
                                    child: Center(
                                      child: Text(
                                        day,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 15),

                        // Calendar Days
                        Expanded(
                          child: _buildCalendarGrid(cycleProvider),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Selected Date Info Card
                _buildSelectedDateCard(cycleProvider),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(CycleProvider provider) {
    final firstDayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday % 7;

    List<Widget> dayWidgets = [];

    // Add empty spaces for days before month starts
    for (int i = 0; i < firstWeekday; i++) {
      dayWidgets.add(const SizedBox(width: 40, height: 40));
    }

    // Add actual days
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      dayWidgets.add(_buildDayCell(date, provider));
    }

    return GridView.count(
      crossAxisCount: 7,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      physics: const NeverScrollableScrollPhysics(),
      children: dayWidgets,
    );
  }

  Widget _buildDayCell(DateTime date, CycleProvider provider) {
    final defaultTextColor = Theme.of(context).colorScheme.onSurface;
    final isToday = _isSameDay(date, DateTime.now());
    final isSelected = _isSameDay(date, _selectedDate);
    final isPeriod = provider.isPeriodDay(date);
    final isFertile = provider.isFertileDay(date);
    final isOvulation = provider.isOvulationDay(date);
    final isPastDate = date.isBefore(DateTime.now()) && !isToday;
    final hasSymptoms = provider.getSymptomsForDate(date).isNotEmpty;
    final isPredicted = provider.isPredictedDay(date);
    final phaseType = provider.getPhaseTypeForDate(date);

    Color backgroundColor = Colors.transparent;
    Color textColor = defaultTextColor;
    bool hasBorder = false;

    // Subtle phase background for all days
    if (phaseType == 'luteal' && !isSelected && !isToday) {
      backgroundColor = const Color(0xFF90CAF9).withOpacity(0.08);
    }

    if (isSelected) {
      backgroundColor = const Color(0xFF118AB2);
      textColor = Colors.white;
    } else if (isToday) {
      hasBorder = true;
      backgroundColor = const Color(0xFF118AB2).withOpacity(0.15);
      textColor = const Color(0xFF118AB2);
    } else if (isOvulation) {
      backgroundColor =
          const Color(0xFFBA68C8).withOpacity(isPredicted ? 0.12 : 0.2);
      textColor = const Color(0xFFBA68C8);
    } else if (isPeriod) {
      backgroundColor =
          const Color(0xFFE57373).withOpacity(isPredicted ? 0.12 : 0.2);
      textColor = const Color(0xFFE57373);
    } else if (isFertile) {
      backgroundColor =
          const Color(0xFFFFD54F).withOpacity(isPredicted ? 0.12 : 0.2);
      textColor = const Color(0xFFD4A000);
    }

    if (isPastDate && !isSelected) {
      textColor = textColor.withOpacity(0.4);
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _selectedDate = date;
        });
      },
      onLongPress: () {
        HapticFeedback.mediumImpact();
        _showDayDetailsDialog(date, provider);
      },
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 200),
        tween: Tween(begin: 1.0, end: isSelected ? 1.0 : 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                shape: BoxShape.circle,
                border: hasBorder
                    ? Border.all(color: const Color(0xFF118AB2), width: 2)
                    : isPredicted &&
                            (isPeriod || isFertile || isOvulation) &&
                            !isSelected
                        ? Border.all(
                            color: isPeriod
                                ? const Color(0xFFE57373).withOpacity(0.4)
                                : isOvulation
                                    ? const Color(0xFFBA68C8).withOpacity(0.4)
                                    : const Color(0xFFFFD54F).withOpacity(0.4),
                            width: 1.5,
                          )
                        : null,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF118AB2).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected || isToday
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        if ((isPeriod || isFertile || isOvulation) &&
                            !isSelected)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isOvulation
                                  ? const Color(0xFFBA68C8)
                                  : isPeriod
                                      ? const Color(0xFFE57373)
                                      : const Color(0xFFFFD54F),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (hasSymptoms && !isSelected)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: LunaraColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedDateCard(CycleProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final isPeriod = provider.isPeriodDay(_selectedDate);
    final isFertile = provider.isFertileDay(_selectedDate);
    final isOvulation = provider.isOvulationDay(_selectedDate);
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final symptoms = provider.getSymptomsForDate(_selectedDate);
    final phase = provider.getPhaseForDate(_selectedDate);

    String statusText = 'Regular Day';
    Color statusColor = Colors.grey[600]!;
    IconData statusIcon = Icons.calendar_today_rounded;

    if (isOvulation) {
      statusText = 'Ovulation Day';
      statusColor = const Color(0xFFBA68C8);
      statusIcon = Icons.favorite_rounded;
    } else if (isPeriod) {
      statusText = 'Period Day';
      statusColor = const Color(0xFFE57373);
      statusIcon = Icons.water_drop_rounded;
    } else if (isFertile) {
      statusText = 'Fertile Window';
      statusColor = const Color(0xFFFFD54F);
      statusIcon = Icons.spa_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(isDark ? 0.08 : 0.15),
            statusColor.withOpacity(isDark ? 0.03 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM d').format(_selectedDate),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            phase,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        if (isToday) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF118AB2).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Today',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF118AB2),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Symptoms Display
          if (symptoms.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.medical_services_rounded,
                          size: 16,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        'Symptoms',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: symptoms
                        .map((symptom) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: LunaraColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: LunaraColors.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                symptom,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: LunaraColors.primaryDark,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Quick Actions
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Log Symptom',
                  Icons.add_circle_outline_rounded,
                  LunaraColors.primary,
                  () {
                    HapticFeedback.mediumImpact();
                    _showSymptomDialog(_selectedDate, provider);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionButton(
                  'Add Note',
                  Icons.edit_note_rounded,
                  const Color(0xFF06D6A0),
                  () {
                    HapticFeedback.mediumImpact();
                    _showNoteDialog(_selectedDate, provider);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: LunaraColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: LunaraColors.primary,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Dialog Functions
  void _showSymptomDialog(DateTime date, CycleProvider provider) {
    final symptoms = [
      'Cramps',
      'Headache',
      'Fatigue',
      'Bloating',
      'Mood Swings',
      'Nausea',
      'Back Pain',
      'Breast Tenderness'
    ];
    final selectedSymptoms =
        Set<String>.from(provider.getSymptomsForDate(date));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Log Symptoms'),
          content: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: symptoms.map((symptom) {
                final isSelected = selectedSymptoms.contains(symptom);
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setDialogState(() {
                      if (isSelected) {
                        selectedSymptoms.remove(symptom);
                      } else {
                        selectedSymptoms.add(symptom);
                      }
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? LunaraColors.primary.withOpacity(0.2)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isSelected
                            ? LunaraColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      symptom,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? LunaraColors.primaryDark
                            : Colors.grey[700],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // Save symptoms logic here
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${selectedSymptoms.length} symptoms logged'),
                    backgroundColor: const Color(0xFF06D6A0),
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: LunaraColors.primary),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNoteDialog(DateTime date, CycleProvider provider) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Note for ${DateFormat('MMM d').format(date)}'),
        content: TextField(
          controller: noteController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Write your note here...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (noteController.text.trim().isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Note saved successfully'),
                    backgroundColor: Color(0xFF06D6A0),
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06D6A0)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDayDetailsDialog(DateTime date, CycleProvider provider) {
    final symptoms = provider.getSymptomsForDate(date);
    final phase = provider.getPhaseForDate(date);
    final isPeriod = provider.isPeriodDay(date);
    final isFertile = provider.isFertileDay(date);
    final isOvulation = provider.isOvulationDay(date);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(DateFormat('MMMM d, yyyy').format(date)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Phase', phase, const Color(0xFF118AB2)),
            if (isPeriod)
              _buildDetailRow('Status', 'Period Day', const Color(0xFFE57373)),
            if (isOvulation)
              _buildDetailRow('Status', 'Ovulation', const Color(0xFFBA68C8)),
            if (isFertile && !isOvulation)
              _buildDetailRow(
                  'Status', 'Fertile Window', const Color(0xFFFFD54F)),
            if (symptoms.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Symptoms:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              ...symptoms.map((s) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.circle,
                            size: 6, color: LunaraColors.primary),
                        const SizedBox(width: 8),
                        Text(s),
                      ],
                    ),
                  )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCycleStatsDialog(CycleProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cycle Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Current Cycle Day', '${provider.currentCycleDay}'),
            _buildStatRow('Current Phase', provider.currentPhase),
            _buildStatRow(
                'Days Until Period', '${provider.daysUntilNextPeriod}'),
            _buildStatRow('Cycle Length', '${provider.cycleLength} days'),
            _buildStatRow(
                'Total Cycles Tracked', '${provider.totalCyclesTracked}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: LunaraColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
