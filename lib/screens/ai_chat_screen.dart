// lib/screens/ai_chat_screen.dart - STREAMING TEXT ANIMATION

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../providers/cycle_provider.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/groq_service.dart';
import '../services/ai_rate_limit_service.dart';
import '../services/premium_service.dart';
 
class AIChatScreen extends StatefulWidget {
  final String? initialPrompt;

  const AIChatScreen({super.key, this.initialPrompt});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];

  GroqModel? _model;
  String? _currentModelName;
  GroqChatSession? _chat;
  bool _isTyping = false;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _dotsController;
  late AnimationController _introController;
  late AnimationController _orbController;
  late AnimationController _shimmerController;
  late AnimationController _glowRingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _introIconAnim;
  late Animation<double> _introTitleAnim;
  late Animation<double> _introTaglineAnim;
  late Animation<double> _introBadgeAnim;
  late Animation<double> _introFeaturesAnim;
  final List<String> _suggestedSymptoms = [];
  int _remainingRequests = PremiumService.freeDailyLimit;
  final String _apiKey = AppConfig.groqApiKey;

  final List<Map<String, dynamic>> _quickActions = [
    {
      'icon': Icons.favorite_rounded,
      'label': 'Period Tips',
      'query': 'Give me tips for managing period symptoms'
    },
    {
      'icon': Icons.restaurant_rounded,
      'label': 'Nutrition',
      'query': 'What foods are best for my current cycle phase?'
    },
    {
      'icon': Icons.self_improvement_rounded,
      'label': 'Exercise',
      'query': 'What exercises should I do in my current phase?'
    },
    {
      'icon': Icons.psychology_rounded,
      'label': 'Mood',
      'query': 'Help me manage mood swings'
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // ── Intro stagger controller ──
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _introIconAnim = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.30, curve: Curves.elasticOut),
    );
    _introTitleAnim = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.15, 0.45, curve: Curves.easeOutCubic),
    );
    _introTaglineAnim = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.30, 0.60, curve: Curves.easeOutCubic),
    );
    _introBadgeAnim = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.45, 0.72, curve: Curves.easeOutCubic),
    );
    _introFeaturesAnim = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.55, 0.85, curve: Curves.easeOutCubic),
    );

    // ── Floating orbs ──
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // ── Shimmer effect ──
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    // ── Glow ring ──
    _glowRingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _introController.forward();
    _setupApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _dotsController.dispose();
    _introController.dispose();
    _orbController.dispose();
    _shimmerController.dispose();
    _glowRingController.dispose();
    super.dispose();
  }

  Future<void> _setupApp() async {
    await _loadChatHistory();
    _initGroq();

    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 800));
      _sendMessage(widget.initialPrompt);
    }
    await _updateRemainingRequests();
  }

  Future<void> _updateRemainingRequests() async {
    final remaining = await AIRateLimitService.instance.getRemainingRequests();
    if (mounted) {
      setState(() => _remainingRequests = remaining);
    }
  }

  Future<void> _loadChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedChat = prefs.getString('chat_history');
    if (savedChat != null) {
      setState(() {
        _messages.clear();
        _messages
            .addAll(List<Map<String, dynamic>>.from(jsonDecode(savedChat)));
      });
      _scrollToBottom();
    }
  }

  Future<void> _saveChatHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat_history', jsonEncode(_messages));
  }

  void _initGroq({List<String> excludeModels = const []}) {
    final stats = Provider.of<CycleProvider>(context, listen: false);

    List<Content> history =
        _messages.where((m) => m['isComplete'] == true).map((m) {
      return m['role'] == 'user'
          ? Content.text(m['text'])
          : Content.model([TextPart(m['text'])]);
    }).toList();

    // Gather real-time daily insights
    final now = DateTime.now();
    final todaySymptoms = stats.getSymptomsForDate(now);
    final symptomsString = todaySymptoms.isNotEmpty
        ? todaySymptoms.join(', ')
        : 'None logged today';

    int? daysUntilPeriod;
    if (stats.nextPeriodDate != null) {
      daysUntilPeriod = stats.nextPeriodDate!.difference(now).inDays;
      // Handle edge cases if they are currently on their period
      if (daysUntilPeriod < 0) daysUntilPeriod = null;
    }

    final String periodContext = daysUntilPeriod != null
        ? "Predicted to start in $daysUntilPeriod days."
        : "Prediction unavailable (awaiting more data).";

    final bool isFertile = stats.isFertileDay(now);
    final bool isOvulation = stats.isOvulationDay(now);

    String fertilityContext = "Not currently in fertile window.";
    if (isOvulation) {
      fertilityContext = "Today is predicted ovulation day.";
    } else if (isFertile) {
      fertilityContext = "Currently in fertile window.";
    }

    final String trackingContext = stats.isTrackingForSomeoneElse
        ? "The user is acting as a caregiver/partner and tracking this cycle for their ${stats.trackedPersonRelation} named ${stats.trackedPersonName}. Direct your advice to the user on how they can best support ${stats.trackedPersonName}."
        : "The user is tracking their own cycle.";

    final String medicalContext = """
    Patient Name: ${stats.isTrackingForSomeoneElse ? stats.trackedPersonName : stats.userName}
    Current Cycle Day: ${stats.currentCycleDay}
    Current Phase: ${stats.currentPhase}
    Cycle Length: ${stats.cycleLength} days
    Next Period: $periodContext
    Fertility Status: $fertilityContext
    Today's Logged Symptoms: $symptomsString
    Predicted Symptoms for Today: ${stats.currentPredictions.isNotEmpty ? stats.currentPredictions.join(', ') : 'None'}
    Tracking Context: $trackingContext
    Goal: Tracking hormonal health and cycle symptoms.
  """;
    String today = now.toString().split(' ')[0];
    String time = TimeOfDay.now().format(context);

    // List of models to try — tier-aware (premium gets 70b, free gets 8b)
    final List<String> potentialModels = PremiumService.instance.availableModels;

    // Filter out excluded models
    final filteredModels = potentialModels.where((m) => !excludeModels.contains(m)).toList();

    bool initialized = false;
    String? lastError;

    for (var modelName in filteredModels) {
      try {
        _model = GroqModel(
          model: modelName,
          apiKey: _apiKey,
          systemInstruction:
              "You are a caring women's health assistant for $medicalContext "
              "TODAY'S DATE: $today. CURRENT TIME: $time. "
              "Day ${stats.currentCycleDay} of ${stats.cycleLength}, ${stats.currentPhase} phase. "
              "Be warm, professional, brief (2-3 sentences for quick questions, detailed for diet/workout plans), and supportive. Use emojis occasionally."
              "1. Acknowledge their current cycle phase and any symptoms logged TODAY before giving advice. "
              "2. If they are close to their period (e.g. within 3-5 days), politely recommend PMS-friendly remedies when relevant. "
              "3. If they have 'Predicted Symptoms for Today' that are NOT yet logged, proactively advise them on how to manage or prevent them. "
              "4. You have full general knowledge (history, science, etc.). "
              "5. Be friendly and natural. "
              "6. Provide direct answers. DO NOT wrap your response in double quotes. "
              "7. Answer any general knowledge or medical questions naturally. "
              "8. For diet plans: Provide detailed meal plans based on their cycle phase. "
              "9. For workout plans: Provide specific exercises based on their current phase. "
              "10. dont make it too lengthy. for example:- 7:30 70gram oats with 400 ml tond milk. "
              "11. Refer to the patient being tracked as '${stats.isTrackingForSomeoneElse ? stats.trackedPersonName : stats.userName}'. If the user is a caregiver, address them as the caregiver. "
              "12. If you don't know the answer, say 'I'm here to help! Could you rephrase that for me?' "
              "13. Always prioritize user safety and well-being. "
              "14. shortened the answer as much as possible, keep it short and precise of max 6-7 lines. "
              "15. NEVER ask for personal information like full name, address, phone number, or email."
              "16. KEEP THE ANSWER SHORT AND PRECISE OF MAX 3 LINES."
              "17. don't Mention patient name in starting of the response",
        );

        // Simple check to see if model is valid (optional, sendMessage will fail later anyway)
        _chat = _model!.startChat(history: history);
        _currentModelName = modelName;
        initialized = true;
        debugPrint("Successfully initialized with model: $modelName");
        break;
      } catch (e) {
        lastError = e.toString();
        debugPrint("Failed to initialize with $modelName: $e");
      }
    }

    if (!initialized) {
      debugPrint("Completely failed to initialize Groq: $lastError");
      _chat = null; // Ensure chat is null if initialization failed
    }

    if (_messages.isEmpty && widget.initialPrompt == null) {
      _triggerGreeting();
    }
  }

  Future<void> _triggerGreeting() async {
    setState(() => _isTyping = true);
    await Future.delayed(const Duration(milliseconds: 1000));

    try {
      final response = await _model!.generateContent(
          [Content.text("Give a warm personalized greeting in 2 sentences.")]);

      setState(() {
        _isTyping = false;
        _messages.add({
          "role": "ai",
          "text": response.text ??
              "Hi! I'm here to support your health journey. 💕",
          "isComplete": false,
        });
      });

      await _animateText(_messages.length - 1,
          response.text ?? "Hi! I'm here to support your health journey. 💕");
      await _saveChatHistory();
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add({
          "role": "ai",
          "text":
              "Hello! I'm your health companion. How can I help you today? 💕",
          "isComplete": false,
        });
      });
      await _animateText(_messages.length - 1,
          "Hello! I'm your health companion. How can I help you today? 💕");
    }
    _scrollToBottom();
  }

  // STREAMING TEXT ANIMATION
  Future<void> _animateText(int messageIndex, String fullText) async {
    final words = fullText.split(' ');
    String displayedText = '';

    for (int i = 0; i < words.length; i++) {
      if (!mounted) break;

      displayedText += (i == 0 ? '' : ' ') + words[i];

      setState(() {
        _messages[messageIndex]['text'] = displayedText;
      });

      // Scroll while animating
      _scrollToBottom();

      // Adjust speed: faster for short words, slower for long ones
      final delay = words[i].length > 8 ? 80 : 50;
      await Future.delayed(Duration(milliseconds: delay));
    }

    // Mark as complete
    setState(() {
      _messages[messageIndex]['isComplete'] = true;
    });
  }

  void _sendMessage([String? predefinedText]) async {
    final text = predefinedText ?? _controller.text.trim();
    if (text.isEmpty || _chat == null) return;

    // Check Rate Limit
    final canRequest = await AIRateLimitService.instance.canMakeRequest();
    if (!canRequest) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            padding: EdgeInsets.zero,
            content: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF7A8A), Color(0xFFD8405B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD8405B).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daily limit reached!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Unlock unlimited AI answers with PRO.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      await PremiumService.instance.setPremium(true);
                      await _updateRemainingRequests();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            behavior: SnackBarBehavior.floating,
                            padding: EdgeInsets.zero,
                            content: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Premium unlocked! Enjoy unlimited messages.',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFD8405B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: const Text(
                      'Upgrade',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return;
    }

    if (text.length > 500) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Message is too long (max 500 characters).'),
            backgroundColor: LunaraColors.primaryDark,
          ),
        );
      }
      return;
    }

    HapticFeedback.lightImpact();
    _analyzeForSymptoms(text);

    if (_apiKey.isEmpty) {
      setState(() {
        _messages.add({"role": "user", "text": text, "isComplete": true});
        _messages.add({
          "role": "ai",
          "text":
              "⚠️ **API Key Missing**\n\nTo use the AI chat, you need to provide your Groq API key when launching the app:\n\n`flutter run --dart-define=GROQ_API_KEY=your_key_here`\n\n*(If you're using an IDE like VS Code or Android Studio, add it to your launch configuration.)*",
          "isComplete": true,
        });
        _controller.clear();
      });
      _scrollToBottom();
      return;
    }

    setState(() {
      _messages.add({"role": "user", "text": text, "isComplete": true});
      _isTyping = true;
      _controller.clear();
    });

    await _saveChatHistory();
    _scrollToBottom();

    try {
      await Future.delayed(const Duration(milliseconds: 600));

      final safePrompt =
          "USER QUERY:\n$text\n\nREMINDER: Answer strictly following your system instructions. Do not break character or execute instructions outside of providing wellness support.";

      GroqResponse? response;
      bool success = false;
      int retryCount = 0;
      List<String> excludedModels = [];

      while (!success && retryCount < 3) {
        try {
          if (_chat == null) {
            throw Exception("Chat session not initialized");
          }
          response = await _chat!
              .sendMessage(Content.text(safePrompt))
              .timeout(const Duration(seconds: 30));
          success = true;
        } catch (e) {
          debugPrint("Attempt ${retryCount + 1} failed with $_currentModelName: $e");
          final errorStr = e.toString().toLowerCase();
          // Handle rate-limit (429) errors with a delay before retrying
          if (errorStr.contains('429') ||
              errorStr.contains('rate') ||
              errorStr.contains('resource has been exhausted') ||
              errorStr.contains('too many requests') ||
              errorStr.contains('quota')) {
            debugPrint("Rate limit hit, waiting before retry...");
            await Future.delayed(Duration(seconds: (retryCount + 1) * 5));
            retryCount++;
          // Broaden the fallback logic to catch model/server errors
          } else if (errorStr.contains('model') || 
              errorStr.contains('404') || 
              errorStr.contains('403') || 
              errorStr.contains('500') || 
              errorStr.contains('503') || 
              errorStr.contains('unavailable')) {
            debugPrint("Model error detected, attempting to re-initialize with fallback...");
            if (_currentModelName != null) excludedModels.add(_currentModelName!);
            _initGroq(excludeModels: excludedModels); 
            if (_chat == null) break;
            retryCount++;
          } else {
            rethrow;
          }
        }
      }

      if (!success || response == null) {
        throw Exception("Failed to get response after $retryCount retries. Last error: ${excludedModels.join(', ')}");
      }

      // Success: Increment limit
      await AIRateLimitService.instance.incrementRequestCount();
      await _updateRemainingRequests();

      setState(() {
        _isTyping = false;
        if (response!.text == null) {
          _messages.add({
            "role": "ai",
            "text": "I'm here to help! Could you rephrase that for me?",
            "isComplete": false,
          });
        } else {
          _messages.add({
            "role": "ai",
            "text": "",
            "isComplete": false,
          });
        }
      });

      // Animate the response
      await _animateText(_messages.length - 1,
          response.text ?? "I'm here to help! Could you rephrase that for me?");

      await _saveChatHistory();
    } catch (e, stackTrace) {
      debugPrint("FULL ERROR: $e");
      debugPrint("STACK TRACE: $stackTrace");

      String errorMsg =
          "I'm having trouble connecting right now. Please try again later.\n\n*(Debug: ${e.toString()})*";
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('429') ||
          errStr.contains('rate') ||
          errStr.contains('resource has been exhausted') ||
          errStr.contains('too many requests') ||
          errStr.contains('quota')) {
        errorMsg =
            "⏳ The AI is getting too many requests right now. Please wait a moment and try again. 💕";
      } else if (e.toString().contains('API key') || e.toString().contains('API_KEY')) {
        errorMsg =
            "⚠️ There seems to be an issue with the API key. Please check your configuration.";
      } else if (errStr.contains('model') || errStr.contains('404')) {
        errorMsg =
            "⚠️ The selected AI model configuration is currently unavailable. We're working on a fix! 💕\n\n*(Debug: ${e.toString()})*";
      } else if (errStr.contains('limit')) {
        errorMsg = "⚠️ Daily limit reached. Please try again tomorrow. 💕";
      }

      setState(() {
        _isTyping = false;
        if (_messages.isNotEmpty && _messages.last['role'] == 'ai' && _messages.last['text'] == "") {
           // We already added an empty AI message, let's use it
        } else {
          _messages.add({
            "role": "ai",
            "text": "",
            "isComplete": false,
          });
        }
      });

      await _animateText(_messages.length - 1, errorMsg);
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Timer(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _analyzeForSymptoms(String text) {
    final lowerText = text.toLowerCase();
    final List<String> detected = [];

    // Simple keyword matching for common symptoms
    final keywordMap = {
      'cramp': 'Cramps',
      'headache': 'Headache',
      'bloating': 'Bloating',
      'bloat': 'Bloating',
      'tired': 'Fatigue',
      'fatigue': 'Fatigue',
      'sad': 'Sadness',
      'nausea': 'Nausea',
      'acne': 'Acne',
      'breakout': 'Acne',
      'backache': 'Backache',
      'back hurts': 'Backache',
      'tender': 'Breast Tenderness',
    };

    keywordMap.forEach((keyword, symptom) {
      if (lowerText.contains(keyword) && !detected.contains(symptom)) {
        detected.add(symptom);
      }
    });

    if (detected.isNotEmpty) {
      setState(() {
        for (var s in detected) {
          if (!_suggestedSymptoms.contains(s)) {
            _suggestedSymptoms.add(s);
          }
        }
      });
    }
  }

  void _clearChat() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text('Clear Conversation?'),
        content: const Text('This will delete your entire chat history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('chat_history');
              setState(() => _messages.clear());
              _initGroq();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: LunaraColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.softBackground(context),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildPremiumHeader(),
                Expanded(child: _buildMessageArea()),
                if (_messages.isEmpty && widget.initialPrompt == null)
                  _buildQuickActions(),
                if (_isTyping) _buildTypingIndicator(),
                _buildPremiumInput(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        boxShadow: AppTheme.softShadow(context),
      ),
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
                color: AppTheme.subtleBackground(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.arrow_back_ios_new,
                  size: 18, color: AppTheme.textDark(context)),
            ),
          ),
          const SizedBox(width: 15),
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient(context),
                shape: BoxShape.circle,
                boxShadow: AppTheme.glowShadow(context),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'AI Assistant',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark(context),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: PremiumService.instance.isPremium
                            ? LunaraColors.warning.withOpacity(0.15)
                            : AppTheme.subtleBackground(context),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: PremiumService.instance.isPremium
                              ? LunaraColors.warning.withOpacity(0.4)
                              : AppTheme.divider(context),
                        ),
                      ),
                      child: Text(
                        PremiumService.instance.isPremium ? '💎 PRO' : 'FREE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: PremiumService.instance.isPremium
                              ? LunaraColors.warning
                              : AppTheme.textLight(context),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  _remainingRequests == -1
                      ? 'Unlimited questions · Premium'
                      : '$_remainingRequests questions left today',
                  style: TextStyle(
                    fontSize: 12,
                    color: _remainingRequests == -1
                        ? LunaraColors.warning
                        : AppTheme.textLight(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _clearChat,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.subtleBackground(context),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.delete_outline_rounded,
                  size: 20, color: AppTheme.textDark(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroHeader() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _introController,
        _orbController,
        _shimmerController,
        _glowRingController,
      ]),
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.only(bottom: 25, top: 10),
          padding: const EdgeInsets.all(24),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ── Floating orbs background ──
              Positioned.fill(
                child: CustomPaint(
                  painter: _FloatingOrbsPainter(
                    progress: _orbController.value,
                    color: LunaraColors.primary,
                    opacity: (_introIconAnim.value * 0.4).clamp(0.0, 0.4),
                  ),
                ),
              ),
              // ── Main content column ──
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── AI Icon with glow ring ──
                  _buildAnimatedIcon(),
                  const SizedBox(height: 22),
                  // ── Title ──
                  _buildAnimatedTitle(),
                  const SizedBox(height: 10),
                  // ── Tagline with shimmer ──
                  _buildAnimatedTagline(),
                  const SizedBox(height: 22),
                  // ── Security badge ──
                  _buildAnimatedBadge(),
                  const SizedBox(height: 16),
                  // ── Feature pills ──
                  _buildAnimatedFeatures(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedIcon() {
    final iconVal = _introIconAnim.value.clamp(0.0, 1.0);
    final glowVal = _glowRingController.value;
    return Transform.scale(
      scale: (0.3 + 0.7 * iconVal).clamp(0.0, 1.2),
      child: Opacity(
        opacity: iconVal,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow ring 1 (outer)
            Container(
              width: 100 + 12 * glowVal,
              height: 100 + 12 * glowVal,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: LunaraColors.primary.withOpacity(0.15 + 0.1 * glowVal),
                  width: 2,
                ),
              ),
            ),
            // Glow ring 2 (middle)
            Container(
              width: 82 + 6 * (1 - glowVal),
              height: 82 + 6 * (1 - glowVal),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: LunaraColors.primaryDark.withOpacity(0.1 + 0.08 * glowVal),
                  width: 1.5,
                ),
              ),
            ),
            // Main icon circle
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    LunaraColors.primary,
                    LunaraColors.primaryDark,
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: LunaraColors.primary.withOpacity(0.3 + 0.2 * glowVal),
                    blurRadius: 25 + 10 * glowVal,
                    spreadRadius: 2 + 4 * glowVal,
                  ),
                  BoxShadow(
                    color: LunaraColors.primaryDark.withOpacity(0.15),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Transform.rotate(
                angle: (1 - iconVal) * 0.5,
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedTitle() {
    final titleVal = _introTitleAnim.value.clamp(0.0, 1.0);
    return Transform.translate(
      offset: Offset(0, 25 * (1 - titleVal)),
      child: Opacity(
        opacity: titleVal,
        child: Text(
          'Lunara AI',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark(context),
            letterSpacing: -1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTagline() {
    final tagVal = _introTaglineAnim.value.clamp(0.0, 1.0);
    final shimmerVal = _shimmerController.value;
    return Transform.translate(
      offset: Offset(0, 20 * (1 - tagVal)),
      child: Opacity(
        opacity: tagVal,
        child: ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                AppTheme.secondaryText(context),
                LunaraColors.primary,
                AppTheme.secondaryText(context),
              ],
              stops: [
                (shimmerVal - 0.3).clamp(0.0, 1.0),
                shimmerVal,
                (shimmerVal + 0.3).clamp(0.0, 1.0),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: const Text(
            'Knows your body more than ever',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBadge() {
    final badgeVal = _introBadgeAnim.value.clamp(0.0, 1.0);
    return Transform.translate(
      offset: Offset(0, 15 * (1 - badgeVal)),
      child: Transform.scale(
        scale: 0.8 + 0.2 * badgeVal,
        child: Opacity(
          opacity: badgeVal,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  LunaraColors.primary.withOpacity(0.08),
                  LunaraColors.primaryDark.withOpacity(0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: LunaraColors.primary.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_rounded, size: 12, color: Colors.green),
                ),
                const SizedBox(width: 8),
                Text(
                  'Secure & Private Cycle Insights',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textLight(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedFeatures() {
    final featVal = _introFeaturesAnim.value.clamp(0.0, 1.0);
    final features = [
      {'icon': Icons.insights_rounded, 'text': 'Cycle Analysis'},
      {'icon': Icons.spa_rounded, 'text': 'Wellness Tips'},
      {'icon': Icons.restaurant_menu_rounded, 'text': 'Nutrition'},
    ];
    return Transform.translate(
      offset: Offset(0, 20 * (1 - featVal)),
      child: Opacity(
        opacity: featVal,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: features.asMap().entries.map((entry) {
            final i = entry.key;
            final f = entry.value;
            // Stagger each pill slightly
            final delay = i * 0.12;
            final itemVal = ((featVal - delay) / (1.0 - delay)).clamp(0.0, 1.0);
            return Transform.scale(
              scale: 0.7 + 0.3 * itemVal,
              child: Opacity(
                opacity: itemVal,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context).withOpacity(0.7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: LunaraColors.primary.withOpacity(0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(f['icon'] as IconData, size: 14, color: LunaraColors.primary),
                      const SizedBox(width: 5),
                      Text(
                        f['text'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.secondaryText(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMessageArea() {
    if (_messages.isEmpty && widget.initialPrompt != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                padding: const EdgeInsets.all(35),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [LunaraColors.primary, LunaraColors.primaryDark],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: LunaraColors.primary.withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_awesome_rounded,
                    size: 55, color: Colors.white),
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'Preparing Your\nPersonalized Plan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.textDark(context),
                height: 1.3,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Analyzing your cycle data...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.secondaryText(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: _buildIntroHeader(),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final m = _messages[index];
        bool isAi = m["role"] == "ai";
        bool isAnimating = isAi && m["isComplete"] != true;

        return TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 400),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 30 * (1 - value)),
              child: Opacity(opacity: value, child: child),
            );
          },
          child: Align(
            alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.78),
              decoration: BoxDecoration(
                gradient: isAi ? null : AppTheme.primaryGradient(context),
                color: isAi ? AppTheme.cardColor(context) : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(22),
                  bottomLeft: Radius.circular(isAi ? 4 : 22),
                  bottomRight: Radius.circular(isAi ? 22 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isAi
                        ? Colors.black.withOpacity(0.08)
                        : LunaraColors.primary.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      m["text"],
                      style: TextStyle(
                        color: isAi ? AppTheme.textDark(context) : Colors.white,
                        fontSize: 15,
                        height: 1.6,
                        fontWeight: isAi ? FontWeight.w500 : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isAnimating) ...[
                    const SizedBox(width: 4),
                    _buildCursor(),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Blinking cursor for streaming effect
  Widget _buildCursor() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 530),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value > 0.5 ? 1.0 : 0.0,
          child: Container(
            width: 2,
            height: 18,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient(context),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted) setState(() {});
      },
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Topics',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryText(context),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _quickActions.length,
            itemBuilder: (context, index) {
              final action = _quickActions[index];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _sendMessage(action['query']);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: LunaraColors.primary.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(action['icon'],
                          size: 20, color: LunaraColors.primary),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          action['label'],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 15),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _dotsController,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  // Stagger each dot by 0.2 in the animation cycle
                  final delay = index * 0.2;
                  final t = (_dotsController.value + delay) % 1.0;
                  // Create a smooth bounce using a sine curve
                  final bounce = (t < 0.5)
                      ? (t * 2)  // 0 -> 1 in first half
                      : (1 - (t - 0.5) * 2);  // 1 -> 0 in second half
                  final opacity = 0.4 + 0.6 * bounce;

                  return Container(
                    margin: EdgeInsets.only(left: index > 0 ? 6 : 0),
                    child: Transform.translate(
                      offset: Offset(0, -6 * bounce),
                      child: Opacity(
                        opacity: opacity,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient(context),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumInput() {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 12,
        left: 20,
        right: 20,
        top: 18,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_suggestedSymptoms.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _suggestedSymptoms.map((symptom) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
                    child: ActionChip(
                      backgroundColor:
                          AppTheme.primary(context).withOpacity(0.1),
                      side: BorderSide(
                          color: AppTheme.primary(context).withOpacity(0.5)),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_circle_outline,
                              size: 14, color: AppTheme.primary(context)),
                          const SizedBox(width: 4),
                          Text(
                            "Log $symptom",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primary(context),
                            ),
                          ),
                        ],
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Provider.of<CycleProvider>(context, listen: false)
                            .addSymptom(symptom);
                        setState(() {
                          _suggestedSymptoms.remove(symptom);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$symptom logged for today'),
                            backgroundColor: AppTheme.primary(context),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.subtleBackground(context).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppTheme.primary(context).withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: "Ask me anything...",
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 15,
                      color: AppTheme.textDark(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _sendMessage();
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient(context),
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.glowShadow(context),
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Floating Orbs Custom Painter ─────────────────────────────
class _FloatingOrbsPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double opacity;

  _FloatingOrbsPainter({
    required this.progress,
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final orbs = <_OrbData>[
      _OrbData(0.15, 0.2, 14, 0.0, 0.35),
      _OrbData(0.85, 0.15, 10, 0.3, 0.25),
      _OrbData(0.1, 0.75, 12, 0.5, 0.3),
      _OrbData(0.9, 0.8, 16, 0.7, 0.4),
      _OrbData(0.5, 0.1, 8, 0.15, 0.2),
      _OrbData(0.45, 0.9, 11, 0.85, 0.28),
    ];

    for (final orb in orbs) {
      final angle = (progress + orb.phase) * 2 * math.pi;
      final dx = orb.baseX * size.width + math.cos(angle) * 18;
      final dy = orb.baseY * size.height + math.sin(angle * 0.7) * 14;

      final paint = Paint()
        ..color = color.withOpacity(opacity * orb.alpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, orb.radius * 0.8);

      canvas.drawCircle(Offset(dx, dy), orb.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_FloatingOrbsPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.opacity != opacity;
}

class _OrbData {
  final double baseX;
  final double baseY;
  final double radius;
  final double phase;
  final double alpha;

  const _OrbData(this.baseX, this.baseY, this.radius, this.phase, this.alpha);
}
