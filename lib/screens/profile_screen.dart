// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/cycle_provider.dart';
import '../providers/theme_provider.dart';
import '../services/app_notification_service.dart';
import '../services/pdf_export_service.dart';
import '../theme/app_theme.dart';
import 'account_settings_screen.dart';
import 'legal_screen.dart';
import 'login_screen.dart';
import 'partner_sync_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final cycleProvider = Provider.of<CycleProvider>(context);
    final notificationService = Provider.of<AppNotificationService>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background(context),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Profile Header
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: AppTheme.softShadow(context),
                ),
                child: Column(
                  children: [
                    // Avatar with edit button
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.primaryGradient(context),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: AppTheme.primary(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Name
                    Text(
                      cycleProvider.userName.isEmpty
                          ? 'User'
                          : cycleProvider.userName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark(context),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Email or member status
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: LunaraColors.warning.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Premium Member',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: LunaraColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Health Stats Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.softShadow(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          context,
                          'Cycle Day',
                          '${cycleProvider.currentCycleDay}',
                          Icons.calendar_today,
                          AppTheme.primary(context),
                        ),
                        _buildStatItem(
                          context,
                          'Height',
                          '${cycleProvider.height} cm',
                          Icons.height,
                          AppTheme.ovulationBlue(context),
                        ),
                        _buildStatItem(
                          context,
                          'Weight',
                          '${cycleProvider.weight} kg',
                          Icons.monitor_weight_outlined,
                          AppTheme.fertileGreen(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Settings Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark(context),
                        ),
                      ),
                    ),

                    // Dark Mode Toggle
                    _buildNotificationToggle(
                      context,
                      themeProvider.isDarkMode
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      'Dark Mode',
                      'Switch to ${themeProvider.isDarkMode ? 'light' : 'dark'} theme',
                      themeProvider.isDarkMode,
                      (_) => themeProvider.toggleTheme(),
                    ),

                    // Notification Toggles
                    _buildNotificationToggle(
                      context,
                      Icons.wb_sunny_rounded,
                      'Daily Reminders',
                      'Time to log your day',
                      notificationService.dailyEnabled,
                      (val) => notificationService.toggleDailyReminders(val),
                    ),
                    _buildNotificationToggle(
                      context,
                      Icons.calendar_month_rounded,
                      'Cycle Predictions',
                      'Period starting soon alert',
                      notificationService.cycleEnabled,
                      (val) => notificationService.toggleCycleReminders(val),
                    ),

                    _buildSettingItem(
                      context,
                      Icons.ios_share_rounded,
                      'Export Health Report',
                      'Share data with your doctor',
                      () async {
                        HapticFeedback.mediumImpact();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Generating Health Report...'),
                            backgroundColor: AppTheme.textDark(context),
                            duration: Duration(seconds: 2),
                          ),
                        );

                        await PdfExportService.generateAndShareDoctorReport(
                            cycleProvider);
                      },
                    ),

                    _buildSettingItem(
                      context,
                      Icons.person_outline,
                      'Account Settings',
                      'Manage your account details',
                      () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AccountSettingsScreen(),
                          ),
                        );
                      },
                    ),

                    _buildSettingItem(
                      context,
                      Icons.people_rounded,
                      'Partner Sync',
                      cycleProvider.isPartnerLinked
                          ? 'Linked with ${cycleProvider.linkedPartnerName ?? "Partner"}'
                          : 'Share cycle data with partner',
                      () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PartnerSyncScreen(),
                          ),
                        );
                      },
                    ),

                    // ─── Connected Apps (Health) ──────────────
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cycleProvider.isHealthConnected
                              ? Colors.green.withOpacity(0.4)
                              : AppTheme.divider(context),
                        ),
                        boxShadow: AppTheme.softShadow(context),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  cycleProvider.isHealthConnected
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: Colors.green,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cycleProvider.isHealthConnected
                                          ? 'Connected to Google Fit ✓'
                                          : 'Connect Google Fit',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textDark(context),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      cycleProvider.isHealthConnected
                                          ? 'Google Fit / Apple Health synced'
                                          : 'Sync steps, sleep, heart rate & period data',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textLight(context),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: cycleProvider.isHealthConnected,
                                onChanged: (value) async {
                                  HapticFeedback.mediumImpact();
                                  if (value) {
                                    final error =
                                        await cycleProvider.connectHealth();
                                    if (error != null && context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(error),
                                          backgroundColor: Colors.orange,
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );
                                    }
                                  } else {
                                    await cycleProvider.disconnectHealth();
                                  }
                                },
                              ),
                            ],
                          ),
                          if (cycleProvider.isHealthConnected) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.subtleBackground(context),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  _buildHealthStat(
                                      context,
                                      Icons.directions_walk,
                                      '${cycleProvider.dailySteps}',
                                      'Steps'),
                                  _buildHealthStat(
                                      context,
                                      Icons.bedtime_rounded,
                                      '${cycleProvider.sleepHours}h',
                                      'Sleep'),
                                  _buildHealthStat(
                                      context,
                                      Icons.monitor_heart_outlined,
                                      cycleProvider.heartRate != null
                                          ? '${cycleProvider.heartRate}'
                                          : '--',
                                      'BPM'),
                                  _buildHealthStat(
                                      context,
                                      Icons.water_drop_outlined,
                                      cycleProvider.isOnPeriod ? 'Yes' : 'No',
                                      'Period'),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      if (cycleProvider.isSyncing)
                                        Container(
                                          width: 12,
                                          height: 12,
                                          margin:
                                              const EdgeInsets.only(right: 8),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppTheme.primary(context),
                                          ),
                                        )
                                      else
                                        Icon(
                                          cycleProvider.lastSyncStatus?.contains('No internet') == true
                                              ? Icons.cloud_off_rounded
                                              : Icons.cloud_done_rounded,
                                          size: 14,
                                          color: (cycleProvider.lastSyncStatus?.contains('No internet') == true)
                                              ? Colors.orange
                                              : Colors.green.withOpacity(0.7),
                                        ),
                                      const SizedBox(width: 6),
                                      Text(
                                        cycleProvider.isSyncing
                                            ? 'Syncing...'
                                            : (cycleProvider.lastSyncStatus ??
                                                'Background sync active'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textLight(context),
                                          fontStyle: (cycleProvider.lastSyncStatus == null) ? FontStyle.italic : FontStyle.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!cycleProvider.isSyncing)
                                    GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        cycleProvider.syncFromHealth();
                                      },
                                      child: Text(
                                        'Sync now',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.primary(context),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    _buildSettingItem(
                      context,
                      Icons.lock_outline,
                      'Privacy & Security',
                      'Privacy policy, terms & health data',
                      () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LegalScreen(),
                          ),
                        );
                      },
                    ),

                    _buildSettingItem(
                      context,
                      Icons.help_outline,
                      'Help & Support',
                      'FAQs, contact us',
                      () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HelpSupportScreen(),
                          ),
                        );
                      },
                    ),

                    _buildSettingItem(
                      context,
                      Icons.info_outline,
                      'About',
                      'Version 1.0.0',
                      () {
                        HapticFeedback.lightImpact();
                        _showAboutDialog(context);
                      },
                    ),

                    const SizedBox(height: 12),

                    // Logout Button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        _showLogoutConfirmation(context, authProvider);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.logout_rounded,
                                color: Colors.red,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.chevron_right, color: Colors.red),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value,
      IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textLight(context),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthStat(
      BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primary(context), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark(context),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.textLight(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary(context).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primary(context), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark(context),
                    ),
                  ),
                  const SizedBox(height: 2),
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
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(BuildContext context, IconData icon,
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppTheme.primary(context),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark(context),
                  ),
                ),
                const SizedBox(height: 2),
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
          Switch(
            value: value,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              onChanged(val);
            },
            activeColor: AppTheme.primary(context),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('About Lunara'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text(
                'Your personal wellness companion for period tracking and health management.'),
            SizedBox(height: 16),
            Text('© 2026 Lunara. All rights reserved.'),
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

  void _showLogoutConfirmation(
      BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out',
          style: TextStyle(
            color: AppTheme.textDark(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppTheme.textDark(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textLight(context)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              Navigator.pop(context); // Close dialog
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
