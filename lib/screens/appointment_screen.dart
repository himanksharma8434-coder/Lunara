// lib/screens/appointment_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/nearby_doctor.dart';
import '../services/nearby_doctor_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_toast.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen>
    with TickerProviderStateMixin {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _locationDenied = false;
  List<NearbyDoctor> _doctors = [];
  late AnimationController _pulseController;

  final List<Map<String, dynamic>> _filters = [
    {'label': 'All', 'icon': Icons.apps_rounded},
    {'label': 'Hospital', 'icon': Icons.local_hospital_rounded},
    {'label': 'Clinic', 'icon': Icons.medical_services_rounded},
    {'label': 'Doctor', 'icon': Icons.person_rounded},
    {'label': 'Pharmacy', 'icon': Icons.local_pharmacy_rounded},
    {'label': 'Dentist', 'icon': Icons.mood_rounded},
    {'label': 'Lab', 'icon': Icons.biotech_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadDoctors();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _isLoading = true;
      _locationDenied = false;
    });

    try {
      final doctors = await NearbyDoctorService.fetchNearbyDoctors();

      if (!mounted) return;

      // Check location permission and status AFTER potential user permission prompts
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();
      final isPermissionDenied = permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever;

      final isFallback = doctors.isNotEmpty && doctors.first.latitude == 0;

      setState(() {
        _doctors = doctors;
        _isLoading = false;
        // Only block the screen if permissions are denied or service is disabled
        _locationDenied = !serviceEnabled || isPermissionDenied;
      });

      if (!mounted) return;

      // If we couldn't get a real position but services are enabled/allowed (e.g. GPS timeout / API fail),
      // show fallback list and warn the user.
      if (isFallback && serviceEnabled && !isPermissionDenied) {
        CustomToast.show(
          context,
          message: 'GPS signal weak or API offline. Showing default healthcare facilities.',
          icon: Icons.location_off_rounded,
          backgroundColor: Colors.orange[400],
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _locationDenied = true;
        });
      }
    }
  }

  List<NearbyDoctor> get _filteredDoctors {
    var docs = _doctors;

    // Apply category filter
    if (_selectedFilter != 'All') {
      docs = docs.where((d) {
        switch (_selectedFilter) {
          case 'Hospital':
            return d.facilityType == 'hospital';
          case 'Clinic':
            return d.facilityType == 'clinic';
          case 'Doctor':
            return d.facilityType == 'doctors';
          case 'Pharmacy':
            return d.facilityType == 'pharmacy';
          case 'Dentist':
            return d.facilityType == 'dentist';
          case 'Lab':
            return d.facilityType == 'laboratory';
          default:
            return true;
        }
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      docs = docs
          .where((d) =>
              d.name.toLowerCase().contains(q) ||
              d.specialty.toLowerCase().contains(q) ||
              d.address.toLowerCase().contains(q))
          .toList();
    }

    return docs;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.isDark(context)
              ? [AppTheme.background(context), AppTheme.background(context)]
              : [LunaraColors.primaryLight, LunaraColors.backgroundPink, const Color(0xFFF3E5F5)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nearby Doctors',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _locationDenied
                                        ? Colors.orange
                                        : LunaraColors.fertileGreen,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_locationDenied
                                                ? Colors.orange
                                                : LunaraColors.fertileGreen)
                                            .withOpacity(
                                                0.3 + _pulseController.value * 0.4),
                                        blurRadius: 6,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _locationDenied
                                      ? 'Location access needed'
                                      : _isLoading
                                          ? 'Finding nearby...'
                                          : '${_doctors.length} found near you',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.secondaryText(context),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Refresh button
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor(context),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _loadDoctors();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: _isLoading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: LunaraColors.primary,
                                  ),
                                )
                              : const Icon(
                                  Icons.refresh_rounded,
                                  size: 22,
                                  color: LunaraColors.primary,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search doctors, clinics, specialties...',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    icon: Icon(Icons.search_rounded, color: Colors.grey[400]),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded,
                                color: Colors.grey[400], size: 20),
                            onPressed: () {
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Category Filter Chips
            SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  final isSelected = _selectedFilter == filter['label'];

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedFilter = filter['label']);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? const LinearGradient(
                                colors: [
                                  LunaraColors.primary,
                                  LunaraColors.primaryDark,
                                ],
                              )
                            : null,
                        color: isSelected ? null : AppTheme.cardColor(context),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? LunaraColors.primary.withOpacity(0.3)
                                : Colors.black.withOpacity(0.04),
                            blurRadius: isSelected ? 12 : 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            filter['icon'] as IconData,
                            size: 16,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textDark(context),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            filter['label'],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textDark(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Main Content
            Expanded(
              child: _isLoading
                  ? _buildShimmerList()
                  : _locationDenied
                      ? _buildLocationDeniedState()
                      : _filteredDoctors.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadDoctors,
                              color: LunaraColors.primary,
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                itemCount: _filteredDoctors.length,
                                itemBuilder: (context, index) {
                                  return _buildDoctorCard(
                                      _filteredDoctors[index], index);
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Doctor Card ─────────────────────────────────

  Widget _buildDoctorCard(NearbyDoctor doctor, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + (index * 80)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Facility Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _getGradientForType(doctor.facilityType),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getIconForType(doctor.facilityType),
                    size: 28,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: LunaraColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              doctor.specialty,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: LunaraColors.primaryDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 13, color: AppTheme.secondaryText(context)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              doctor.address,
                              style: TextStyle(
                                  fontSize: 11, color: AppTheme.secondaryText(context)),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Bottom row: distance + actions
            Row(
              children: [
                // Labels section (wrapped in Expanded to prevent pushing buttons off screen)
                Expanded(
                  child: Row(
                    children: [
                      // Distance badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: LunaraColors.fertileGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.near_me_rounded, size: 12, color: LunaraColors.fertileGreen),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                doctor.distanceKm > 0 ? doctor.distanceDisplay : 'Nearby',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: LunaraColors.fertileGreen,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 6),

                      // Category label
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            doctor.categoryLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.secondaryText(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Actions section
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Call/Find button
                    if (doctor.phone != null)
                      _buildActionButton(
                        icon: Icons.phone_rounded,
                        label: 'Call',
                        color: LunaraColors.fertileGreen,
                        onTap: () => _callDoctor(doctor),
                      )
                    else
                      _buildActionButton(
                        icon: Icons.search_rounded,
                        label: 'Find Info',
                        color: const Color(0xFF4285F4),
                        onTap: () => _searchDoctorOnGoogle(doctor),
                      ),

                    const SizedBox(width: 6),

                    // Directions button
                    _buildActionButton(
                      icon: Icons.directions_rounded,
                      label: 'Go',
                      color: (doctor.latitude == 0 && doctor.longitude == 0)
                          ? Colors.grey
                          : LunaraColors.primary,
                      onTap: () => _openDirections(doctor),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.85)],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Shimmer Loading ─────────────────────────────

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: AppTheme.isDark(context) ? const Color(0xFF2A2A2A) : Colors.grey[300]!,
      highlightColor: AppTheme.isDark(context) ? const Color(0xFF3A3A3A) : Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }

  // ─── Location Denied State ────────────────────────

  Widget _buildLocationDeniedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: LunaraColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_off_rounded,
                size: 40,
                color: LunaraColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Location Access Needed',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Enable location access to discover doctors, clinics, and healthcare facilities near you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.secondaryText(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                await Geolocator.openLocationSettings();
              },
              icon: const Icon(Icons.settings_rounded, size: 18),
              label: const Text('Open Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: LunaraColors.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadDoctors,
              child: const Text(
                'Try Again',
                style: TextStyle(
                  color: LunaraColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Empty State ─────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 60, color: AppTheme.divider(context)),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.secondaryText(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different filter or search term',
            style: TextStyle(fontSize: 13, color: AppTheme.secondaryText(context)),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────

  IconData _getIconForType(String type) {
    switch (type) {
      case 'hospital':
        return Icons.local_hospital_rounded;
      case 'doctors':
        return Icons.person_rounded;
      case 'pharmacy':
        return Icons.local_pharmacy_rounded;
      case 'dentist':
        return Icons.mood_rounded;
      case 'physiotherapist':
        return Icons.accessibility_new_rounded;
      case 'laboratory':
        return Icons.biotech_rounded;
      default:
        return Icons.medical_services_rounded;
    }
  }

  List<Color> _getGradientForType(String type) {
    switch (type) {
      case 'hospital':
        return [const Color(0xFFEF5350), const Color(0xFFE53935)];
      case 'doctors':
        return [LunaraColors.primary, LunaraColors.primaryDark];
      case 'pharmacy':
        return [const Color(0xFF66BB6A), const Color(0xFF43A047)];
      case 'dentist':
        return [const Color(0xFF42A5F5), const Color(0xFF1E88E5)];
      case 'laboratory':
        return [const Color(0xFFAB47BC), const Color(0xFF8E24AA)];
      default:
        return [const Color(0xFF26C6DA), const Color(0xFF00ACC1)];
    }
  }

  void _callDoctor(NearbyDoctor doctor) async {
    if (doctor.phone == null) return;
    final uri = Uri.parse('tel:${doctor.phone}');
    try {
      await launchUrl(uri);
    } catch (_) {
      if (mounted) {
        CustomToast.show(context, message: 'Could not open dialer for ${doctor.phone}', icon: Icons.error_outline, backgroundColor: Colors.red[400]);
      }
    }
  }

  void _searchDoctorOnGoogle(NearbyDoctor doctor) async {
    // Construct a high-intent search query for contact info
    final query = Uri.encodeComponent('${doctor.name} ${doctor.address} contact number');
    final uri = Uri.parse('https://www.google.com/search?q=$query');

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        CustomToast.show(context, message: 'Could not open browser for search', icon: Icons.check_circle, backgroundColor: const Color(0xFF4CAF50));
      }
    }
  }

  void _openDirections(NearbyDoctor doctor) async {
    // Fallback data has (0,0) — can't give real directions
    if (doctor.latitude == 0 && doctor.longitude == 0) {
      if (mounted) {
        CustomToast.show(context, message: 'Location not available for this facility. Enable GPS and refresh to get real results.', icon: Icons.check_circle, backgroundColor: const Color(0xFF4CAF50));
      }
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${doctor.latitude},${doctor.longitude}',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        CustomToast.show(context, message: 'Could not open maps for directions', icon: Icons.error_outline, backgroundColor: Colors.red[400]);
      }
    }
  }
}
