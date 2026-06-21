import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/nearby_doctor.dart';

/// Service to discover real nearby healthcare facilities using
/// the user's GPS location + OpenStreetMap Overpass API.
class NearbyDoctorService {
  static const double _defaultRadiusMeters = 3000; // 3 km

  /// Get the user's current GPS position.
  /// Returns null if permissions are denied or location services are off.
  static Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint("NearbyDoctorService: Location services enabled status: $serviceEnabled");
      if (!serviceEnabled) return null;

      // Check permission
      var permission = await Geolocator.checkPermission();
      debugPrint("NearbyDoctorService: Check permission result: $permission");
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint("NearbyDoctorService: Request permission result: $permission");
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint("NearbyDoctorService: Permission denied forever");
        return null;
      }

      // Fast path: Try to get the last known position first to save 5-10 seconds of GPS lock time.
      try {
        final lastPosition = await Geolocator.getLastKnownPosition();
        if (lastPosition != null) {
          debugPrint("NearbyDoctorService: Found last known position: ${lastPosition.latitude}, ${lastPosition.longitude}");
          return lastPosition;
        }
      } catch (e) {
        debugPrint("NearbyDoctorService: Error getting last known position: $e");
      }

      // Fallback: Get new position with lower accuracy for drastically faster response indoors
      debugPrint("NearbyDoctorService: Requesting current position (accuracy low, 5s limit)...");
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );
      debugPrint("NearbyDoctorService: Current position obtained: ${position.latitude}, ${position.longitude}");
      return position;
    } catch (e) {
      debugPrint("NearbyDoctorService: Exception in getCurrentPosition: $e");
      return null;
    }
  }

  static const List<String> _overpassEndpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://api.openstreetmap.fr/oapi/interpreter',
  ];

  /// Fetch nearby healthcare facilities from the Overpass API.
  static Future<List<NearbyDoctor>> fetchNearbyDoctors({
    Position? position,
    double? radiusMeters,
  }) async {
    // If no position provided, try to get it
    debugPrint("NearbyDoctorService: fetchNearbyDoctors called. Position parameter: $position");
    position ??= await getCurrentPosition();
    if (position == null) {
      debugPrint("NearbyDoctorService: Final position is null, returning fallback doctors");
      return _getFallbackDoctors();
    }

    final queryRadius = radiusMeters ?? _defaultRadiusMeters;

    try {
      var doctors = await _fetchFromOverpass(position, queryRadius);

      // Adaptive widening: If we found 0 results and no custom radius was specified, try 8km
      if (doctors.isEmpty && radiusMeters == null) {
        debugPrint("NearbyDoctorService: 0 results at ${queryRadius}m. Trying adaptive widening search to 8000m...");
        doctors = await _fetchFromOverpass(position, 8000);
      }

      return doctors.isEmpty ? _getFallbackDoctors() : doctors;
    } catch (e) {
      debugPrint("NearbyDoctorService: Exception in fetchNearbyDoctors: $e");
      return _getFallbackDoctors();
    }
  }

  static Future<List<NearbyDoctor>> _fetchFromOverpass(
    Position position,
    double radiusMeters,
  ) async {
    final query = _buildOverpassQuery(
      position.latitude,
      position.longitude,
      radiusMeters,
    );
    debugPrint("NearbyDoctorService: Querying Overpass with radius ${radiusMeters}m:\n$query");

    // Batch fetch: Execute all endpoints concurrently and race for the first successful 200 OK response.
    final futures = _overpassEndpoints.map((endpoint) {
      debugPrint("NearbyDoctorService: Batch fetching endpoint: $endpoint");
      return http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'LunaraApp/1.0 (com.example.lunaraai; support@lunara.ai)',
        },
        body: {'data': query},
      ).timeout(const Duration(seconds: 4));
    });

    http.Response? response;
    try {
      response = await _raceToSuccess(futures);
    } catch (e) {
      debugPrint("NearbyDoctorService: All Overpass batch endpoints failed: $e");
    }

    if (response == null || response.statusCode != 200) {
      debugPrint("NearbyDoctorService: Failed to get successful Overpass response.");
      return [];
    }

    final data = json.decode(response.body);
    final elements = data['elements'] as List<dynamic>? ?? [];
    debugPrint("NearbyDoctorService: Parsed ${elements.length} elements from response.");

    // Replace loop with functional JSON mapping
    final doctors = elements
        .map((element) => _parseElementToDoctor(element, position))
        .where((doc) => doc != null)
        .cast<NearbyDoctor>()
        .toList();

    // Sort by distance
    doctors.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    return doctors;
  }

  /// Helper to race multiple HTTP futures and return the first 200 OK.
  static Future<http.Response> _raceToSuccess(Iterable<Future<http.Response>> futures) {
    final completer = Completer<http.Response>();
    int errors = 0;
    
    for (final f in futures) {
      f.then((res) {
        if (res.statusCode == 200) {
          if (!completer.isCompleted) completer.complete(res);
        } else {
          errors++;
          if (errors == futures.length && !completer.isCompleted) {
            completer.completeError('All failed');
          }
        }
      }).catchError((e) {
        errors++;
        if (errors == futures.length && !completer.isCompleted) {
          completer.completeError('All failed');
        }
      });
    }
    
    return completer.future;
  }

  /// Helper to parse a single JSON element into a NearbyDoctor object
  static NearbyDoctor? _parseElementToDoctor(dynamic element, Position position) {
    final tags = element['tags'] as Map<String, dynamic>? ?? {};
    final name = tags['name'] as String?;
    if (name == null || name.isEmpty) return null; // Skip unnamed facilities

    final lat = (element['lat'] as num?)?.toDouble() ??
        (element['center']?['lat'] as num?)?.toDouble();
    final lon = (element['lon'] as num?)?.toDouble() ??
        (element['center']?['lon'] as num?)?.toDouble();

    if (lat == null || lon == null) return null;

    final distanceKm = _calculateDistance(
      position.latitude,
      position.longitude,
      lat,
      lon,
    );

    final facilityType = _determineFacilityType(tags);
    final specialty = _determineSpecialty(tags, facilityType);

    return NearbyDoctor(
      name: name,
      specialty: specialty,
      address: _buildAddress(tags),
      latitude: lat,
      longitude: lon,
      distanceKm: distanceKm,
      phone: tags['phone'] as String? ?? tags['contact:phone'] as String?,
      isOpen: true,
      facilityType: facilityType,
    );
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
  way["amenity"="doctors"](around:$radiusMeters,$lat,$lon);
  way["amenity"="pharmacy"](around:$radiusMeters,$lat,$lon);
  way["amenity"="dentist"](around:$radiusMeters,$lat,$lon);
  way["healthcare"](around:$radiusMeters,$lat,$lon);

  relation["amenity"="hospital"](around:$radiusMeters,$lat,$lon);
  relation["amenity"="clinic"](around:$radiusMeters,$lat,$lon);
  relation["amenity"="doctors"](around:$radiusMeters,$lat,$lon);
  relation["healthcare"](around:$radiusMeters,$lat,$lon);
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
    final building = tags['building'] as String? ?? '';

    if (amenity == 'hospital' || healthcare == 'hospital' || building == 'hospital') {
      return 'hospital';
    }
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
