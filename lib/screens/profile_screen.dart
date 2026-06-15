// lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cycle_provider.dart';
import '../providers/theme_provider.dart';
import '../services/app_notification_service.dart';
import '../services/pdf_export_service.dart';
import '../theme/app_theme.dart';
import 'account_settings_screen.dart';
import 'custom_notifications_screen.dart';
import 'legal_screen.dart';
import 'login_screen.dart';
import 'partner_sync_screen.dart';
import 'help_support_screen.dart';
import 'plus_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../services/database_service.dart';
import '../services/plus_service.dart';
import '../widgets/custom_toast.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background(context),
      ),
      child: const SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: 20),
              _ProfileHeader(),
              _HealthOverview(),
              SizedBox(height: 20),
              _SettingsSection(),
              SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SUB-WIDGETS ───────────────────────────────────────────────────

class _ProfileHeader extends StatefulWidget {
  const _ProfileHeader();

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  final DatabaseService _dbService = DatabaseService();

  Future<void> _pickAndUploadImage(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.userId.isEmpty) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image == null) return;

      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop & Rotate',
            toolbarColor: AppTheme.primary(context),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            hideBottomControls: false,
          ),
          IOSUiSettings(
            title: 'Crop & Rotate',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile == null) return;

      setState(() => _isUploading = true);

      final file = File(croppedFile.path);
      final newUrl = await _dbService.uploadAvatar(authProvider.userId, file);

      if (newUrl != null) {
        authProvider.updateUserAvatar(newUrl);
        if (mounted) {
          CustomToast.show(
            context,
            message: 'Profile picture updated successfully!',
            icon: Icons.check_circle,
            backgroundColor: const Color(0xFF4CAF50),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        CustomToast.show(
          context,
          message: 'Upload failed: ${e.toString().replaceAll('Exception: ', '')}',
          icon: Icons.error_outline,
          backgroundColor: Colors.red[400],
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = context.select<CycleProvider, String>((p) => p.userName);
    final avatarUrl = context.select<AuthProvider, String>((p) => p.userAvatarUrl);

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(25),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Column(
        children: [
          // Avatar
          GestureDetector(
            onTap: _isUploading ? null : () => _pickAndUploadImage(context),
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTheme.primaryGradient(context),
                  ),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: _isUploading
                        ? const Center(child: CircularProgressIndicator())
                        : (avatarUrl.isNotEmpty
                            ? Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint('Image load error: $error');
                                  return Icon(
                                    Icons.error_outline,
                                    color: Colors.red[400],
                                    size: 40,
                                  );
                                },
                              )
                            : Icon(
                                Icons.person,
                                size: 50,
                                color: AppTheme.primary(context),
                              )),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary(context),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            userName.isEmpty ? 'User' : userName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark(context),
            ),
          ),
          const SizedBox(height: 6),

          // Member status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: PlusService.instance.isPlus
                  ? LunaraColors.warning.withOpacity(0.15)
                  : AppTheme.subtleBackground(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: PlusService.instance.isPlus
                    ? LunaraColors.warning.withOpacity(0.4)
                    : AppTheme.divider(context),
              ),
            ),
            child: Text(
              PlusService.instance.isPlus ? '💎 Plus Member' : 'Free Plan',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: PlusService.instance.isPlus
                    ? LunaraColors.warning
                    : AppTheme.textLight(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthOverview extends StatelessWidget {
  const _HealthOverview();

  @override
  Widget build(BuildContext context) {
    final currentCycleDay = context.select<CycleProvider, int>((p) => p.currentCycleDay);
    final height = context.select<CycleProvider, int>((p) => p.height);
    final weight = context.select<CycleProvider, int>((p) => p.weight);

    return Container(
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
                '$currentCycleDay',
                Icons.calendar_today,
                AppTheme.primary(context),
              ),
              _buildStatItem(
                context,
                'Height',
                '$height cm',
                Icons.height,
                AppTheme.ovulationBlue(context),
              ),
              _buildStatItem(
                context,
                'Weight',
                '$weight kg',
                Icons.monitor_weight_outlined,
                AppTheme.fertileGreen(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
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
          const _PlusAdvantagesItem(),
          const _DarkModeToggle(),
          const _NotificationToggles(),
          const _CustomNotificationsItem(),
          const _ExportReportItem(),
          const _AccountSettingsItem(),
          const _PartnerSyncItem(),
          const _GoogleFitConnectionCard(),
          const _LegalAndHelpItems(),
          const SizedBox(height: 12),
          const _LogoutButton(),
        ],
      ),
    );
  }
}

class _DarkModeToggle extends StatelessWidget {
  const _DarkModeToggle();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.select<ThemeProvider, bool>((p) => p.isDarkMode);

    return _buildNotificationToggle(
      context,
      isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
      'Dark Mode',
      'Switch to ${isDarkMode ? 'light' : 'dark'} theme',
      isDarkMode,
      (_) => context.read<ThemeProvider>().toggleTheme(),
    );
  }
}

class _NotificationToggles extends StatelessWidget {
  const _NotificationToggles();

  @override
  Widget build(BuildContext context) {
    final dailyEnabled = context.select<AppNotificationService, bool>((p) => p.dailyEnabled);
    final cycleEnabled = context.select<AppNotificationService, bool>((p) => p.cycleEnabled);

    return Column(
      children: [
        _buildNotificationToggle(
          context,
          Icons.wb_sunny_rounded,
          'Daily Reminders',
          'Time to log your day',
          dailyEnabled,
          (val) => context.read<AppNotificationService>().toggleDailyReminders(val),
        ),
        _buildNotificationToggle(
          context,
          Icons.calendar_month_rounded,
          'Cycle Predictions',
          'Period starting soon alert',
          cycleEnabled,
          (val) => context.read<AppNotificationService>().toggleCycleReminders(val),
        ),
      ],
    );
  }
}

class _CustomNotificationsItem extends StatelessWidget {
  const _CustomNotificationsItem();

  @override
  Widget build(BuildContext context) {
    return _buildSettingItem(
      context,
      Icons.edit_notifications_rounded,
      'Custom Insights',
      'Manage custom daily notification content',
      () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CustomNotificationsScreen(),
          ),
        );
      },
    );
  }
}

