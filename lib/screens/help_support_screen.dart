// lib/screens/help_support_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/groq_service.dart';
import '../services/plus_service.dart';
import '../config/app_config.dart';
import '../widgets/custom_toast.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _selectedCategory = 'Question';
  bool _isSubmitting = false;
  bool _feedbackSent = false;
  File? _screenshot;
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = ['Question', 'Feedback', 'Bug Report', 'Other'];

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How are my cycle predictions calculated?',
      'answer': 'Lunara uses advanced statistical and machine learning models based on your logged period start dates, cycle lengths, and historical data. The more consistently you log your cycle, the more accurate the predictions become.'
    },
    {
      'question': 'Is my health data secure and private?',
      'answer': 'Absolutely. At Lunara, your privacy is our absolute priority. All data is encrypted in transit and at rest using standard security protocols. With our row-level security architecture, only you can access your data. We never sell your personal information.'
    },
    {
      'question': 'How can I sync Google Fit / Apple Health?',
      'answer': 'Go to your Profile tab, and scroll to the "Connect Google Fit" (or Apple Health) section. Toggle the switch to grant permissions. Lunara will automatically sync your steps, sleep hours, heart rate, and active cycles.'
    },
    {
      'question': 'What should I do if my period is irregular?',
      'answer': 'Lunara is designed to support irregular periods. If you track conditions like PCOS, you can log irregular cycle lengths. The AI analysis screen provides personalized tips on nutrition and wellness tailored to hormone tracking for irregular cycles.'
    },
    {
      'question': 'Can I backup and restore my cycle history?',
      'answer': 'Yes. When you are signed in, your data is securely synced to your cloud account. If you switch devices, simply sign in with the same credentials, and your entire cycle history will restore instantly.'
    },
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickScreenshot() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final extension = image.path.split('.').last.toLowerCase();
      if (extension != 'img' && extension != 'jpeg') {
        if (mounted) {
          CustomToast.show(
            context,
            message: 'Only .img or .jpeg files are allowed.',
            icon: Icons.error_outline,
            backgroundColor: Colors.red[400],
          );
        }
        return;
      }

      final length = await image.length();
      if (length > 5 * 1024 * 1024) {
        if (mounted) {
          CustomToast.show(
            context,
            message: 'File size must be maximum 5MB.',
            icon: Icons.error_outline,
            backgroundColor: Colors.red[400],
          );
        }
        return;
      }

      setState(() {
        _screenshot = File(image.path);
      });
    } catch (e) {
      debugPrint('Error picking screenshot: $e');
    }
  }

  void _submitFeedback() async {
    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) {
      CustomToast.show(context, message: 'Please enter your question or feedback message.', icon: Icons.check_circle, backgroundColor: const Color(0xFF4CAF50));
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final uid = authProvider.userId.isNotEmpty ? authProvider.userId : null;
      final emailInput = _emailController.text.trim();
      final userEmail = emailInput.isNotEmpty 
          ? emailInput 
          : (authProvider.userEmail.isNotEmpty ? authProvider.userEmail : 'anonymous@example.com');

      String? aiReply;
      String status = 'pending_manual_review';

      // ─── AI REPLY LOGIC FOR QUESTIONS ───
      if (_selectedCategory == 'Question') {
        if (AppConfig.groqApiKey.isEmpty) {
          aiReply = "Configuration Error: Groq API key is missing. Please check your setup.";
        } else {
          bool success = false;
          final systemInstruction = "You are Lunara's automated AI Support Assistant. "
              "The user has submitted a support question. Answer it beautifully, clearly, and concisely (under 4 sentences). "
              "Use bullet points if helpful. Keep your tone supportive, clean, and highly professional. "
              "Do not state details not supported by the app.";

          final modelsToTry = [
            'qwen-2.5-32b',
            'mixtral-8x7b-32768'
          ];
          
          for (final modelName in modelsToTry) {
            try {
              final model = GroqModel(
                model: modelName,
                apiKey: AppConfig.groqApiKey,
                systemInstruction: systemInstruction,
              );

              final response = await model.generateContent([Content.text(feedback)]).timeout(const Duration(seconds: 15));
              if (response.text != null && response.text!.isNotEmpty) {
                aiReply = response.text;
                status = 'replied_by_ai';
                success = true;
                break; // Break the loop if successful
              }
            } catch (aiError) {
              debugPrint('Support AI generation failed with $modelName: $aiError');
            }
          }
          
          if (!success) {
            aiReply = "Our AI is currently experiencing high volume. Your question has been logged, and our team will review it shortly! 💕";
          }
        }
      }

      // ─── INSERT INTO SUPABASE ───
      final supabase = Supabase.instance.client;
      final isPlus = PlusService.instance.isPlus;
      final phone = supabase.auth.currentUser?.phone ?? '';

      String finalMessage = feedback;
      if (isPlus) {
        finalMessage += '\n\n[PRIORITY: HIGH]';
        if (phone.isNotEmpty) {
          finalMessage += '\n[USER_PHONE: $phone]';
        }
      }

      if (_selectedCategory == 'Bug Report' && _screenshot != null) {
        try {
          final fileExt = _screenshot!.path.split('.').last;
          final fileName = 'bug_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
          final filePath = '${uid ?? 'anon'}/$fileName';
          
          await supabase.storage.from('avatars').upload(
            filePath,
            _screenshot!,
            fileOptions: const FileOptions(cacheControl: '3600'),
          );
          final imageUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
          finalMessage += '\n\n[SCREENSHOT: $imageUrl]';
        } catch (e) {
          debugPrint('Failed to upload screenshot: $e');
        }
      }

      await supabase.from('support_tickets').insert({
        'user_id': uid,
        'email': userEmail,
        'category': _selectedCategory,
        'message': finalMessage,
        'ai_reply': aiReply,
        'status': status,
      });

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _feedbackSent = true;
        });
        HapticFeedback.lightImpact();
        _feedbackController.clear();
        _emailController.clear();
        _screenshot = null;
      }
    } catch (e) {
      debugPrint('Error submitting ticket: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        CustomToast.show(context, message: 'Failed to submit ticket: $e. Did you run the SQL migration on Supabase?', icon: Icons.error_outline, backgroundColor: Colors.red[400]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [LunaraColors.primary, LunaraColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: LunaraColors.primary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.support_agent_rounded, color: Colors.white, size: 36),
                    const SizedBox(height: 16),
                    const Text(
                      'How can we help you?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Browse our frequently asked questions or drop us a message below.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.85),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // FAQ Section Title
              Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark(context),
                ),
              ),
              const SizedBox(height: 12),

              // FAQ List
              ..._faqs.map((faq) => _buildFaqItem(faq['question']!, faq['answer']!)),

              const SizedBox(height: 35),

              // Feedback Form Title
              Text(
                'Still need help? Contact Us',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark(context),
                ),
              ),
              const SizedBox(height: 12),

              // Feedback form card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.softShadow(context),
                ),
                child: _feedbackSent ? _buildSuccessState() : _buildContactForm(),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(
              question,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTheme.textDark(context),
              ),
            ),
            iconColor: LunaraColors.primary,
            collapsedIconColor: AppTheme.textLight(context),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              Text(
                answer,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textLight(context),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category dropdown label
        Text(
          'Select Category',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textLight(context),
          ),
        ),
        const SizedBox(height: 8),

        // Category buttons Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: LunaraColors.primary,
                  disabledColor: Colors.transparent,
                  backgroundColor: AppTheme.background(context),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textDark(context),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) {
                      setState(() => _selectedCategory = cat);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Email textfield label
        Text(
          'Your Email (optional)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textLight(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppTheme.background(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.divider(context)),
          ),
          child: TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Enter your email address',
              border: InputBorder.none,
            ),
            style: TextStyle(color: AppTheme.textDark(context)),
          ),
        ),
        const SizedBox(height: 20),

        if (_selectedCategory == 'Bug Report') ...[
          Text(
            'Attach Screenshot (optional)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight(context),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickScreenshot,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.background(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.divider(context)),
              ),
              child: Row(
                children: [
                  Icon(
                    _screenshot != null ? Icons.image : Icons.add_photo_alternate_outlined,
                    color: _screenshot != null ? LunaraColors.primary : AppTheme.textLight(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _screenshot != null ? _screenshot!.path.split('/').last : 'Upload .img or .jpeg (max 5MB)',
                      style: TextStyle(
                        color: _screenshot != null ? AppTheme.textDark(context) : AppTheme.textLight(context),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_screenshot != null)
                    GestureDetector(
                      onTap: () => setState(() => _screenshot = null),
                      child: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Message textfield label
        Text(
          'How can we help?',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textLight(context),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.background(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.divider(context)),
          ),
          child: TextField(
            controller: _feedbackController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Type your message or question here...',
              border: InputBorder.none,
            ),
            style: TextStyle(color: AppTheme.textDark(context)),
          ),
        ),
        const SizedBox(height: 24),

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitFeedback,
            style: ElevatedButton.styleFrom(
              backgroundColor: LunaraColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Send Message',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.send_rounded, size: 16),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_outline_rounded,
            color: Colors.green,
            size: 48,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Message Sent!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Thank you for reaching out. Our support team will get back to you if required.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textLight(context),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () {
            setState(() {
              _feedbackSent = false;
            });
          },
          child: const Text(
            'Send Another Message',
            style: TextStyle(
              color: LunaraColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
