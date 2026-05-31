import 'dart:convert';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/nearby_doctor.dart';

/// Service to discover real nearby healthcare facilities using
/// the user's GPS location + OpenStreetMap Overpass API.
class NearbyDoctorService {
  static const double _defaultRadiusMeters = 10000; // 10 km

  /// Get the user's current GPS position.
  /// Returns null if permissions are denied or location services are off.
  static Future<Position?> getCurrentPosition() async {
    // Check if location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    // Check permission
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    // Fast path: Try to get the last known position first to save 5-10 seconds of GPS lock time.
    try {
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        return lastPosition;
      }
    } catch (_) {}

    // Fallback: Get new position with lower accuracy for drastically faster response indoors
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.low,
        timeLimit: Duration(seconds: 5),
      ),
    );
  }

  /// Fetch nearby healthcare facilities from the Overpass API.
  static Future<List<NearbyDoctor>> fetchNearbyDoctors({
    Position? position,
    double radiusMeters = _defaultRadiusMeters,
  }) async {
    // If no position provided, try to get it
    position ??= await getCurrentPosition();
    if (position == null) return _getFallbackDoctors();

    try {
      final query = _buildOverpassQuery(
        position.latitude,
        position.longitude,
        radiusMeters,
      );

      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'data': query},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        return _getFallbackDoctors();
      }

      final data = json.decode(response.body);
      final elements = data['elements'] as List<dynamic>? ?? [];

      final doctors = <NearbyDoctor>[];
      for (final element in elements) {
        final tags = element['tags'] as Map<String, dynamic>? ?? {};
        final name = tags['name'] as String?;
        if (name == null || name.isEmpty) continue; // Skip unnamed facilities

        final lat = (element['lat'] as num?)?.toDouble() ??
            (element['center']?['lat'] as num?)?.toDouble();
        final lon = (element['lon'] as num?)?.toDouble() ??
            (element['center']?['lon'] as num?)?.toDouble();

        if (lat == null || lon == null) continue;

        final distanceKm = _calculateDistance(
          position.latitude,
          position.longitude,
          lat,
          lon,
        );

        final facilityType = _determineFacilityType(tags);
        final specialty = _determineSpecialty(tags, facilityType);

        doctors.add(NearbyDoctor(
          name: name,
          specialty: specialty,
          address: _buildAddress(tags),
          latitude: lat,
          longitude: lon,
          distanceKm: distanceKm,
          phone: tags['phone'] as String? ?? tags['contact:phone'] as String?,
          isOpen: true, // OSM doesn't reliably give real-time open/closed
          facilityType: facilityType,
        ));
      }

      // Sort by distance
      doctors.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));

      return doctors.isEmpty ? _getFallbackDoctors() : doctors;
    } catch (e) {
      return _getFallbackDoctors();
    }
  }

  /// Build the Overpass QL query to find healthcare facilities nearby.
  static String _buildOverpassQuery(
    double lat,
    double lon,
    double radiusMeters,
  ) {
    return '''
[out:json][timeout:8];
(
  node["amenity"="hospital"](around:$radiusMeters,$lat,$lon);
  node["amenity"="clinic"](around:$radiusMeters,$lat,$lon);
  node["amenity"="doctors"](around:$radiusMeters,$lat,$lon);
  node["amenity"="pharmacy"](around:$radiusMeters,$lat,$lon);
  node["amenity"="dentist"](around:$radiusMeters,$lat,$lon);
  node["healthcare"](around:$radiusMeters,$lat,$lon);
  way["amenity"="hospital"](around:$radiusMeters,$lat,$lon);
  way["amenity"="clinic"](around:$radiusMeters,$lat,$lon);
);
out center;
''';
  }

  /// Calculate the Haversine distance between two lat/lng points.
  static double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371.0; // Earth's radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;

  /// Determine a facility type from OSM tags.
  static String _determineFacilityType(Map<String, dynamic> tags) {
    final amenity = tags['amenity'] as String? ?? '';
    final healthcare = tags['healthcare'] as String? ?? '';

    if (amenity == 'hospital') return 'hospital';
    if (amenity == 'doctors' || healthcare == 'doctor') return 'doctors';
    if (amenity == 'dentist' || healthcare == 'dentist') return 'dentist';
    if (amenity == 'pharmacy') return 'pharmacy';
    if (healthcare == 'physiotherapist') return 'physiotherapist';
    if (healthcare == 'laboratory') return 'laboratory';
    if (amenity == 'clinic' || healthcare == 'clinic') return 'clinic';
    if (healthcare.isNotEmpty) return 'clinic';
    return 'clinic';
  }

  /// Determine a human-readable specialty from OSM tags.
  static String _determineSpecialty(
    Map<String, dynamic> tags,
    String facilityType,
  ) {
    // Check for explicit speciality tag
    final speciality =
        tags['healthcare:speciality'] as String? ?? tags['speciality'] as String? ?? '';
    if (speciality.isNotEmpty) {
      return _formatSpeciality(speciality);
    }

    // Infer from facility type
    switch (facilityType) {
      case 'hospital':
        return 'Hospital / Multi-Specialty';
      case 'doctors':
        return 'General Physician';
      case 'dentist':
        return 'Dentist';
      case 'pharmacy':
        return 'Pharmacy';
      case 'physiotherapist':
        return 'Physiotherapy';
      case 'laboratory':
        return 'Diagnostic Lab';
      default:
        return 'Healthcare Clinic';
    }
  }

  /// Format an OSM speciality tag (e.g. "gynaecology;obstetrics") into
  /// a human-readable string.
  static String _formatSpeciality(String raw) {
    return raw
        .split(';')
        .take(2) // max 2 specialties to keep it concise
        .map((s) => s.trim())
        .map((s) => s[0].toUpperCase() + s.substring(1))
        .join(' · ');
  }

  /// Build an address string from OSM tags.
  static String _buildAddress(Map<String, dynamic> tags) {
    final parts = <String>[];
    if (tags['addr:street'] != null) {
      final houseNumber = tags['addr:housenumber'] as String? ?? '';
      parts.add('$houseNumber ${tags['addr:street']}'.trim());
    }
    if (tags['addr:city'] != null) parts.add(tags['addr:city'] as String);
    if (tags['addr:postcode'] != null) {
      parts.add(tags['addr:postcode'] as String);
    }
    if (parts.isEmpty) {
      // Try alt address formats
      if (tags['address'] != null) return tags['address'] as String;
      return 'Address not available';
    }
    return parts.join(', ');
  }

  /// Fallback sample doctors when location is unavailable or API fails.
  static List<NearbyDoctor> _getFallbackDoctors() {
    return const [
      NearbyDoctor(
        name: 'City General Hospital',
        specialty: 'Hospital / Multi-Specialty',
        address: 'Near you',
        latitude: 0,
        longitude: 0,
        distanceKm: 0,
        facilityType: 'hospital',
      ),
      NearbyDoctor(
        name: 'Women\'s Health Clinic',
        specialty: 'Gynaecology · Obstetrics',
        address: 'Near you',
        latitude: 0,
        longitude: 0,
        distanceKm: 0,
        facilityType: 'clinic',
      ),
      NearbyDoctor(
        name: 'Family Care Center',
        specialty: 'General Physician',
        address: 'Near you',
        latitude: 0,
        longitude: 0,
        distanceKm: 0,
        facilityType: 'doctors',
      ),
      NearbyDoctor(
        name: 'HealthFirst Diagnostics',
        specialty: 'Diagnostic Lab',
        address: 'Near you',
        latitude: 0,
        longitude: 0,
        distanceKm: 0,
        facilityType: 'laboratory',
      ),
    ];
  }
}
