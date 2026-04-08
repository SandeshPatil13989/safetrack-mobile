import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  LatLng? _currentPosition;
  final List<LatLng> _routePoints = [];
  bool _isTracking = false;
  double _currentSpeed = 0.0;
  double _currentAccuracy = 0.0;
  double _maxSpeed = 0.0;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable GPS/Location services!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation,
        ),
      );
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _currentAccuracy = position.accuracy;
        });
      }
    } catch (e) {
      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        if (mounted) {
          setState(() {
            _currentPosition = LatLng(position.latitude, position.longitude);
            _currentAccuracy = position.accuracy;
          });
        }
      } catch (err) {
        debugPrint('Location error: $err');
      }
    }
  }

  void _startTracking() {
    setState(() {
      _isTracking = true;
      _maxSpeed = 0.0;
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 1,
        intervalDuration: const Duration(seconds: 2),
        forceLocationManager: false,
      ),
    ).listen((Position position) async {

      // Allow higher accuracy threshold when moving fast
      // If speed > 5 km/h, accept up to 100m accuracy
      // If speed <= 5 km/h, accept up to 50m accuracy
      final speedKmh = position.speed * 3.6;
      final maxAcceptableAccuracy = speedKmh > 5 ? 100.0 : 50.0;
      if (position.accuracy > maxAcceptableAccuracy) return;

      final latLng = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _currentPosition = latLng;
          _currentSpeed = speedKmh < 0 ? 0 : speedKmh;
          _currentAccuracy = position.accuracy;

          // Track max speed
          if (_currentSpeed > _maxSpeed) {
            _maxSpeed = _currentSpeed;
          }

          _routePoints.add(latLng);
          if (_routePoints.length > 500) _routePoints.removeAt(0);
        });
      }

      try { _mapController.move(latLng, 16); } catch (e) {
        debugPrint('Map move error: $e');
      }

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final locationData = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'speed': position.speed,
          'accuracy': position.accuracy,
          'timestamp': DateTime.now().toIso8601String(),
        };
        await FirebaseDatabase.instance
            .ref('locations/$uid/current')
            .set(locationData);

        final historyRef =
            FirebaseDatabase.instance.ref('locations/$uid/history');
        await historyRef.push().set(locationData);

        final snapshot = await historyRef.get();
        if (snapshot.exists) {
          final data = Map<String, dynamic>.from(snapshot.value as Map);
          if (data.length > 100) {
            final keys = data.keys.toList()..sort();
            final toDelete = keys.take(data.length - 100);
            for (final key in toDelete) {
              await historyRef.child(key).remove();
            }
          }
        }
      }
    });
  }

  void _stopTracking() {
    setState(() => _isTracking = false);
    _positionStream?.cancel();
    _positionStream = null;
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter:
                _currentPosition ?? const LatLng(15.8623, 74.4550),
            initialZoom: 15,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.safetrack_mobile',
            ),
            if (_routePoints.length > 1)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    strokeWidth: 3,
                    color: const Color(0xFF2E86C1),
                  ),
                ],
              ),
            if (_currentPosition != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _currentPosition!,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E86C1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E86C1).withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
          ],
        ),

        // Stats bar
        if (_isTracking)
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1F3C).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF2E86C1).withValues(alpha: 0.4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statChip(
                    'Speed',
                    '${_currentSpeed.toStringAsFixed(1)} km/h',
                    Colors.greenAccent,
                  ),
                  _divider(),
                  _statChip(
                    'Max',
                    '${_maxSpeed.toStringAsFixed(1)} km/h',
                    Colors.red,
                  ),
                  _divider(),
                  _statChip(
                    'Accuracy',
                    '±${_currentAccuracy.toStringAsFixed(0)}m',
                    _currentAccuracy <= 15
                        ? Colors.greenAccent
                        : _currentAccuracy <= 30
                            ? Colors.orange
                            : Colors.red,
                  ),
                  _divider(),
                  _statChip(
                    'Points',
                    '${_routePoints.length}',
                    Colors.orange,
                  ),
                ],
              ),
            ),
          ),

        // Low accuracy warning
        if (_isTracking && _currentAccuracy > 30 && _currentAccuracy <= 50)
          Positioned(
            top: 75,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber,
                      color: Colors.orange, size: 14),
                  SizedBox(width: 6),
                  Text(
                    'Low GPS accuracy — move to open area',
                    style: TextStyle(color: Colors.orange, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),

        // Bottom controls
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isTracking && _currentAccuracy > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _currentAccuracy <= 15
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _currentAccuracy <= 15
                          ? Colors.green.withValues(alpha: 0.4)
                          : Colors.orange.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.gps_fixed,
                        color: _currentAccuracy <= 15
                            ? Colors.greenAccent
                            : Colors.orange,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'GPS: ±${_currentAccuracy.toStringAsFixed(0)}m — '
                        '${_currentAccuracy <= 15 ? 'Excellent ✅' : _currentAccuracy <= 30 ? 'Good 👍' : 'Waiting...'}',
                        style: TextStyle(
                          color: _currentAccuracy <= 15
                              ? Colors.greenAccent
                              : Colors.orange,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      _isTracking ? _stopTracking : _startTracking,
                  icon: Icon(
                    _isTracking ? Icons.stop : Icons.play_arrow,
                    size: 22,
                  ),
                  label: Text(
                    _isTracking
                        ? 'Stop Live Tracking'
                        : 'Start Live Tracking',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTracking
                        ? const Color(0xFFE74C3C)
                        : const Color(0xFF2E86C1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 9),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white12,
    );
  }
}