import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/fair.dart';
import '../services/location_service.dart';
import '../services/participation_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  final ParticipationStorage _storage = ParticipationStorage();

  Position? _currentPosition;
  String _address = "Getting location...";
  Fair? _nearestFair;
  bool _isAtFair = false;
  int _totalPoints = 0;
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = false;

  // ⭐ 新增：控制收缩
  bool _isExpanded = true;

  final List<Fair> _fairs = [
    Fair(
      name: "Southern UC Education & Career Fair 2026",
      locationDesc: "Southern University College, Skudai, Johor",
      position: const LatLng(1.5332, 103.6799),
      points: 60,
      radiusInMeters: 150.0,
    ),
    Fair(
      name: "KL Education Fair 2026",
      locationDesc: "Kuala Lumpur Convention Centre",
      position: const LatLng(3.1357, 101.6869),
      points: 50,
    ),
    Fair(
      name: "Selangor Career Expo 2026",
      locationDesc: "Shah Alam Convention Centre",
      position: const LatLng(3.0738, 101.5183),
      points: 40,
    ),
    Fair(
      name: "Penang Job Fair 2026",
      locationDesc: "Penang International Convention Centre",
      position: const LatLng(5.4350, 100.3091),
      points: 30,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _getCurrentLocation();
  }

  Future<void> _loadData() async {
    final points = await _storage.getTotalPoints();
    final hist = await _storage.getHistory();
    setState(() {
      _totalPoints = points;
      _history = hist;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      Position position = await _locationService.getCurrentPosition();
      String address = await _locationService.getAddressFromLatLng(
          position.latitude, position.longitude);

      Fair? nearest = _locationService.findNearestFair(position, _fairs);
      bool atFair =
          nearest != null && _locationService.isAtFair(position, nearest);

      setState(() {
        _currentPosition = position;
        _address = address;
        _nearestFair = nearest;
        _isAtFair = atFair;
      });
    } catch (e) {
      setState(() {
        _address = "Error: $e";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinFair() async {
    if (_nearestFair == null || !_isAtFair || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not within the fair radius!')),
      );
      return;
    }

    await _storage.recordParticipation(_nearestFair!);
    await _loadData();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Successfully joined ${_nearestFair!.name}! +${_nearestFair!.points} points')),
    );

    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    LatLng userLatLng = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(3.1390, 101.6869);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fair Attendance Tracker'),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _getCurrentLocation),
        ],
      ),
      body: Column(
        children: [
          // 🗺 地图
          Expanded(
            flex: 2,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: userLatLng,
                initialZoom: 15.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.fair.app',
                ),
                if (_currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: userLatLng,
                        child: const Icon(Icons.person_pin_circle,
                            color: Colors.blue, size: 45),
                      ),
                    ],
                  ),
                if (_nearestFair != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _nearestFair!.position,
                        child: const Icon(Icons.location_on,
                            color: Colors.red, size: 45),
                      ),
                    ],
                  ),
                if (_nearestFair != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _nearestFair!.position,
                        radius: _nearestFair!.radiusInMeters,
                        useRadiusInMeter: true,
                        color: Colors.red.withOpacity(0.15),
                        borderStrokeWidth: 3,
                        borderColor: Colors.red,
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // 🍔 可收缩面板
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isExpanded
                ? MediaQuery.of(context).size.height * 0.5
                : 60,
            child: Column(
              children: [
                // 🔽 burger 按钮
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    color: Colors.grey[300],
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_isExpanded
                            ? Icons.keyboard_arrow_down
                            : Icons.keyboard_arrow_up),
                        const SizedBox(width: 8),
                        Text(_isExpanded ? "Hide Panel" : "Show Panel"),
                      ],
                    ),
                  ),
                ),

                // 🔽 展开内容
                if (_isExpanded)
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.location_on),
                              title: const Text("Current Address"),
                              subtitle: Text(_address),
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (_nearestFair != null) ...[
                            Card(
                              color: _isAtFair
                                  ? Colors.green[50]
                                  : Colors.red[50],
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Nearest Fair: ${_nearestFair!.name}",
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                        "Location: ${_nearestFair!.locationDesc}"),
                                    Text(
                                        "Points: ${_nearestFair!.points}"),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Text("Status: "),
                                        Text(
                                          _isAtFair
                                              ? "At Fair"
                                              : "Not At Fair",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _isAtFair
                                                ? Colors.green
                                                : Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed:
                                    _isAtFair && !_isLoading
                                        ? _joinFair
                                        : null,
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: _isAtFair
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                child: const Text("Join Fair",
                                    style: TextStyle(fontSize: 18)),
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),
                          Text("Total Points Earned: $_totalPoints",
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),

                          const SizedBox(height: 20),
                          const Text("Participation History",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),

                          if (_history.isEmpty)
                            const Text("No records yet.")
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics:
                                  const NeverScrollableScrollPhysics(),
                              itemCount: _history.length,
                              itemBuilder: (context, index) {
                                final item =
                                    _history[_history.length - 1 - index];
                                return Card(
                                  child: ListTile(
                                    title: Text(item['fairName']),
                                    subtitle: Text(_storage
                                        .formatTimestamp(
                                            item['timestamp'])),
                                    trailing: Text(
                                      "+${item['points']} pts",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}