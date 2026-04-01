import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
import '../models/fair.dart';

class LocationService {
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled. Please enable GPS.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<String> getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark p = placemarks[0];
        return "${p.thoroughfare ?? ''}, ${p.locality ?? ''}, ${p.administrativeArea ?? ''}, ${p.country ?? ''}";
      }
    } catch (e) {
      return "Unable to get address";
    }
    return "Unknown address";
  }

  double getDistance(LatLng pos1, LatLng pos2) {
    return Geolocator.distanceBetween(
      pos1.latitude,
      pos1.longitude,
      pos2.latitude,
      pos2.longitude,
    );
  }

  Fair? findNearestFair(Position userPosition, List<Fair> fairs) {
    if (fairs.isEmpty) return null;

    Fair nearest = fairs[0];
    double minDistance = getDistance(
      LatLng(userPosition.latitude, userPosition.longitude),
      nearest.position,
    );

    for (var fair in fairs.skip(1)) {
      double distance = getDistance(
        LatLng(userPosition.latitude, userPosition.longitude),
        fair.position,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearest = fair;
      }
    }
    return nearest;
  }

  bool isAtFair(Position userPos, Fair fair) {
    double distance = getDistance(
      LatLng(userPos.latitude, userPos.longitude),
      fair.position,
    );
    return distance <= fair.radiusInMeters;
  }
}