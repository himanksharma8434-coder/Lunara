// lib/screens/partner_sync_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cycle_provider.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

class PartnerSyncScreen extends StatefulWidget {
  const PartnerSyncScreen({super.key});

  @override
  State<PartnerSyncScreen> createState() => _PartnerSyncScreenState();
}

class _PartnerSyncScreenState extends State<PartnerSyncScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _codeController = TextEditingController();
  bool _isGenerating = false;
  bool _isAccepting = false;
  String? _errorMessage;

  // Partner View data
  Map<String, dynamic>? _partnerProfile;
  List<Map<String, dynamic>> _partnerCycles = [];
  StreamSubscription? _assessmentSub;
  List<Map<String, dynamic>> _partnerAssessments = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // If linked as partner, load partner data
    final cp = context.read<CycleProvider>();
    if (cp.isPartnerLinked && cp.partnerLinkRole == 'partner') {
      _loadPartnerData(cp.linkedPartnerUid!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    _assessmentSub?.cancel();
    super.dispose();
  }

  Future<void> _loadPartnerData(String trackerUid) async {
    final db = DatabaseService();
    final profile = await db.getPartnerProfile(trackerUid);
    final cycles = await db.getPartnerCycles(trackerUid);

    if (mounted) {
      setState(() {
        _partnerProfile = profile;
        _partnerCycles = cycles;
      });
    }

    // Subscribe to real-time assessments
    _assessmentSub?.cancel();
    _assessmentSub = db.streamPartnerAssessments(trackerUid).listen((data) {
      if (mounted) {
        setState(() {
          _partnerAssessments = data;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: AppTheme.textDark(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Partner Sync',
          style: TextStyle(
            color: AppTheme.textDark(context),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary(context),
          unselectedLabelColor: AppTheme.textLight(context),
          indicatorColor: AppTheme.primary(context),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: 'Share My Data'),
            Tab(text: 'View Partner'),
          ],
        ),
      ),
      body: Consumer<CycleProvider>(
        builder: (context, cp, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildShareTab(cp),
              _buildViewTab(cp),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // TAB 1: SHARE MY DATA
  // ═══════════════════════════════════════════════════════

  Widget _buildShareTab(CycleProvider cp) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header illustration
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primary(context).withOpacity(0.1),
                  AppTheme.primary(context).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.share_rounded,
                  size: 48,
                  color: AppTheme.primary(context),
                ),
                const SizedBox(height: 12),
                Text(
                  'Share Your Cycle Data',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Generate a code and share it with your partner so they can stay informed about your cycle.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textLight(context),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Status card - linked or not
          if (cp.isPartnerLinked && cp.partnerLinkRole == 'tracker') ...[
            _buildLinkedCard(cp),
          ] else ...[
            _buildGenerateCard(cp),
          ],
        ],
      ),
    );
  }

  Widget _buildLinkedCard(CycleProvider cp) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.4)),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.link_rounded, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Linked with ${cp.linkedPartnerName ?? "Partner"}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your cycle data is being shared',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
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
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showRevokeDialog(cp),
              icon: const Icon(Icons.link_off_rounded, color: Colors.red, size: 18),
              label: const Text('Disconnect Partner',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateCard(CycleProvider cp) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Column(
        children: [
          if (cp.activeInviteCode != null) ...[
            Text(
              'Your Invite Code',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textLight(context),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.primary(context).withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppTheme.primary(context).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    cp.activeInviteCode!
                        .split('')
                        .join(' '),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4,
                      color: AppTheme.primary(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: cp.activeInviteCode!));
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Code copied! 📋'),
                          backgroundColor: AppTheme.primary(context),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: Icon(Icons.copy_rounded,
                        color: AppTheme.primary(context)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Share this code with your partner.\nThey can enter it in the "View Partner" tab.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textLight(context),
                height: 1.5,
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isGenerating
                    ? null
                    : () async {
                        setState(() => _isGenerating = true);
                        HapticFeedback.mediumImpact();
                        await cp.generateInviteCode();
                        if (mounted) setState(() => _isGenerating = false);
                      },
                icon: _isGenerating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.qr_code_rounded, color: Colors.white),
                label: Text(
                  _isGenerating ? 'Generating...' : 'Generate Invite Code',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary(context),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // TAB 2: VIEW PARTNER
  // ═══════════════════════════════════════════════════════

  Widget _buildViewTab(CycleProvider cp) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (cp.isPartnerLinked && cp.partnerLinkRole == 'partner') ...[
            _buildPartnerView(cp),
          ] else ...[
            _buildEnterCodeCard(cp),
          ],
        ],
      ),
    );
  }

  Widget _buildEnterCodeCard(CycleProvider cp) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.withOpacity(0.1),
                Colors.pink.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(Icons.visibility_rounded,
                  size: 48, color: Colors.purple),
              const SizedBox(height: 12),
              Text(
                'View Partner\'s Cycle',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter the invite code shared by your partner to view their cycle data in real time.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textLight(context),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Code input card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.softShadow(context),
          ),
          child: Column(
            children: [
              TextField(
                controller: _codeController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8,
                  color: AppTheme.textDark(context),
                ),
                decoration: InputDecoration(
                  hintText: '000000',
                  hintStyle: TextStyle(
                    color: AppTheme.textLight(context).withOpacity(0.3),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 8,
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: AppTheme.subtleBackground(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
              ],

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isAccepting
                      ? null
                      : () async {
                          final code = _codeController.text.trim();
                          if (code.length != 6) {
                            setState(() =>
                                _errorMessage = 'Please enter a 6-digit code');
                            return;
                          }
                          setState(() {
                            _isAccepting = true;
                            _errorMessage = null;
                          });
                          HapticFeedback.mediumImpact();

                          final success = await cp.acceptInviteCode(code);

                          if (mounted) {
                            setState(() => _isAccepting = false);
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Partner linked successfully! 🎉'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              // Load partner data
                              if (cp.linkedPartnerUid != null) {
                                _loadPartnerData(cp.linkedPartnerUid!);
                              }
                            } else {
                              setState(() => _errorMessage =
                                  'Invalid or expired code. Try again.');
                            }
                          }
                        },
                  icon: _isAccepting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.link_rounded, color: Colors.white),
                  label: Text(
                    _isAccepting ? 'Connecting...' : 'Link Partner',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerView(CycleProvider cp) {
    final name = _partnerProfile?['name'] ?? cp.linkedPartnerName ?? 'Partner';
    final cycleLength = _partnerProfile?['cycle_length'] ?? 28;
    final periodDuration = _partnerProfile?['period_duration'] ?? 5;

    // Calculate partner's current cycle day
    int cycleDay = 0;
    String phase = 'Unknown';
    Color phaseColor = Colors.grey;

    if (_partnerCycles.isNotEmpty) {
      final latestStart =
          DateTime.parse(_partnerCycles.first['start_date'] as String);
      cycleDay = DateTime.now().difference(latestStart).inDays + 1;

      if (cycleDay <= periodDuration) {
        phase = 'Menstrual';
        phaseColor = const Color(0xFFE57373);
      } else if (cycleDay <= 13) {
        phase = 'Follicular';
        phaseColor = const Color(0xFF81C784);
      } else if (cycleDay <= 16) {
        phase = 'Ovulation';
        phaseColor = const Color(0xFFFFB74D);
      } else {
        phase = 'Luteal';
        phaseColor = const Color(0xFF64B5F6);
      }
    }

    // Get latest assessment
    Map<String, dynamic>? latestAssessment;
    if (_partnerAssessments.isNotEmpty) {
      _partnerAssessments.sort((a, b) =>
          (b['date'] as String).compareTo(a['date'] as String));
      latestAssessment = _partnerAssessments.first;
    }

    return Column(
      children: [
        // Partner header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                phaseColor.withOpacity(0.15),
                phaseColor.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: phaseColor.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: phaseColor.withOpacity(0.2),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'P',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: phaseColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "$name's Cycle",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textDark(context),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: phaseColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$phase Phase · Day $cycleDay',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: phaseColor,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Cycle overview stats
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.softShadow(context),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPartnerStat(
                  'Cycle Day', '$cycleDay', Icons.calendar_today, phaseColor),
              _buildPartnerStat('Cycle Len', '$cycleLength d',
                  Icons.loop_rounded, Colors.blue),
              _buildPartnerStat('Period', '$periodDuration d',
                  Icons.water_drop_rounded, Colors.red),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Latest mood / symptoms
        if (latestAssessment != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.softShadow(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.update_rounded,
                        size: 18, color: AppTheme.primary(context)),
                    const SizedBox(width: 8),
                    Text(
                      'Latest Check-in',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark(context),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('LIVE',
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (latestAssessment['mood'] != null)
                  _buildInfoRow(
                      'Mood', latestAssessment['mood'], Icons.mood_rounded),
                if (latestAssessment['symptoms'] != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    'Symptoms',
                    (latestAssessment['symptoms'] is List)
                        ? (latestAssessment['symptoms'] as List).join(', ')
                        : latestAssessment['symptoms'].toString(),
                    Icons.healing_rounded,
                  ),
                ],
                if (latestAssessment['sleep_hours'] != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('Sleep',
                      '${latestAssessment['sleep_hours']}h', Icons.bedtime),
                ],
                if (latestAssessment['steps'] != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('Steps', '${latestAssessment['steps']}',
                      Icons.directions_walk),
                ],
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Disconnect button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showRevokeDialog(cp),
            icon: const Icon(Icons.link_off_rounded,
                color: Colors.red, size: 18),
            label: const Text('Disconnect',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPartnerStat(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark(context),
          ),
        ),
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

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.textLight(context)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textLight(context),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark(context),
            ),
          ),
        ),
      ],
    );
  }

  void _showRevokeDialog(CycleProvider cp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Disconnect Partner?',
            style: TextStyle(
                color: AppTheme.textDark(context),
                fontWeight: FontWeight.w700)),
        content: Text(
          'This will stop sharing cycle data. You can reconnect later with a new code.',
          style: TextStyle(color: AppTheme.textLight(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: TextStyle(color: AppTheme.textLight(context))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await cp.revokePartnerLink();
              _assessmentSub?.cancel();
              if (mounted) {
                setState(() {
                  _partnerProfile = null;
                  _partnerCycles = [];
                  _partnerAssessments = [];
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Partner disconnected'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            child: const Text('Disconnect',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
