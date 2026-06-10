import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/privacy_provider.dart';
import '../../../../widgets/custom_toast.dart';

/// Privacy & Ghost Mode settings screen.
///
/// Accessible from the user's profile/settings area. Allows toggling
/// Ghost Mode, biometric lock, adjusting auto-lock timeout, and
/// performing a full local data wipe.
class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final privacy = context.watch<PrivacyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // ─── Ghost Mode Header Card ─────────────────
          _buildHeaderCard(context, theme, privacy),
          const SizedBox(height: 24),

          // ─── Security Section ───────────────────────
          _buildSectionTitle(theme, 'Security'),
          const SizedBox(height: 12),
          _buildSettingsTile(
            context: context,
            theme: theme,
            icon: Icons.shield_outlined,
            title: 'Ghost Mode',
            subtitle: 'Enable full local-first privacy. All data stays on-device.',
            trailing: Switch.adaptive(
              value: privacy.ghostModeEnabled,
              activeColor: theme.colorScheme.primary,
              onChanged: (value) => privacy.toggleGhostMode(value),
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context: context,
            theme: theme,
            icon: Icons.fingerprint,
            title: 'Biometric Lock',
            subtitle: 'Require fingerprint or face to open Lunara.',
            trailing: Switch.adaptive(
              value: privacy.biometricEnabled,
              activeColor: theme.colorScheme.primary,
              onChanged: privacy.ghostModeEnabled
                  ? (value) async {
                      final success = await privacy.toggleBiometric(value);
                      if (!success && context.mounted) {
                        CustomToast.show(context, message: 'Biometrics unavailable or not enrolled on this device.', icon: Icons.check_circle, backgroundColor: const Color(0xFF4CAF50));
                      }
                    }
                  : null, // Disabled when Ghost Mode is off
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context: context,
            theme: theme,
            icon: Icons.timer_outlined,
            title: 'Auto-Lock Timeout',
            subtitle: _autoLockLabel(privacy.autoLockTimeoutMinutes),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            onTap: privacy.ghostModeEnabled && privacy.biometricEnabled
                ? () => _showAutoLockPicker(context, privacy)
                : null,
          ),

          const SizedBox(height: 32),

          // ─── Data Section ───────────────────────────
          _buildSectionTitle(theme, 'Data'),
          const SizedBox(height: 12),
          _buildSettingsTile(
            context: context,
            theme: theme,
            icon: Icons.info_outline,
            title: 'Encryption Status',
            subtitle: 'AES-256 · All data encrypted at rest',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Active',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildSettingsTile(
            context: context,
            theme: theme,
            icon: Icons.cloud_off_outlined,
            title: 'Zero Cloud Policy',
            subtitle: 'No data is transmitted to any server.',
            trailing: Icon(
              Icons.check_circle_outline,
              color: Colors.green.withOpacity(0.7),
              size: 22,
            ),
          ),

          const SizedBox(height: 32),

          // ─── Danger Zone ────────────────────────────
          _buildSectionTitle(
            theme,
            'Danger Zone',
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 12),
          _buildDestructiveButton(context, theme, privacy),
        ],
      ),
    );
  }

  // ─── Header Card ─────────────────────────────────

  Widget _buildHeaderCard(
    BuildContext context,
    ThemeData theme,
    PrivacyProvider privacy,
  ) {
    final isActive = privacy.ghostModeEnabled;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActive
              ? [
                  theme.colorScheme.primary.withOpacity(0.15),
                  theme.colorScheme.primary.withOpacity(0.05),
                ]
              : [
                  theme.colorScheme.surfaceContainerHighest,
                  theme.colorScheme.surfaceContainerHighest,
                ],
        ),
        border: Border.all(
          color: isActive
              ? theme.colorScheme.primary.withOpacity(0.3)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? theme.colorScheme.primary.withOpacity(0.2)
                  : theme.colorScheme.onSurface.withOpacity(0.08),
            ),
            child: Icon(
              isActive ? Icons.shield : Icons.shield_outlined,
              size: 28,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? 'Ghost Mode Active' : 'Ghost Mode Inactive',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isActive
                      ? 'Your data is fully encrypted and private.'
                      : 'Enable for maximum on-device privacy.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Title ───────────────────────────────

  Widget _buildSectionTitle(ThemeData theme, String title, {Color? color}) {
    return Text(
      title.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: color ?? theme.colorScheme.onSurface.withOpacity(0.5),
        letterSpacing: 1.5,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  // ─── Settings Tile ───────────────────────────────

  Widget _buildSettingsTile({
    required BuildContext context,
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: theme.colorScheme.primary.withOpacity(0.08),
                ),
                child: Icon(icon, size: 20, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }

  // ─── Auto-Lock Picker ────────────────────────────

  String _autoLockLabel(int minutes) {
    if (minutes == 0) return 'Immediately';
    if (minutes == 1) return 'After 1 minute';
    return 'After $minutes minutes';
  }

  void _showAutoLockPicker(BuildContext context, PrivacyProvider privacy) {
    final theme = Theme.of(context);
    final options = [0, 1, 5, 15, 30];

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Auto-Lock Timeout',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'How long after backgrounding before the app locks.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),
            ...options.map(
              (mins) => RadioListTile<int>(
                value: mins,
                groupValue: privacy.autoLockTimeoutMinutes,
                activeColor: theme.colorScheme.primary,
                title: Text(_autoLockLabel(mins)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onChanged: (value) {
                  if (value != null) {
                    privacy.setAutoLockTimeout(value);
                    Navigator.pop(ctx);
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── Destructive Wipe Button ─────────────────────

  Widget _buildDestructiveButton(
    BuildContext context,
    ThemeData theme,
    PrivacyProvider privacy,
  ) {
    return Material(
      color: theme.colorScheme.error.withOpacity(0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _confirmWipe(context, privacy),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: theme.colorScheme.error.withOpacity(0.15),
                ),
                child: Icon(
                  Icons.delete_forever_outlined,
                  size: 22,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wipe All Local Data',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Permanently delete all encrypted data on this device.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.warning_amber_rounded,
                color: theme.colorScheme.error.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmWipe(BuildContext context, PrivacyProvider privacy) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Wipe All Data?',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: const Text(
          'This will permanently delete ALL locally stored data including:\n\n'
          '• Cycle history\n'
          '• Daily assessments\n'
          '• Profile information\n'
          '• Encryption keys\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await privacy.wipeAllData();
              if (context.mounted) {
                CustomToast.show(context, message: 'All local data has been wiped.', icon: Icons.check_circle, backgroundColor: const Color(0xFF4CAF50));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Wipe Everything'),
          ),
        ],
      ),
    );
  }
}
