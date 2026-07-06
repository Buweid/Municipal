import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng _selectedLocation = const LatLng(23.5880, 58.3829); // Muscat default
  final MapController _mapController = MapController();
  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation!;
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission permanently denied. Enable in settings.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newLocation = LatLng(position.latitude, position.longitude);

      setState(() => _selectedLocation = newLocation);
      _mapController.move(newLocation, 16);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Pick Location'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selectedLocation),
            child: const Text(
              'Confirm',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── MAP ───────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 14,
              onTap: (_, latLng) {
                setState(() => _selectedLocation = latLng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.muscat.municipality',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── INSTRUCTION BANNER ────────────────────────────
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 8),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.touch_app, size: 18, color: Color(0xFF2E7D32)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap on the map to select the issue location',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── COORDINATES DISPLAY ───────────────────────────
          Positioned(
            bottom: 90,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Color(0x22000000), blurRadius: 8),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.pin_drop, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedLocation.latitude.toStringAsFixed(5)}, '
                        '${_selectedLocation.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── GPS BUTTON ────────────────────────────────────
          Positioned(
            bottom: 20,
            right: 16,
            child: FloatingActionButton(
              backgroundColor: const Color(0xFF2E7D32),
              onPressed: _isLocating ? null : _getCurrentLocation,
              child: _isLocating
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
                  : const Icon(Icons.my_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}