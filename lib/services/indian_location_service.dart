import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

class IndianLocationService {
  // Popular Indian cities with coordinates
  static const Map<String, Map<String, double>> indianCities = {
    'Mumbai': {'latitude': 19.0760, 'longitude': 72.8777},
    'Delhi': {'latitude': 28.7041, 'longitude': 77.1025},
    'Bangalore': {'latitude': 12.9716, 'longitude': 77.5946},
    'Hyderabad': {'latitude': 17.3850, 'longitude': 78.4867},
    'Chennai': {'latitude': 13.0827, 'longitude': 80.2707},
    'Kolkata': {'latitude': 22.5726, 'longitude': 88.3639},
    'Pune': {'latitude': 18.5204, 'longitude': 73.8567},
    'Ahmedabad': {'latitude': 23.0225, 'longitude': 72.5714},
    'Jaipur': {'latitude': 26.9124, 'longitude': 75.7873},
    'Surat': {'latitude': 21.1702, 'longitude': 72.8311},
  };

  // Popular Indian landmarks and malls
  static const Map<String, Map<String, dynamic>> indianLandmarks = {
    'Phoenix MarketCity, Mumbai': {
      'latitude': 19.0596,
      'longitude': 72.8295,
      'city': 'Mumbai',
      'type': 'Mall',
    },
    'Inorbit Mall, Mumbai': {
      'latitude': 19.0596,
      'longitude': 72.8295,
      'city': 'Mumbai',
      'type': 'Mall',
    },
    'High Street Phoenix, Mumbai': {
      'latitude': 19.0596,
      'longitude': 72.8295,
      'city': 'Mumbai',
      'type': 'Mall',
    },
    'Select Citywalk, Delhi': {
      'latitude': 28.5275,
      'longitude': 77.2189,
      'city': 'Delhi',
      'type': 'Mall',
    },
    'DLF Cyber City, Delhi': {
      'latitude': 28.5275,
      'longitude': 77.2189,
      'city': 'Delhi',
      'type': 'Mall',
    },
    'Forum Vijaya, Bangalore': {
      'latitude': 12.9716,
      'longitude': 77.5946,
      'city': 'Bangalore',
      'type': 'Mall',
    },
    'Phoenix MarketCity, Bangalore': {
      'latitude': 12.9716,
      'longitude': 77.5946,
      'city': 'Bangalore',
      'type': 'Mall',
    },
    'Inorbit Mall, Hyderabad': {
      'latitude': 17.3850,
      'longitude': 78.4867,
      'city': 'Hyderabad',
      'type': 'Mall',
    },
    'Phoenix MarketCity, Chennai': {
      'latitude': 13.0827,
      'longitude': 80.2707,
      'city': 'Chennai',
      'type': 'Mall',
    },
    'South City Mall, Kolkata': {
      'latitude': 22.5726,
      'longitude': 88.3639,
      'city': 'Kolkata',
      'type': 'Mall',
    },
  };

  // Get current location with India-specific error handling
  Future<Position?> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return null;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return null;
      }

      // Get current position with India-optimized settings
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      debugPrint('Error getting current location: $e');
      return null;
    }
  }

  // Get address from coordinates with India-specific formatting
  Future<String?> getAddressFromCoordinates(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Format address for India
        List<String> addressParts = [];

        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          addressParts.add(place.postalCode!);
        }

        return addressParts.join(', ');
      }
      return null;
    } catch (e) {
      debugPrint('Error getting address from coordinates: $e');
      return null;
    }
  }

  // Get coordinates from address with India-specific search
  Future<Map<String, double>?> getCoordinatesFromAddress(String address) async {
    try {
      // Add "India" to the address for better geocoding
      String searchAddress = address;
      if (!address.toLowerCase().contains('india')) {
        searchAddress = '$address, India';
      }

      List<Location> locations = await locationFromAddress(searchAddress);
      if (locations.isNotEmpty) {
        return {
          'latitude': locations.first.latitude,
          'longitude': locations.first.longitude,
        };
      }
      return null;
    } catch (e) {
      debugPrint('Error getting coordinates from address: $e');
      return null;
    }
  }

  // Get popular Indian landmarks by city
  List<Map<String, dynamic>> getLandmarksByCity(String city) {
    return indianLandmarks.entries
        .where((entry) => entry.value['city'] == city)
        .map(
          (entry) => {
            'name': entry.key,
            'latitude': entry.value['latitude'],
            'longitude': entry.value['longitude'],
            'type': entry.value['type'],
          },
        )
        .toList();
  }

  // Get all malls in India
  List<Map<String, dynamic>> getAllMalls() {
    return indianLandmarks.entries
        .where((entry) => entry.value['type'] == 'Mall')
        .map(
          (entry) => {
            'name': entry.key,
            'latitude': entry.value['latitude'],
            'longitude': entry.value['longitude'],
            'city': entry.value['city'],
          },
        )
        .toList();
  }

  // Get all Indian cities
  List<String> getAllCities() {
    return indianCities.keys.toList();
  }

  // Get coordinates for a specific city
  Map<String, double>? getCityCoordinates(String cityName) {
    return indianCities[cityName];
  }

  // Calculate distance between two points in India (in kilometers)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  // Get default location (Mumbai, India)
  Map<String, double> getDefaultLocation() {
    return indianCities['Mumbai']!;
  }

  // Check if location is in India (rough bounds)
  bool isLocationInIndia(double latitude, double longitude) {
    return latitude >= 6.0 &&
        latitude <= 37.0 &&
        longitude >= 68.0 &&
        longitude <= 97.0;
  }

  // Get nearby landmarks within a radius
  List<Map<String, dynamic>> getNearbyLandmarks(
    double latitude,
    double longitude,
    double radiusKm,
  ) {
    List<Map<String, dynamic>> nearby = [];

    for (var entry in indianLandmarks.entries) {
      double distance = calculateDistance(
        latitude,
        longitude,
        entry.value['latitude'],
        entry.value['longitude'],
      );

      if (distance <= radiusKm) {
        nearby.add({
          'name': entry.key,
          'latitude': entry.value['latitude'],
          'longitude': entry.value['longitude'],
          'city': entry.value['city'],
          'type': entry.value['type'],
          'distance': distance,
        });
      }
    }

    // Sort by distance
    nearby.sort(
      (a, b) => (a['distance'] as double).compareTo(b['distance'] as double),
    );
    return nearby;
  }

  // Search landmarks by name (fuzzy search)
  List<Map<String, dynamic>> searchLandmarks(String query) {
    String lowerQuery = query.toLowerCase();
    List<Map<String, dynamic>> results = [];

    for (var entry in indianLandmarks.entries) {
      if (entry.key.toLowerCase().contains(lowerQuery) ||
          entry.value['city'].toString().toLowerCase().contains(lowerQuery)) {
        results.add({
          'name': entry.key,
          'latitude': entry.value['latitude'],
          'longitude': entry.value['longitude'],
          'city': entry.value['city'],
          'type': entry.value['type'],
        });
      }
    }

    return results;
  }
}
