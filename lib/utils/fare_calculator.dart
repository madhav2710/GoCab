import '../models/ride_request_model.dart' as ride_request;
import '../models/ride_model.dart' as ride_model;

class FareCalculator {
  static const double baseFare = 2.0;
  static const double perKmRate = 1.5;
  static const double carpoolDiscount = 0.2; // 20% discount for carpool

  /// Calculate estimated fare based on distance and ride type
  /// Works with both RideType enums (old and new models)
  static double calculateEstimatedFare(double distance, String rideType) {
    double fare = baseFare + (distance * perKmRate);

    // Check for carpool discount (works with both enum types)
    if (rideType.toLowerCase().contains('carpool')) {
      fare = fare * (1 - carpoolDiscount);
    }

    return double.parse(fare.toStringAsFixed(2));
  }

  /// Calculate estimated fare using RideType from ride_request_model
  static double calculateEstimatedFareFromRideRequest(
    double distance,
    ride_request.RideType rideType,
  ) {
    return calculateEstimatedFare(distance, rideType.name);
  }

  /// Calculate estimated fare using RideType from ride_model (legacy)
  static double calculateEstimatedFareFromRideModel(
    double distance,
    ride_model.RideType rideType,
  ) {
    return calculateEstimatedFare(distance, rideType.name);
  }
}
