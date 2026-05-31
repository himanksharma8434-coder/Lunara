/// Represents a real nearby healthcare facility found via location search.
class NearbyDoctor {
  final String name;
  final String specialty;
  final String address;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final String? phone;
  final bool isOpen;
  final String facilityType; // hospital, clinic, doctors, pharmacy, etc.

  const NearbyDoctor({
    required this.name,
    required this.specialty,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    this.phone,
    this.isOpen = true,
    this.facilityType = 'clinic',
  });

  /// Display-friendly distance string.
  String get distanceDisplay {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  /// Icon-friendly category mapping.
  String get categoryLabel {
    switch (facilityType) {
      case 'hospital':
        return 'Hospital';
      case 'doctors':
        return 'Doctor\'s Office';
      case 'pharmacy':
        return 'Pharmacy';
      case 'dentist':
        return 'Dentist';
      case 'physiotherapist':
        return 'Physiotherapist';
      case 'laboratory':
        return 'Laboratory';
      default:
        return 'Clinic';
    }
  }
}
