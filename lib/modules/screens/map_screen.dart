import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';

class MapScreen extends StatefulWidget {
  final String title;
  final int? driverFirebaseId;
  final bool showNearbyDrivers;

  const MapScreen({
    super.key,
    this.title = 'Map',
    this.driverFirebaseId,
    this.showNearbyDrivers = false,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;

  final Map<MarkerId, Marker> _markers = {};
  StreamSubscription? _driversSubscription;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _driversSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      _addMyLocationMarker(position);

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15,
        ),
      );

      _listenToDrivers();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _addMyLocationMarker(Position position) {
    final markerId = const MarkerId('my_location');
    final marker = Marker(
      markerId: markerId,
      position: LatLng(position.latitude, position.longitude),
      infoWindow: const InfoWindow(title: 'My Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
    );
    setState(() => _markers[markerId] = marker);
  }

  void _listenToDrivers() {
    _driversSubscription?.cancel();

    _driversSubscription = FirebaseDatabase.instance
        .ref('drivers')
        .onValue
        .listen((event) {
      if (!mounted) return;

      final data = event.snapshot.value;
      if (data == null) return;

      final driversMap = Map<String, dynamic>.from(data as Map);

      _markers.removeWhere((key, value) => key.value.startsWith('driver_'));

      driversMap.forEach((key, value) {
        final driver = Map<String, dynamic>.from(value as Map);
        final driverLat =
            double.tryParse(driver['latitude'].toString()) ?? 0;
        final driverLng =
            double.tryParse(driver['longitude'].toString()) ?? 0;
        final status = driver['status'] ?? 'offline';
        final driverName = driver['driver_name'] ?? 'Driver';
        final driverId = int.tryParse(key) ?? 0;

        if (widget.driverFirebaseId != null) {
          if (driverId != widget.driverFirebaseId) return;
        } else {
          if (!widget.showNearbyDrivers) return;
          if (status != 'available') return;

          if (_currentPosition != null) {
            final distance = Geolocator.distanceBetween(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                  driverLat,
                  driverLng,
                ) /
                1000;
            if (distance > 3) return;
          }
        }

        final markerId = MarkerId('driver_$key');
        final marker = Marker(
          markerId: markerId,
          position: LatLng(driverLat, driverLng),
          infoWindow: InfoWindow(
            title: driverName,
            snippet:
                status == 'available' ? '🟢 Available' : '🟡 On a ride',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            status == 'available'
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueOrange,
          ),
        );

        setState(() => _markers[markerId] = marker);

        if (widget.driverFirebaseId != null &&
            driverId == widget.driverFirebaseId) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(LatLng(driverLat, driverLng)),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (_currentPosition != null) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    15,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentPosition == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Could not get location',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    // ── Google Map ──────────────────────────
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        zoom: 15,
                      ),
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      markers: Set<Marker>.of(_markers.values),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      zoomGesturesEnabled: true,
                      scrollGesturesEnabled: true,
                      rotateGesturesEnabled: true,
                      tiltGesturesEnabled: true,
                    ),

                    // ── Legend (bottom left) ─────────────────
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 12, height: 12,
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('My Location',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 12, height: 12,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Available Driver',
                                    style: TextStyle(fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 12, height: 12,
                                  decoration: const BoxDecoration(
                                    color: Colors.orange,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text('Driver on ride',
                                    style: TextStyle(fontSize: 12)),
                              ],
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