class _ExportReportItem extends StatelessWidget {
  const _ExportReportItem();

  @override
  Widget build(BuildContext context) {
    return _buildSettingItem(
      context,
      Icons.ios_share_rounded,
      'Export Health Report',
      'Share data with your doctor',
      () async {
        HapticFeedback.mediumImpact();
        CustomToast.show(context, message: 'Generating Health Report...',
        );
        final cycleProvider = context.read<CycleProvider>();
        await PdfExportService.generateAndShareDoctorReport(cycleProvider);
      },
    );
  }
}

class _AccountSettingsItem extends StatelessWidget {
  const _AccountSettingsItem();

  @override
  Widget build(BuildContext context) {
    return _buildSettingItem(
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
    );
  }
}

class _PlusAdvantagesItem extends StatelessWidget {
  const _PlusAdvantagesItem();

  @override
  Widget build(BuildContext context) {
    final isPlus = context.watch<PlusService>().isPlus;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PlusScreen(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2D1B4E), Color(0xFF44206E)],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.amber.withOpacity(isPlus ? 0.2 : 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF44206E).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lunara Plus',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPlus ? 'Manage your Plus plan' : 'Unlock all features',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (!isPlus)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.amber, Color(0xFFFFD54F)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'UPGRADE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2D1B4E),
                  ),
                ),
              ),
            if (isPlus)
              const Text(
                'ACTIVE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.amber,
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.amber),
          ],
        ),
      ),
    );
  }
}

class _PartnerSyncItem extends StatelessWidget {
  const _PartnerSyncItem();

  @override
  Widget build(BuildContext context) {
    final isPartnerLinked = context.select<CycleProvider, bool>((p) => p.isPartnerLinked);
    final linkedPartnerName = context.select<CycleProvider, String?>((p) => p.linkedPartnerName);

    return _buildSettingItem(
      context,
      Icons.people_rounded,
      'Partner Sync',
      isPartnerLinked
          ? 'Linked with ${linkedPartnerName ?? "Partner"}'
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
    );
  }
}

