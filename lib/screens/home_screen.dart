import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';
import '../services/participation_service.dart';
import '../models/fair.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Position? currentPosition;
  String currentAddress = "Loading address...";
  String status = "Not At Fair";
  Color statusColor = Colors.red;

  Fair? nearestFair;
  double distanceToFair = 0.0;
  int totalPoints = 0;

  final List<Fair> fairs = [
    Fair(
    name: "Southern University College Career Fair",
    locationName: "Southern University College",
    latitude: 1.5328,     
    longitude: 103.6825,
    points: 50,
  ),
  Fair(
    name: "Johor Bahru Education Fair",
    locationName: "Johor Bahru Convention Centre",
    latitude: 1.4920,
    longitude: 103.7425,
    points: 40,
  ),
  ];

  static const double allowedRadius = 200.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _getCurrentLocation();
    totalPoints = await ParticipationService.getTotalPoints();
    setState(() {});
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await LocationService.getCurrentPosition();
      String address = await LocationService.getAddressFromPosition(position);

      setState(() {
        currentPosition = position;
        currentAddress = address;
      });

      _findNearestFair(position);
    } catch (e) {
      setState(() => currentAddress = "Error getting location");
    }
  }

  void _findNearestFair(Position userPos) {
    double minDist = double.infinity;
    Fair? closest;

    for (var fair in fairs) {
      double dist = LocationService.calculateDistance(
        userPos.latitude, userPos.longitude, fair.latitude, fair.longitude);
      
      if (dist < minDist) {
        minDist = dist;
        closest = fair;
      }
    }

    setState(() {
      nearestFair = closest;
      distanceToFair = minDist;
      status = (minDist <= allowedRadius) ? "At Fair" : "Not At Fair";
      statusColor = (minDist <= allowedRadius) ? Colors.green : Colors.red;
    });
  }

  Future<void> _joinFair() async {
    if (nearestFair == null || distanceToFair > allowedRadius) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You are not at the fair location!")),
      );
      return;
    }

    bool success = await ParticipationService.addParticipation(
        nearestFair!.name, nearestFair!.points);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You have already joined ${nearestFair!.name}")),
      );
      return;
    }

    int newTotal = await ParticipationService.getTotalPoints();

    setState(() {
      totalPoints = newTotal;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Successfully joined ${nearestFair!.name} (+${nearestFair!.points} points)")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fair Attendance Tracker"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
              // 返回後更新總分
              int updatedTotal = await ParticipationService.getTotalPoints();
              setState(() {
                totalPoints = updatedTotal;
              });
            },
          ),
        ],
      ),
      body: currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(currentPosition!.latitude, currentPosition!.longitude),
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.fairattendance',
                    ),
                    MarkerLayer(markers: [
                      Marker(
                        point: LatLng(currentPosition!.latitude, currentPosition!.longitude),
                        child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 40),
                      ),
                      if (nearestFair != null)
                        Marker(
                          point: LatLng(nearestFair!.latitude, nearestFair!.longitude),
                          child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                        ),
                    ]),
                    if (nearestFair != null)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: LatLng(nearestFair!.latitude, nearestFair!.longitude),
                            radius: allowedRadius,
                            useRadiusInMeter: true,
                            color: Colors.green.withOpacity(0.2),
                            borderColor: Colors.green,
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                  ],
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Address: $currentAddress"),
                        const SizedBox(height: 8),
                        if (nearestFair != null) ...[
                          Text("Nearest Fair: ${nearestFair!.name}"),
                          Text("Distance: ${distanceToFair.toStringAsFixed(0)} meters"),
                        ],
                        const SizedBox(height: 8),
                        Text("Status: $status", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _joinFair,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text("JOIN FAIR", style: TextStyle(fontSize: 18, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text("Total Points: $totalPoints", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}