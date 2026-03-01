// lib/screens/ai_chat_screen.dart - STREAMING TEXT ANIMATION

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import '../providers/cycle_provider.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

  GenerativeModel? _model;
  ChatSession? _chat;
  bool _isTyping = false;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  final String _apiKey = AppConfig.geminiApiKey;

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

    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _setupApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _setupApp() async {
    await _loadChatHistory();
    _initGemini();

    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 800));
      _sendMessage(widget.initialPrompt);
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

  void _initGemini() {
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
    Tracking Context: $trackingContext
    Goal: Tracking hormonal health and cycle symptoms.
  """;
    String today = now.toString().split(' ')[0];
    String time = TimeOfDay.now().format(context);

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
      ],
      systemInstruction: Content.system(
          "You are a caring women's health assistant for $medicalContext "
          "TODAY'S DATE: $today. CURRENT TIME: $time. "
          "Day ${stats.currentCycleDay} of ${stats.cycleLength}, ${stats.currentPhase} phase. "
          "Be warm, professional, brief (2-3 sentences for quick questions, detailed for diet/workout plans), and supportive. Use emojis occasionally."
          "1. Acknowledge their current cycle phase and any symptoms logged TODAY before giving advice. "
          "2. If they are close to their period (e.g. within 3-5 days), politely recommend PMS-friendly remedies when relevant. "
          "3. You have full general knowledge (history, science, etc.). "
          "4. Be friendly and natural. "
          "5. Provide direct answers. DO NOT wrap your response in double quotes. "
          "6. Answer any general knowledge or medical questions naturally. "
          "7. For diet plans: Provide detailed meal plans based on their cycle phase. "
          "8. For workout plans: Provide specific exercises based on their current phase. "
          "9. dont make it too lengthy. for example:- 7:30 70gram oats with 400 ml tond milk. "
          "10. Refer to the patient being tracked as '${stats.isTrackingForSomeoneElse ? stats.trackedPersonName : stats.userName}'. If the user is a caregiver, address them as the caregiver. "
          "11. If you don't know the answer, say 'I'm here to help! Could you rephrase that for me?' "
          "12. Always prioritize user safety and well-being. "
          "13. shortened the answer as much as possible, keep it short and precise of max 6-7 lines. "
          "14. NEVER ask for personal information like full name, address, phone number, or email."),
    );

    _chat = _model!.startChat(history: history);

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

    HapticFeedback.lightImpact();

    if (_apiKey.isEmpty) {
      setState(() {
        _messages.add({"role": "user", "text": text, "isComplete": true});
        _messages.add({
          "role": "ai",
          "text":
              "⚠️ **API Key Missing**\n\nTo use the AI chat, you need to provide your Gemini API key when launching the app:\n\n`flutter run --dart-define=GEMINI_API_KEY=your_key_here`\n\n*(If you're using an IDE like VS Code or Android Studio, add it to your launch configuration.)*",
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
      final response = await _chat!
          .sendMessage(Content.text(text))
          .timeout(const Duration(seconds: 30));

      setState(() {
        _isTyping = false;
        if (response.text == null) {
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
    } catch (e) {
      debugPrint("FULL ERROR: $e");
      setState(() {
        _isTyping = false;
        _messages.add({
          "role": "ai",
          "text": "",
          "isComplete": false,
        });
      });

      await _animateText(_messages.length - 1,
          "CONNECTION ERROR: ${e.toString().split(':').last}");
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
              _initGemini();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8989),
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFCE4EC).withOpacity(0.4),
              const Color(0xFFF8BBD0).withOpacity(0.3),
              AppTheme.background(context),
            ],
          ),
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
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
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
                color: const Color(0xFFFCE4EC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  size: 18, color: Color(0xFF3E2723)),
            ),
          ),
          const SizedBox(width: 15),
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8989), Color(0xFFD8405B)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8989).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF3E2723),
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Personalized wellness guide',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6D4C41),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _clearChat,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFCE4EC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  size: 20, color: Color(0xFF3E2723)),
            ),
          ),
        ],
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
                    colors: [Color(0xFFFF8989), Color(0xFFD8405B)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8989).withOpacity(0.4),
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
            const Text(
              'Preparing Your\nPersonalized Plan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3E2723),
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
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
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
                    colors: [Color(0xFFFF8989), Color(0xFFD8405B)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8989).withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: const Icon(Icons.chat_bubble_rounded,
                    size: 55, color: Colors.white),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Your Personal Health\nCompanion',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF3E2723),
                height: 1.3,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Ask me anything about periods, symptoms,\nnutrition, or wellness tips',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
                gradient: isAi
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFFFF8989), Color(0xFFD8405B)],
                      ),
                color: isAi ? Colors.white : null,
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
                        : const Color(0xFFFF8989).withOpacity(0.4),
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
                        color: isAi ? const Color(0xFF3E2723) : Colors.white,
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
              gradient: const LinearGradient(
                colors: [Color(0xFFFF8989), Color(0xFFD8405B)],
              ),
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
              color: Colors.grey[700],
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFFF8989).withOpacity(0.3),
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
                          size: 20, color: const Color(0xFFFF8989)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          action['label'],
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3E2723),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) => _buildBouncingDot(index)),
          ),
        ),
      ),
    );
  }

  Widget _buildBouncingDot(int index) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        final delay = index * 0.15;
        final animValue = ((value + delay) % 1.0);
        final bounce = (1 - (animValue * 2 - 1).abs());

        return Container(
          margin: EdgeInsets.only(left: index > 0 ? 6 : 0),
          child: Transform.translate(
            offset: Offset(0, -6 * bounce),
            child: Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF8989), Color(0xFFD8405B)],
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted && _isTyping) setState(() {});
      },
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
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFCE4EC).withOpacity(0.8),
                    const Color(0xFFF8BBD0).withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFFFF8989).withOpacity(0.2),
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF3E2723),
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
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8989), Color(0xFFD8405B)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF8989).withOpacity(0.5),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
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
    );
  }
}