class _GoogleFitConnectionCard extends StatelessWidget {
  const _GoogleFitConnectionCard();

  @override
  Widget build(BuildContext context) {
    final isHealthConnected = context.select<CycleProvider, bool>((p) => p.isHealthConnected);
    final dailySteps = context.select<CycleProvider, int>((p) => p.dailySteps);
    final sleepHours = context.select<CycleProvider, double>((p) => p.sleepHours);
    final heartRate = context.select<CycleProvider, int?>((p) => p.heartRate);
    final isOnPeriod = context.select<CycleProvider, bool>((p) => p.isOnPeriod);
    final isSyncing = context.select<CycleProvider, bool>((p) => p.isSyncing);
    final lastSyncStatus = context.select<CycleProvider, String?>((p) => p.lastSyncStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHealthConnected ? Colors.green.withOpacity(0.4) : AppTheme.divider(context),
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
                  isHealthConnected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
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
                      isHealthConnected ? 'Connected to Google Fit ✓' : 'Connect Google Fit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isHealthConnected
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
                value: isHealthConnected,
                onChanged: (value) async {
                  HapticFeedback.mediumImpact();
                  final cycleProvider = context.read<CycleProvider>();
                  if (value) {
                    final error = await cycleProvider.connectHealth();
                    if (error != null && context.mounted) {
                      CustomToast.show(
                        context,
                        message: error,
                        icon: Icons.error_outline,
                        backgroundColor: Colors.red[400],
                      );
                    }
                  } else {
                    await cycleProvider.disconnectHealth();
                  }
                },
              ),
            ],
          ),
          if (isHealthConnected) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.subtleBackground(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHealthStat(
                    context,
                    Icons.directions_walk,
                    '$dailySteps',
                    'Steps',
                  ),
                  _buildHealthStat(
                    context,
                    Icons.bedtime_rounded,
                    '${sleepHours}h',
                    'Sleep',
                  ),
                  _buildHealthStat(
                    context,
                    Icons.monitor_heart_outlined,
                    heartRate != null ? '$heartRate' : '--',
                    'BPM',
                  ),
                  _buildHealthStat(
                    context,
                    Icons.water_drop_outlined,
                    isOnPeriod ? 'Yes' : 'No',
                    'Period',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (isSyncing)
                        Container(
                          width: 12,
                          height: 12,
                          margin: const EdgeInsets.only(right: 8),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primary(context),
                          ),
                        )
                      else
                        Icon(
                          lastSyncStatus?.contains('No internet') == true
                              ? Icons.cloud_off_rounded
                              : Icons.cloud_done_rounded,
                          size: 14,
                          color: (lastSyncStatus?.contains('No internet') == true)
                              ? Colors.orange
                              : Colors.green.withOpacity(0.7),
                        ),
                      const SizedBox(width: 6),
                      Text(
                        isSyncing ? 'Syncing...' : (lastSyncStatus ?? 'Background sync active'),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight(context),
                          fontStyle: (lastSyncStatus == null) ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                    ],
                  ),
                  if (!isSyncing)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.read<CycleProvider>().syncFromHealth();
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
    );
  }
}

class _LegalAndHelpItems extends StatelessWidget {
  const _LegalAndHelpItems();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
      ],
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        final authProvider = context.read<AuthProvider>();
        _showLogoutConfirmation(context, authProvider);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
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
    );
  }
}

// ─── PRIVATE GLOBAL HELPERS ────────────────────────────────────────

Widget _buildStatItem(
    BuildContext context, String label, String value, IconData icon, Color color) {
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

Widget _buildHealthStat(BuildContext context, IconData icon, String value, String label) {
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

Widget _buildNotificationToggle(
  BuildContext context,
  IconData icon,
  String title,
  String subtitle,
  bool value,
  Function(bool) onChanged,
) {
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
          Text('Your personal wellness companion for period tracking and health management.'),
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

void _showLogoutConfirmation(BuildContext context, AuthProvider authProvider) {
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
