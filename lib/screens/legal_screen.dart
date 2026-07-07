import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

/// Displays legal documents (Privacy Policy & Terms of Service).
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: const Text('Legal'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                context,
                icon: Icons.shield_outlined,
                title: 'Privacy Policy',
                description: 'Your health data belongs to you. We collect only '
                    'what is necessary to provide the service and never sell '
                    'your personal information to third parties.',
                items: const [
                  'Health data is encrypted in transit and at rest.',
                  'Cycle data is stored in your Supabase account.',
                  'Analytics are anonymised and used only to improve the app.',
                  'You can delete your account and all data at any time from Account Settings.',
                ],
                linkLabel: 'Read More',
                onLinkTap: () async {
                  final url = Uri.parse('https://lunara-446e.firebaseapp.com/privacy.html');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                description: 'By using Lunara you agree to these terms. '
                    'The app provides wellness insights for informational '
                    'purposes only and is not a substitute for medical advice.',
                items: const [
                  'Lunara is not a medical device.',
                  'Predictions are estimates based on statistical models.',
                  'Always consult a healthcare professional for medical decisions.',
                  'We reserve the right to update these terms with notice.',
                ],
                linkLabel: 'Read More',
                onLinkTap: () async {
                  final url = Uri.parse('https://lunara-446e.firebaseapp.com/terms.html');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
              const SizedBox(height: 24),
              _buildSection(
                context,
                icon: Icons.favorite_border_rounded,
                title: 'Health Data Disclaimer',
                description: 'Lunara integrates with Google Health Connect and '
                    'Apple HealthKit to sync steps, sleep, heart rate, and '
                    'menstrual cycle data.',
                items: const [
                  'Health data is only accessed with your explicit permission.',
                  'You can revoke health access at any time from your phone Settings.',
                  'We do not share health data with advertisers.',
                ],
              ),
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Lunara v1.0.0 • © ${DateTime.now().year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textLight(context),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required List<String> items,
    String? linkLabel,
    VoidCallback? onLinkTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
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
                  color: AppTheme.primary(context).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primary(context), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textLight(context),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: AppTheme.fertileGreen(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textDark(context),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (linkLabel != null && onLinkTap != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onLinkTap,
              child: Row(
                children: [
                  Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: AppTheme.primary(context),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    linkLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary(context),
                      decoration: TextDecoration.underline,
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
