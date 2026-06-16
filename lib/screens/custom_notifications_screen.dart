import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/database_service.dart';
import '../services/app_notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_toast.dart';

class CustomNotificationsScreen extends StatefulWidget {
  const CustomNotificationsScreen({super.key});

  @override
  State<CustomNotificationsScreen> createState() => _CustomNotificationsScreenState();
}

class _CustomNotificationsScreenState extends State<CustomNotificationsScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _textController = TextEditingController();
  late Future<List<Map<String, dynamic>>> _notificationsFuture;
  bool _isAdding = false;
  bool _isDeleting = false;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _loadCustomNotifications();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _loadCustomNotifications() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      _notificationsFuture = _dbService.fetchCustomNotifications(authProvider.userId);
    });
  }

  Future<void> _addInsight() async {
    final content = _textController.text.trim();
    if (content.isEmpty) return;

    // Format content with time metadata if selected
    final String formattedContent;
    if (_selectedTime != null) {
      final hourStr = _selectedTime!.hour.toString().padLeft(2, '0');
      final minuteStr = _selectedTime!.minute.toString().padLeft(2, '0');
      formattedContent = '[time:$hourStr:$minuteStr]$content';
    } else {
      formattedContent = content;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() => _isAdding = true);
    HapticFeedback.mediumImpact();

    try {
      await _dbService.addCustomNotification(authProvider.userId, formattedContent);
      
      // Reschedule daily guidance to pick up the new fact
      await AppNotificationService().scheduleDailyGuidance();

      _textController.clear();
      setState(() {
        _selectedTime = null;
      });
      _loadCustomNotifications();

      if (mounted) {
        CustomToast.show(
          context,
          message: 'Insight added successfully!',
          icon: Icons.check_circle,
          backgroundColor: const Color(0xFF4CAF50),
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: 'Failed to add insight: $e',
          icon: Icons.error_outline,
          backgroundColor: Colors.red[400],
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _deleteInsight(int id) async {
    setState(() => _isDeleting = true);
    HapticFeedback.mediumImpact();

    try {
      await _dbService.deleteCustomNotification(id);
      
      // Reschedule daily guidance to remove the deleted fact
      await AppNotificationService().scheduleDailyGuidance();

      _loadCustomNotifications();

      if (mounted) {
        CustomToast.show(
          context,
          message: 'Insight deleted successfully!',
          icon: Icons.check_circle,
          backgroundColor: const Color(0xFF4CAF50),
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          message: 'Failed to delete: $e',
          icon: Icons.error_outline,
          backgroundColor: Colors.red[400],
        );
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppTheme.textDark(context);

    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.backgroundGradient(context),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header with Custom Premium Back Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.cardColor(context),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: AppTheme.softShadow(context),
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 18,
                            color: textColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Custom Insights',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Define your own daily health notification alerts',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textLight(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Text Input Area
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.softShadow(context),
                    border: Border.all(
                      color: AppTheme.divider(context),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline_rounded,
                            color: AppTheme.primary(context),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Type a new notification content:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _textController,
                        maxLength: 150,
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: 'e.g. Try starting seed cycling today to support your luteal phase! 🌸',
                          hintStyle: TextStyle(
                            color: AppTheme.textLight(context).withOpacity(0.5),
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: AppTheme.subtleBackground(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          counterText: '',
                        ),
                        onChanged: (val) {
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              HapticFeedback.lightImpact();
                              final TimeOfDay? picked = await showTimePicker(
                                context: context,
                                initialTime: _selectedTime ?? TimeOfDay.now(),
                                builder: (context, child) {
                                  final isDark = AppTheme.isDark(context);
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      timePickerTheme: TimePickerThemeData(
                                        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                        dialHandColor: AppTheme.primary(context),
                                        dialBackgroundColor: isDark ? const Color(0xFF2D1B28) : const Color(0xFFFCE4EC),
                                        dayPeriodTextColor: isDark ? Colors.white : const Color(0xFF3E2723),
                                        dayPeriodColor: WidgetStateColor.resolveWith((states) {
                                          if (states.contains(WidgetState.selected)) {
                                            return AppTheme.primary(context).withOpacity(0.2);
                                          }
                                          return Colors.transparent;
                                        }),
                                        hourMinuteTextColor: isDark ? Colors.white : const Color(0xFF3E2723),
                                        dialTextColor: isDark ? Colors.white : const Color(0xFF3E2723),
                                      ),
                                      colorScheme: isDark
                                          ? ColorScheme.dark(
                                              primary: AppTheme.primary(context),
                                              onPrimary: Colors.white,
                                              surface: const Color(0xFF1E1E1E),
                                              onSurface: Colors.white,
                                            )
                                          : ColorScheme.light(
                                              primary: AppTheme.primary(context),
                                              onPrimary: Colors.white,
                                              surface: Colors.white,
                                              onSurface: const Color(0xFF3E2723),
                                            ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedTime = picked;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: _selectedTime != null
                                    ? AppTheme.primary(context).withOpacity(0.12)
                                    : AppTheme.subtleBackground(context),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedTime != null
                                      ? AppTheme.primary(context)
                                      : AppTheme.divider(context),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 16,
                                    color: _selectedTime != null
                                        ? AppTheme.primary(context)
                                        : AppTheme.textLight(context),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _selectedTime != null
                                        ? 'Deliver at ${_selectedTime!.format(context)}'
                                        : 'Set Delivery Time',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _selectedTime != null
                                          ? AppTheme.primary(context)
                                          : AppTheme.textLight(context),
                                    ),
                                  ),
                                  if (_selectedTime != null) ...[
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedTime = null;
                                        });
                                      },
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 14,
                                        color: AppTheme.primary(context),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_textController.text.length} / 150',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textLight(context),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isAdding || _textController.text.trim().isEmpty ? null : _addInsight,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary(context),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              elevation: 0,
                            ),
                            icon: _isAdding
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.send_rounded, size: 16),
                            label: const Text(
                              'Save',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Notifications Pool List
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _notificationsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: LunaraColors.primary,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load insights',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _loadCustomNotifications,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: LunaraColors.primary,
                                ),
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        );
                      }

                      final items = snapshot.data ?? [];

                      if (items.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary(context).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      size: 48,
                                      color: AppTheme.primary(context),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'No custom insights yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 40),
                                    child: Text(
                                      'Add your own custom health insights or messages above. We will mix them with our default list to deliver unique notifications every day!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textLight(context),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      return RefreshIndicator(
                        color: LunaraColors.primary,
                        onRefresh: () async {
                          _loadCustomNotifications();
                        },
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final id = item['id'] as int;
                            final rawContent = item['content'] ?? '';
                            final timeMatch = RegExp(r'^\[time:(\d{2}):(\d{2})\](.*)$', dotAll: true).firstMatch(rawContent);
                            final String content;
                            final String? scheduledTime;
                            if (timeMatch != null) {
                              scheduledTime = '${timeMatch.group(1)}:${timeMatch.group(2)}';
                              content = timeMatch.group(3)!;
                            } else {
                              scheduledTime = null;
                              content = rawContent;
                            }

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.cardColor(context),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: AppTheme.softShadow(context),
                                border: Border.all(
                                  color: AppTheme.divider(context),
                                  width: 1.5,
                                ),
                              ),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary(context).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    scheduledTime != null ? Icons.alarm_rounded : Icons.favorite_rounded,
                                    size: 16,
                                    color: AppTheme.primary(context),
                                  ),
                                ),
                                title: Text(
                                  content,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: textColor,
                                    height: 1.3,
                                  ),
                                ),
                                subtitle: scheduledTime != null
                                    ? Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.access_time_rounded,
                                              size: 12,
                                              color: AppTheme.primary(context),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Delivered daily at $scheduledTime',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.primary(context),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : null,
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () => _deleteInsight(id),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_isDeleting)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: LunaraColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
