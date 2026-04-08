import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class GeofenceScreen extends StatefulWidget {
  const GeofenceScreen({super.key});

  @override
  State<GeofenceScreen> createState() => _GeofenceScreenState();
}

class _GeofenceScreenState extends State<GeofenceScreen> {
  final _nameController = TextEditingController();
  final _radiusController = TextEditingController(text: '100');
  List<Map<String, dynamic>> _geofences = [];
  LatLng _currentPosition = const LatLng(12.9716, 77.5946);
  bool _isLoading = true;
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadGeofences();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    } catch (_) {}
  }

  Future<void> _loadGeofences() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseDatabase.instance
        .ref('geofences/$uid')
        .get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _geofences = data.entries
            .map((e) => {
                  'id': e.key,
                  ...Map<String, dynamic>.from(e.value as Map),
                })
            .toList();
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _addGeofence() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a zone name')),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final geofenceData = {
      'name': _nameController.text.trim(),
      'latitude': _currentPosition.latitude,
      'longitude': _currentPosition.longitude,
      'radius': double.parse(_radiusController.text),
      'active': true,
      'createdAt': DateTime.now().toIso8601String(),
    };

    await FirebaseDatabase.instance
        .ref('geofences/$uid')
        .push()
        .set(geofenceData);

    _nameController.clear();
    _loadGeofences();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Geofence zone added!'),
          backgroundColor: Color(0xFF2E86C1),
        ),
      );
    }
  }

  Future<void> _deleteGeofence(String id) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseDatabase.instance.ref('geofences/$uid/$id').remove();
    _loadGeofences();
  }

  bool _isInsideGeofence(Map<String, dynamic> geofence) {
    final distance = Geolocator.distanceBetween(
      _currentPosition.latitude,
      _currentPosition.longitude,
      double.parse(geofence['latitude'].toString()),
      double.parse(geofence['longitude'].toString()),
    );
    return distance <= double.parse(geofence['radius'].toString());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF0D1F3C),
          child: Row(
            children: [
              const Icon(Icons.fence, color: Color(0xFF2E86C1)),
              const SizedBox(width: 8),
              const Text(
                'Geofence Zones',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _showMap = !_showMap),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E86C1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(_showMap ? Icons.list : Icons.map,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(_showMap ? 'List' : 'Map',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF0A1628),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Safe Zone at Current Location',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Zone name (e.g. Home)',
                        hintStyle:
                            const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF1A2744),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _radiusController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Radius (m)',
                        hintStyle:
                            const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF1A2744),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addGeofence,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E86C1),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child:
                        const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF2E86C1)))
              : _geofences.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fence,
                              color: Colors.grey, size: 60),
                          SizedBox(height: 16),
                          Text('No geofence zones yet',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 16)),
                          SizedBox(height: 8),
                          Text(
                            'Add a zone using the form above',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : _showMap
                      ? _buildMapView()
                      : _buildListView(),
        ),
      ],
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _geofences.length,
      itemBuilder: (context, index) {
        final fence = _geofences[index];
        final isInside = _isInsideGeofence(fence);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2744),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isInside
                  ? Colors.greenAccent.withOpacity(0.5)
                  : const Color(0xFF2E86C1).withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isInside
                      ? Colors.greenAccent.withOpacity(0.15)
                      : const Color(0xFF2E86C1).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.fence,
                  color: isInside
                      ? Colors.greenAccent
                      : const Color(0xFF2E86C1),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fence['name'].toString(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Radius: ${fence['radius']}m  •  ${isInside ? "✅ Inside zone" : "❌ Outside zone"}',
                      style: TextStyle(
                        color: isInside
                            ? Colors.greenAccent
                            : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: Colors.redAccent),
                onPressed: () =>
                    _deleteGeofence(fence['id'].toString()),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    return FlutterMap(
      options: MapOptions(
        initialCenter: _currentPosition,
        initialZoom: 15,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.safetrack_mobile',
        ),
        CircleLayer(
          circles: _geofences
              .map((fence) => CircleMarker(
                    point: LatLng(
                      double.parse(fence['latitude'].toString()),
                      double.parse(fence['longitude'].toString()),
                    ),
                    radius:
                        double.parse(fence['radius'].toString()),
                    color:
                        const Color(0xFF2E86C1).withOpacity(0.2),
                    borderColor: const Color(0xFF2E86C1),
                    borderStrokeWidth: 2,
                    useRadiusInMeter: true,
                  ))
              .toList(),
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: _currentPosition,
              width: 30,
              height: 30,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF2E86C1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_pin,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }
}