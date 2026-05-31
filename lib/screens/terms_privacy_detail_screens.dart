import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lunara Terms of Service',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Last Updated: May 30, 2026',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textLight(context),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),
              _buildParagraph(
                context,
                'Welcome to Lunara. By downloading, accessing, or using our mobile application, you agree to be bound by these Terms of Service ("Terms"). Please read them carefully before using the app.',
              ),
              _buildSectionTitle(context, '1. Informational Purposes Only'),
              _buildParagraph(
                context,
                'Lunara is a health and wellness tracking application designed to help users understand their patterns and biological cycles. Lunara is NOT a medical device, nor is it a substitute for professional medical advice, diagnosis, treatment, or contraception. Always consult with a qualified healthcare provider regarding any medical condition or family planning choices. Never disregard professional medical advice because of something you read or tracked in this application.',
              ),
              _buildSectionTitle(context, '2. User Accounts'),
              _buildParagraph(
                context,
                'To use certain features of Lunara, you must register for an account using a valid email address and password. You are solely responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account. You agree to notify us immediately of any unauthorized use of your account.',
              ),
              _buildSectionTitle(context, '3. Privacy & Data Protection'),
              _buildParagraph(
                context,
                'Your privacy is extremely important to us. Our collection, storage, and use of your personal and health-related data are governed by our Privacy Policy. By agreeing to these Terms, you also consent to our practices as outlined in the Privacy Policy.',
              ),
              _buildSectionTitle(context, '4. Allowed & Prohibited Uses'),
              _buildParagraph(
                context,
                'You agree to use Lunara only for lawful personal wellness tracking. You agree not to:\n'
                '• Reverse engineer, decompile, or copy the application\'s source code.\n'
                '• Use the community feed to upload, post, or transmit any content that is offensive, unlawful, defamatory, or harmful.\n'
                '• Attempt to disrupt or compromise the security or integrity of our servers and databases.',
              ),
              _buildSectionTitle(context, '5. Limitation of Liability'),
              _buildParagraph(
                context,
                'To the maximum extent permitted by applicable law, Lunara and its creators shall not be liable for any direct, indirect, incidental, special, or consequential damages resulting from your use of or inability to use the application, including cycle predictions, data loss, or community interactions.',
              ),
              _buildSectionTitle(context, '6. Modifications to Service'),
              _buildParagraph(
                context,
                'We reserve the right to modify, suspend, or discontinue the application or any part of its services at any time, with or without notice. We also reserve the right to update these Terms from time to time, and your continued use of Lunara constitutes acceptance of those changes.',
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textDark(context),
        ),
      ),
    );
  }

  Widget _buildParagraph(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: AppTheme.textLight(context),
        height: 1.6,
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lunara Privacy Policy',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Last Updated: May 30, 2026',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textLight(context),
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),
              _buildParagraph(
                context,
                'At Lunara, your privacy is our core foundation. We recognize the highly sensitive nature of health and menstrual cycle tracking data, and we are committed to safeguarding it. This Privacy Policy explains how we handle your data.',
              ),
              _buildSectionTitle(context, '1. Data Ownership & Rights'),
              _buildParagraph(
                context,
                'Your health and cycle data belongs 100% to you. We do not sell, rent, or lease your personal details or tracked health metrics to advertisers, pharmaceutical companies, or any other third parties. You can export, modify, or permanently delete your account and all associated data at any time.',
              ),
              _buildSectionTitle(context, '2. Information We Collect'),
              _buildParagraph(
                context,
                'To provide you with biological cycle insights, we securely store:\n'
                '• Account details: Your email address, encrypted credentials, and name.\n'
                '• Wellness metrics: Menstrual dates, symptoms, sleep duration, water intake, steps, and moods that you choose to log.\n'
                '• Opt-in Health Data: Optional sync data from Google Health Connect or Apple HealthKit if you grant permission.',
              ),
              _buildSectionTitle(context, '3. Data Security & Encryption'),
              _buildParagraph(
                context,
                'All data stored in your Lunara account is encrypted both in transit (using TLS/HTTPS protocol) and at rest on our secure PostgreSQL database managed via Supabase. We utilize strict Row Level Security (RLS) policies to ensure that your records are accessible only by you.',
              ),
              _buildSectionTitle(context, '4. Third-Party Integrations'),
              _buildParagraph(
                context,
                'If you sync steps or cycle data with external health suites (like Google Health Connect or Apple HealthKit), that data is subject to the respective platform\'s privacy framework. Lunara strictly adheres to their Developer Policy, and we will never send Health Connect/HealthKit data to external tracking platforms.',
              ),
              _buildSectionTitle(context, '5. Account & Data Deletion'),
              _buildParagraph(
                context,
                'Should you choose to leave Lunara, you can initiate a complete account deletion from the settings menu. Doing so triggers a cascade deletion across our databases, purging all cycle logs, assessments, and credentials permanently.',
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.textDark(context),
        ),
      ),
    );
  }

  Widget _buildParagraph(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: AppTheme.textLight(context),
        height: 1.6,
      ),
    );
  }
}
