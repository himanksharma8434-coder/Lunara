// lib/screens/insights_screen.dart — Premium Cycle Analytics

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/cycle_provider.dart';
import '../theme/app_theme.dart';
import '../services/pdf_export_service.dart';
import '../services/premium_service.dart';
import '../services/groq_service.dart';
import '../config/app_config.dart';
import '../widgets/shimmer_loading.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Future<void> _fetchInsightsFuture;

  int _selectedRange = 7;
  bool _isGeneratingAI = false;
  String? _aiInsights;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fetchInsightsFuture = Future.delayed(const Duration(milliseconds: 800));
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CycleProvider>(context);
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: FutureBuilder<void>(
          future: _fetchInsightsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CustomScrollView(
                physics: const NeverScrollableScrollPhysics(),
                slivers: [
                  _buildHeader(context),
                  const SliverToBoxAdapter(child: InsightsShimmer()),
                ],
              );
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeader(context),
                // Time Range Selector (Premium unlocks extended)
                SliverToBoxAdapter(
                  child: _buildTimeRangeBar(provider),
                ),
                // Cycle Phase Overview
                SliverToBoxAdapter(
                  child: _buildAnimatedCard(
                    delay: 0,
                    child: _CyclePhaseCard(provider: provider),
                  ),
                ),
                // AI Predictive Trends (Premium)
                SliverToBoxAdapter(
                  child: _buildAnimatedCard(
                    delay: 50,
                    child: _buildAIPredictiveCard(provider),
                  ),
                ),
                // Wellness Trends
                SliverToBoxAdapter(
                  child: _buildAnimatedCard(
                    delay: 100,
                    child: _WellnessTrendsCard(provider: provider, days: _selectedRange),
                  ),
                ),
                // Mood Trend
                SliverToBoxAdapter(
                  child: _buildAnimatedCard(
                    delay: 200,
                    child: _MoodTrendCard(provider: provider, days: _selectedRange),
                  ),
                ),
                // Symptom Frequency
                SliverToBoxAdapter(
                  child: _buildAnimatedCard(
                    delay: 300,
                    child: _SymptomFrequencyCard(provider: provider, days: _selectedRange),
                  ),
                ),

                // Export Button
                SliverToBoxAdapter(
                  child: _buildAnimatedCard(
                    delay: 400,
                    child: _buildExportButton(context, provider),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 16,
          left: 20,
          right: 20,
          bottom: 20,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.subtleBackground(context),
              AppTheme.backgroundPink(context).withOpacity(0.4),
              AppTheme.background(context),
            ],
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppTheme.softShadow(context),
                ),
                child: Icon(Icons.arrow_back_ios_new,
                    size: 18, color: AppTheme.textDark(context)),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Insights',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textDark(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Track patterns • Understand your body',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textBrown(context).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient(context),
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppTheme.glowShadow(context),
              ),
              child: Icon(Icons.insights_rounded,
                  size: 20, color: AppTheme.cardColor(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(BuildContext context, CycleProvider provider) {
    return Container(
      margin: EdgeInsets.fromLTRB(20, 16, 20, 8),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          HapticFeedback.mediumImpact();
          // Provide visual feedback while generating
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Generating medical report...'),
              duration: Duration(seconds: 1),
            ),
          );
          await PdfExportService.generateAndShareDoctorReport(provider);
        },
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppTheme.primary(context),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: AppTheme.subtleBackground(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LunaraRadius.md),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf_rounded, size: 20),
            SizedBox(width: 10),
            Text(
              'Export Doctor Report',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCard({required int delay, required Widget child}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
    );
  }

  // ─── Time Range Bar ───────────────────────────────
  Widget _buildTimeRangeBar(CycleProvider provider) {
    final isPremium = PremiumService.instance.isPremium;
    final ranges = [
      {'days': 7, 'label': '7D'},
      {'days': 14, 'label': '14D'},
      {'days': 30, 'label': '30D', 'premium': true},
      {'days': 60, 'label': '60D', 'premium': true},
      {'days': 90, 'label': '90D', 'premium': true},
    ];

    return Container(
      margin: EdgeInsets.fromLTRB(20, 4, 20, 4),
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Row(
        children: ranges.map((r) {
          final days = r['days'] as int;
          final label = r['label'] as String;
          final needsPremium = r['premium'] == true;
          final isSelected = _selectedRange == days;
          final isLocked = needsPremium && !isPremium;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (isLocked) {
                  _showPremiumRangeToast();
                  return;
                }
                HapticFeedback.lightImpact();
                setState(() => _selectedRange = days);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? AppTheme.primaryGradient(context)
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLocked)
                      Icon(Icons.lock_rounded,
                          size: 10,
                          color: isSelected
                              ? Colors.white70
                              : AppTheme.textLight(context).withOpacity(0.5)),
                    if (isLocked) SizedBox(width: 3),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : isLocked
                                ? AppTheme.textLight(context).withOpacity(0.5)
                                : AppTheme.textDark(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showPremiumRangeToast() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 3),
        content: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF7A8A), Color(0xFFD8405B)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.workspace_premium_rounded,
                  color: AppTheme.cardColor(context), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Extended history is a Premium feature',
                  style: TextStyle(
                    color: AppTheme.cardColor(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  await PremiumService.instance.setPremium(true);
                  if (mounted) setState(() {});
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context).withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Upgrade',
                    style: TextStyle(
                      color: AppTheme.cardColor(context),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── AI Predictive Card ───────────────────────────
  Widget _buildAIPredictiveCard(CycleProvider provider) {
    final isPremium = PremiumService.instance.isPremium;

    return Container(
      margin: EdgeInsets.fromLTRB(20, 6, 20, 6),
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: isPremium
            ? LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isPremium ? null : Colors.white,
        borderRadius: BorderRadius.circular(LunaraRadius.lg),
        boxShadow: isPremium
            ? [
                BoxShadow(
                  color: Color(0xFF6C63FF).withOpacity(0.2),
                  blurRadius: 20,
                  offset: Offset(0, 6),
                ),
              ]
            : AppTheme.softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF5B52CC)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_awesome_rounded,
                    size: 18, color: AppTheme.cardColor(context)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Predictive Trends',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isPremium
                              ? Colors.white54
                              : AppTheme.textDark(context).withOpacity(0.6),
                          letterSpacing: 0.5,
                        )),
                    Text(
                      'Smart Correlations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isPremium ? Colors.white : AppTheme.textDark(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isPremium)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_rounded, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text('PRO',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          if (!isPremium) ...[
            // Locked state — show blurred preview
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.divider(context).withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  _buildLockedInsightRow(
                    Icons.bedtime_rounded,
                    'Sleep ↔ Mood correlation detected',
                    Color(0xFFB39DDB),
                  ),
                  SizedBox(height: 10),
                  _buildLockedInsightRow(
                    Icons.monitor_heart_rounded,
                    'Symptom pattern found on cycle day...',
                    AppTheme.periodRed(context),
                  ),
                  SizedBox(height: 10),
                  _buildLockedInsightRow(
                    Icons.trending_up_rounded,
                    'Activity levels affect your...',
                    AppTheme.fertileGreen(context),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await PremiumService.instance.setPremium(true);
                  if (mounted) setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.workspace_premium_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Unlock AI Insights',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Premium unlocked — show AI insights
            if (_aiInsights != null)
              ..._buildAIInsightCards()
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isGeneratingAI ? null : () => _generateAIInsights(provider),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Color(0xFF6C63FF).withOpacity(0.5),
                    padding: EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isGeneratingAI
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppTheme.cardColor(context)),
                            ),
                            SizedBox(width: 10),
                            Text('Analyzing patterns...',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.cardColor(context))),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Analyze My Patterns',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w800)),
                          ],
                        ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildLockedInsightRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark(context).withOpacity(0.7),
            ),
          ),
        ),
        Icon(Icons.blur_on_rounded,
            size: 16, color: AppTheme.textDark(context).withOpacity(0.4)),
      ],
    );
  }

  Future<void> _generateAIInsights(CycleProvider provider) async {
    setState(() => _isGeneratingAI = true);

    try {
      final history = provider.getWellnessHistory(_selectedRange);
      final symptomFreq = provider.getSymptomFrequency(_selectedRange);
      final phase = provider.currentPhase;

      final historyLines = history.map((e) {
        final d = e['date'] as DateTime;
        final dayName = DateFormat('EEEE').format(d);
        final dateStr = DateFormat('MMM d').format(d);
        final symptoms = (e['symptoms'] as List<String>).join(', ');
        return '$dayName $dateStr — Sleep: ${e['sleep']}h, Water: ${e['water']}gl, Steps: ${e['steps']}, Mood: ${e['mood']}, Symptoms: ${symptoms.isEmpty ? 'None' : symptoms}';
      }).join('\n');

      final topSymptoms = symptomFreq.entries
          .take(5)
          .map((e) => '${e.key} (${e.value}x)')
          .join(', ');

      final prompt = '''
You are an expert health data analyst. Analyze this user's wellness data and find CORRELATIONS, PATTERNS, and PREDICTIONS.

=== LAST $_selectedRange DAYS DATA ===
$historyLines

=== TOP SYMPTOMS ===
${topSymptoms.isEmpty ? 'No symptoms' : topSymptoms}

=== CURRENT PHASE ===
$phase

=== INSTRUCTIONS ===
Return EXACTLY 3-4 insights. Each insight MUST start with one of these prefixes on its own line:
[CORRELATION] — for connections between two metrics (e.g., sleep and mood)
[PATTERN] — for recurring trends (e.g., symptom spikes on certain days)
[PREDICTION] — for forecasted events based on data
[ALERT] — for concerning trends needing attention

After the prefix line, write 1-2 sentences explaining the insight. Be very specific — mention actual days, numbers, and metrics from the data.

Example format:
[CORRELATION]
Your sleep drops below 6h on Wednesdays, and your mood consistently dips to "Low" on Thursdays. This suggests poor midweek sleep directly impacts next-day mood.

Do NOT use markdown formatting. Keep each insight EXTREMELY short (1 sentence max).
''';

      final model = GroqModel(
        model: PremiumService.premiumModels.first,
        apiKey: AppConfig.groqApiKey,
        systemInstruction:
            'You are a women\'s health data analyst. Find non-obvious correlations in wellness data. Be specific and reference actual data points.',
      );

      final response = await model.generateChatCompletion(
        messages: [{'role': 'user', 'content': prompt}],
      );

      if (mounted) {
        setState(() {
          _aiInsights = response;
          _isGeneratingAI = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingAI = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate insights. Try again.')),
        );
      }
    }
  }

  List<Widget> _buildAIInsightCards() {
    if (_aiInsights == null) return [];
    final blocks = _aiInsights!.split(RegExp(r'\[(CORRELATION|PATTERN|PREDICTION|ALERT)\]'));
    final typeRegex = RegExp(r'(CORRELATION|PATTERN|PREDICTION|ALERT)');
    final types = typeRegex.allMatches(_aiInsights!).map((m) => m.group(0)!).toList();

    final widgets = <Widget>[];
    for (int i = 0; i < types.length && i < blocks.length - 1; i++) {
      final type = types[i];
      final text = blocks[i + 1].trim();
      if (text.isEmpty) continue;

      IconData icon;
      Color color;
      switch (type) {
        case 'CORRELATION':
          icon = Icons.compare_arrows_rounded;
          color = Color(0xFF6C63FF);
          break;
        case 'PATTERN':
          icon = Icons.timeline_rounded;
          color = Color(0xFFFFB74D);
          break;
        case 'PREDICTION':
          icon = Icons.auto_graph_rounded;
          color = Color(0xFF4CAF50);
          break;
        case 'ALERT':
          icon = Icons.warning_amber_rounded;
          color = Color(0xFFEF5350);
          break;
        default:
          icon = Icons.lightbulb_rounded;
          color = AppTheme.primary(context);
      }

      widgets.add(
        Container(
          margin: EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: color,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textDark(context),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Add regenerate button
    widgets.add(
      Center(
        child: TextButton.icon(
          onPressed: () {
            setState(() => _aiInsights = null);
            final provider = Provider.of<CycleProvider>(context, listen: false);
            _generateAIInsights(provider);
          },
          icon: Icon(Icons.refresh_rounded, size: 16, color: Colors.white54),
          label: Text('Regenerate',
              style: TextStyle(
                  color: Colors.white54,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
        ),
      ),
    );

    return widgets;
  }
}

// ═══════════════════════════════════════════════════════════════════
//  CYCLE PHASE CARD — Horizontal progress with phase segments
// ═══════════════════════════════════════════════════════════════════

class _CyclePhaseCard extends StatelessWidget {
  final CycleProvider provider;
  const _CyclePhaseCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final day = provider.currentCycleDay;
    final total = provider.cycleLength;
    final phase = provider.currentPhase;
    final periodEnd = provider.periodDuration;
    final ovulationStart = 13;
    final ovulationEnd = 17;

    return Container(
      margin: EdgeInsets.fromLTRB(20, 8, 20, 6),
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(LunaraRadius.lg),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _phaseColor(context, phase).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _phaseIcon(phase),
                  size: 18,
                  color: _phaseColor(context, phase),
                ),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cycle Phase',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textLight(context),
                        letterSpacing: 0.5,
                      )),
                  Text(
                    phase,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _phaseColor(context, phase),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.textDark(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Day $day',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.cardColor(context),
                        ),
                      ),
                      TextSpan(
                        text: ' / $total',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.cardColor(context).withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 22),
          // Phase progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  _segment(periodEnd / total, AppTheme.periodRed(context), day, 1,
                      periodEnd, total),
                  _segment(
                      (ovulationStart - periodEnd - 1) / total,
                      AppTheme.follicularTeal(context),
                      day,
                      periodEnd + 1,
                      ovulationStart - 1,
                      total),
                  _segment(
                      (ovulationEnd - ovulationStart + 1) / total,
                      AppTheme.ovulationBlue(context),
                      day,
                      ovulationStart,
                      ovulationEnd,
                      total),
                  _segment(
                      (total - ovulationEnd) / total,
                      AppTheme.lutealPurple(context),
                      day,
                      ovulationEnd + 1,
                      total,
                      total),
                ],
              ),
            ),
          ),
          SizedBox(height: 14),
          // Phase labels
          Row(
            children: [
              _phaseLabel(context, 'Menstrual', AppTheme.periodRed(context)),
              _phaseLabel(context, 'Follicular', AppTheme.follicularTeal(context)),
              _phaseLabel(context, 'Ovulation', AppTheme.ovulationBlue(context)),
              _phaseLabel(context, 'Luteal', AppTheme.lutealPurple(context)),
            ],
          ),
          if (provider.daysUntilNextPeriod > 0 &&
              provider.daysUntilNextPeriod <= provider.cycleLength) ...[
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.subtleBackground(context).withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 16, color: AppTheme.primary(context)),
                  SizedBox(width: 10),
                  Text(
                    'Next period in ${provider.daysUntilNextPeriod} days',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary(context),
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

  Widget _segment(
      double flex, Color color, int currentDay, int start, int end, int total) {
    final isActive = currentDay >= start && currentDay <= end;
    return Expanded(
      flex: (flex * 100).round().clamp(1, 100),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        margin: EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.25),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }

  Widget _phaseLabel(BuildContext context, String label, Color color) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textLight(context)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _phaseColor(BuildContext context, String phase) {
    switch (phase) {
      case 'Menstrual':
        return AppTheme.periodRed(context);
      case 'Follicular':
        return AppTheme.follicularTeal(context);
      case 'Ovulation':
        return AppTheme.ovulationBlue(context);
      case 'Luteal':
        return AppTheme.lutealPurple(context);
      default:
        return AppTheme.primary(context);
    }
  }

  IconData _phaseIcon(String phase) {
    switch (phase) {
      case 'Menstrual':
        return Icons.water_drop_rounded;
      case 'Follicular':
        return Icons.eco_rounded;
      case 'Ovulation':
        return Icons.spa_rounded;
      case 'Luteal':
        return Icons.nightlight_round;
      default:
        return Icons.circle;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  WELLNESS TRENDS — Grouped bar chart (water, sleep, steps)
// ═══════════════════════════════════════════════════════════════════

class _WellnessTrendsCard extends StatelessWidget {
  final CycleProvider provider;
  final int days;
  const _WellnessTrendsCard({required this.provider, this.days = 7});

  @override
  Widget build(BuildContext context) {
    final history = provider.getWellnessHistory(days);

    return Container(
      margin: EdgeInsets.fromLTRB(20, 6, 20, 6),
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(LunaraRadius.lg),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.ovulationBlue(context).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.bar_chart_rounded,
                    size: 18, color: AppTheme.ovulationBlue(context)),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Wellness Trends',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textLight(context),
                        letterSpacing: 0.5,
                      )),
                  Text(
                    'Last $days Days',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(context, 'Water', AppTheme.ovulationBlue(context)),
              SizedBox(width: 20),
              _legendDot(context, 'Sleep', AppTheme.lutealPurple(context)),
              SizedBox(width: 20),
              _legendDot(context, 'Steps', AppTheme.fertileGreen(context)),
            ],
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _calculateMaxY(history),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.textDark(context),
                    tooltipPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final labels = ['💧 Water', '😴 Sleep', '🚶 Steps'];
                      final units = [' glasses', ' hrs', ''];
                      return BarTooltipItem(
                        '${labels[rodIndex]}\n${rod.toY.toStringAsFixed(rodIndex == 2 ? 0 : 1)}${units[rodIndex]}',
                        TextStyle(
                          color: AppTheme.cardColor(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= history.length) {
                          return SizedBox.shrink();
                        }
                        final date = history[index]['date'] as DateTime;
                        return Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('E').format(date).substring(0, 2),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textLight(context),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _calculateMaxY(history) / 4,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.divider(context),
                    strokeWidth: 1,
                  ),
                ),
                barGroups: List.generate(history.length, (index) {
                  final entry = history[index];
                  final water = (entry['water'] as int).toDouble();
                  final sleep = (entry['sleep'] as double);
                  // Normalize steps to a 0–12 scale for visual balance
                  final stepsRaw = (entry['steps'] as int).toDouble();
                  final stepsNormalized = (stepsRaw / 1000).clamp(0.0, 12.0);

                  return BarChartGroupData(
                    x: index,
                    barsSpace: 3,
                    barRods: [
                      BarChartRodData(
                        toY: water,
                        width: 8,
                        color: AppTheme.ovulationBlue(context),
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: sleep,
                        width: 8,
                        color: AppTheme.lutealPurple(context),
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: stepsNormalized,
                        width: 8,
                        color: AppTheme.fertileGreen(context),
                        borderRadius: BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
              duration: const Duration(milliseconds: 600),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateMaxY(List<Map<String, dynamic>> history) {
    double max = 8; // minimum scale
    for (final e in history) {
      final water = (e['water'] as int).toDouble();
      final sleep = (e['sleep'] as double);
      final steps = ((e['steps'] as int) / 1000).clamp(0.0, 12.0);
      if (water > max) max = water;
      if (sleep > max) max = sleep;
      if (steps > max) max = steps;
    }
    return (max + 2).ceilToDouble();
  }

  Widget _legendDot(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textLight(context),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  MOOD TREND — Smooth line chart
// ═══════════════════════════════════════════════════════════════════

class _MoodTrendCard extends StatelessWidget {
  final CycleProvider provider;
  final int days;
  const _MoodTrendCard({required this.provider, this.days = 7});

  double _moodToValue(String mood) {
    switch (mood.toLowerCase()) {
      case 'great':
        return 5;
      case 'good':
        return 4;
      case 'okay':
        return 3;
      case 'low':
        return 2;
      case 'bad':
      case 'terrible':
        return 1;
      default:
        return 3;
    }
  }

  String _valueToEmoji(double value) {
    if (value >= 4.5) return '😄';
    if (value >= 3.5) return '😊';
    if (value >= 2.5) return '😐';
    if (value >= 1.5) return '😔';
    return '😢';
  }

  @override
  Widget build(BuildContext context) {
    final history = provider.getWellnessHistory(days);
    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), _moodToValue(e.value['mood'] as String));
    }).toList();

    return Container(
      margin: EdgeInsets.fromLTRB(20, 6, 20, 6),
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(LunaraRadius.lg),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.mood_rounded,
                    size: 18, color: Colors.orange),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mood Trend',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textLight(context),
                        letterSpacing: 0.5,
                      )),
                  Text(
                    'How you\'ve been feeling',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: 0.5,
                maxY: 5.5,
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.textDark(context),
                    tooltipPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final emoji = _valueToEmoji(spot.y);
                        final index = spot.x.toInt();
                        final date = history[index]['date'] as DateTime;
                        return LineTooltipItem(
                          '$emoji ${history[index]['mood']}\n${DateFormat('MMM d').format(date)}',
                          TextStyle(
                            color: AppTheme.cardColor(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= history.length) {
                          return SizedBox.shrink();
                        }
                        final date = history[index]['date'] as DateTime;
                        return Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            DateFormat('E').format(date).substring(0, 2),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textLight(context),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value < 1 || value > 5) {
                          return SizedBox.shrink();
                        }
                        return Text(
                          _valueToEmoji(value),
                          style: TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.divider(context),
                    strokeWidth: 1,
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: Colors.orange,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppTheme.cardColor(context),
                          strokeWidth: 2.5,
                          strokeColor: Colors.orange,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.orange.withOpacity(0.15),
                          Colors.orange.withOpacity(0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 600),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  SYMPTOM FREQUENCY — Horizontal bar chart
// ═══════════════════════════════════════════════════════════════════

class _SymptomFrequencyCard extends StatelessWidget {
  final CycleProvider provider;
  final int days;
  const _SymptomFrequencyCard({required this.provider, this.days = 30});

  @override
  Widget build(BuildContext context) {
    final frequency = provider.getSymptomFrequency(days);
    final topSymptoms = frequency.entries.take(6).toList();

    return Container(
      margin: EdgeInsets.fromLTRB(20, 6, 20, 6),
      padding: EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(LunaraRadius.lg),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.periodRed(context).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.healing_rounded,
                    size: 18, color: AppTheme.periodRed(context)),
              ),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Symptom Patterns',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textLight(context),
                        letterSpacing: 0.5,
                      )),
                  Text(
                    'Last $days Days',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textDark(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 20),
          if (topSymptoms.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 48,
                      color: AppTheme.fertileGreen(context).withOpacity(0.4)),
                  SizedBox(height: 12),
                  Text(
                    'No symptoms logged yet',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textLight(context).withOpacity(0.6),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Log symptoms daily to see patterns here',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textLight(context).withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            )
          else
            ...topSymptoms.asMap().entries.map((entry) {
              final index = entry.key;
              final symptom = entry.value.key;
              final count = entry.value.value;
              final maxCount = topSymptoms.first.value;
              final ratio = count / maxCount;

              // Gradient colors from warm to cool based on index
              final colors = [
                AppTheme.periodRed(context),
                AppTheme.primary(context),
                Colors.orange,
                AppTheme.ovulationBlue(context),
                AppTheme.lutealPurple(context),
                AppTheme.follicularTeal(context),
              ];
              final barColor = colors[index % colors.length];

              return Padding(
                padding: EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatSymptomName(symptom),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark(context),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: barColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$count ${count == 1 ? 'day' : 'days'}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: barColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 800 + (index * 100)),
                      tween: Tween(begin: 0.0, end: ratio),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.divider(context),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: value,
                            child: Container(
                              decoration: BoxDecoration(
                                color: barColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatSymptomName(String symptom) {
    return symptom
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }
}
