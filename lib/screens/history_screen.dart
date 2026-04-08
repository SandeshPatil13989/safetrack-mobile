import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _historyPoints = [];
  bool _isLoading = true;
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot = await FirebaseDatabase.instance
        .ref('locations/$uid/history')
        .limitToLast(50)
        .get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final points = data.values
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      points.sort((a, b) =>
          b['timestamp'].toString().compareTo(a['timestamp'].toString()));
      setState(() {
        _historyPoints = points;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  String _formatTime(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return timestamp;
    }
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
              const Icon(Icons.history, color: Color(0xFF2E86C1)),
              const SizedBox(width: 8),
              const Text(
                'Location History',
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
                      Icon(
                        _showMap ? Icons.list : Icons.map,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showMap ? 'List' : 'Map',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _loadHistory,
                child: const Icon(Icons.refresh, color: Colors.white70),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF2E86C1)))
              : _historyPoints.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_off,
                              color: Colors.grey, size: 60),
                          SizedBox(height: 16),
                          Text(
                            'No history yet',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Start tracking to see your location history',
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
      itemCount: _historyPoints.length,
      itemBuilder: (context, index) {
        final point = _historyPoints[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A2744),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF2E86C1).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF2E86C1).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                        color: Color(0xFF2E86C1),
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lat: ${double.parse(point['latitude'].toString()).toStringAsFixed(5)}'
                      '  Lng: ${double.parse(point['longitude'].toString()).toStringAsFixed(5)}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(point['timestamp'].toString()),
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.location_on,
                  color: Color(0xFF2E86C1), size: 18),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    if (_historyPoints.isEmpty) return const SizedBox();
    final points = _historyPoints
        .map((p) => LatLng(
              double.parse(p['latitude'].toString()),
              double.parse(p['longitude'].toString()),
            ))
        .toList();

    return FlutterMap(
      options: MapOptions(
        initialCenter: points.first,
        initialZoom: 15,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.safetrack_mobile',
        ),
        PolylineLayer(
          polylines: [
            Polyline(
              points: points,
              color: const Color(0xFF2E86C1),
              strokeWidth: 3,
            ),
          ],
        ),
        MarkerLayer(
          markers: points
              .asMap()
              .entries
              .map(
                (e) => Marker(
                  point: e.value,
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: e.key == 0
                          ? Colors.green
                          : e.key == points.length - 1
                              ? Colors.red
                              : const Color(0xFF2E86C1),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white, width: 2),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}