import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'map_screen.dart';
import 'history_screen.dart';
import 'geofence_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _userName = 'User';
  bool _isTracking = false;
  bool _sosActive = false;

  final List<Widget> _screens = [
    const MapScreen(),
    const HistoryScreen(),
    const GeofenceScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final snapshot =
          await FirebaseDatabase.instance.ref('users/$uid/name').get();
      if (snapshot.exists) {
        setState(() => _userName = snapshot.value.toString());
      }
    }
  }

  Future<void> _triggerSOS() async {
    int countdown = 3;
    bool cancelled = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Future.doWhile(() async {
            await Future.delayed(const Duration(seconds: 1));
            if (!ctx.mounted) return false;
            setDialogState(() => countdown--);
            if (countdown <= 0) {
              if (ctx.mounted) Navigator.pop(ctx);
              return false;
            }
            return true;
          });

          return AlertDialog(
            backgroundColor: const Color(0xFF1A2744),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.red, width: 1),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                SizedBox(width: 8),
                Text('SOS Activating!',
                    style: TextStyle(color: Colors.white, fontSize: 20)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red, width: 3),
                    color: Colors.red.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Text(
                      countdown.toString(),
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Emergency alert sending...\nTap Cancel to stop.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    cancelled = true;
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (!cancelled) {
      await _sendSOS();
    }
  }

  Future<void> _sendSOS() async {
    setState(() => _sosActive = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseDatabase.instance.ref('sos/$uid').set({
        'active': true,
        'timestamp': DateTime.now().toIso8601String(),
        'userName': _userName,
      });
    }
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1A2744),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Colors.red, width: 1),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 8),
              Text('SOS Active!',
                  style: TextStyle(color: Colors.white, fontSize: 20)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Live location is being shared with emergency contacts!',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  if (uid != null) {
                    await FirebaseDatabase.instance
                        .ref('sos/$uid')
                        .update({'active': false});
                  }
                  setState(() => _sosActive = false);
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Cancel SOS',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3C6E),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              'SafeTrack',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              const Text('Track',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              Switch(
                value: _isTracking,
                onChanged: (val) => setState(() => _isTracking = val),
                activeColor: Colors.greenAccent,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PopupMenuButton(
              child: CircleAvatar(
                backgroundColor: const Color(0xFF2E86C1),
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              itemBuilder: (_) => [
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.person, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Profile'),
                    ],
                  ),
                  onTap: () {
                    Future.delayed(Duration.zero, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreen()),
                      );
                    });
                  },
                ),
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Logout',
                          style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF0D1F3C),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _isTracking ? Colors.greenAccent : Colors.grey,
                    shape: BoxShape.circle,
                    boxShadow: _isTracking
                        ? [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 2,
                            )
                          ]
                        : [],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isTracking ? 'Live Tracking Active' : 'Tracking Paused',
                  style: TextStyle(
                    color: _isTracking ? Colors.greenAccent : Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  'Hello, $_userName 👋',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(child: _screens[_currentIndex]),
        ],
      ),
      floatingActionButton: GestureDetector(
        onLongPress: _triggerSOS,
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Long press SOS button to activate emergency alert'),
              backgroundColor: Color(0xFF1A3C6E),
              duration: Duration(seconds: 2),
            ),
          );
        },
        child: Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: _sosActive ? Colors.red[900] : const Color(0xFFE74C3C),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.5),
                blurRadius: 15,
                spreadRadius: 3,
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 28),
              Text(
                _sosActive ? 'ACTIVE' : 'SOS',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF1A3C6E),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.map, 'Map'),
            _buildNavItem(1, Icons.history, 'History'),
            const SizedBox(width: 60),
            _buildNavItem(2, Icons.fence, 'Geofence'),
            IconButton(
              icon: const Icon(Icons.person, color: Colors.white70),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return IconButton(
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: isSelected ? Colors.white : Colors.white54,
              size: 22),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontSize: 10,
            ),
          ),
        ],
      ),
      onPressed: () => setState(() => _currentIndex = index),
    );
  }
}