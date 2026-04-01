import 'package:latlong2/latlong.dart';

class Fair {
  final String name;
  final String locationDesc;
  final LatLng position;
  final int points;
  final double radiusInMeters;

  Fair({
    required this.name,
    required this.locationDesc,
    required this.position,
    required this.points,
    this.radiusInMeters = 120.0, // 建议 100-150 米，方便测试
  });
}