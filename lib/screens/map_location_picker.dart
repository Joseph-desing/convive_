import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class MapLocationPicker extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapLocationPicker({Key? key, this.initialLat, this.initialLng}) : super(key: key);

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  LatLng _center = LatLng(-0.180653, -78.467834); // Quito fallback
  LatLng? _picked;
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar ubicación'),
        actions: [
          TextButton(
            onPressed: () {
                  final LatLng chosen = _picked ?? LatLng(widget.initialLat ?? _center.latitude, widget.initialLng ?? _center.longitude);
                  // Debug log
                  debugPrint('MapLocationPicker: returning ${chosen.latitude}, ${chosen.longitude}');
                  Navigator.pop(context, {'lat': chosen.latitude, 'lng': chosen.longitude});
                },
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialLat != null && widget.initialLng != null
                  ? LatLng(widget.initialLat!, widget.initialLng!)
                  : _center,
              initialZoom: 13,
              onTap: (tapPos, latlng) {
                setState(() {
                  _picked = latlng;
                });
                // Center map on the picked point and show feedback
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  try {
                    _mapController.move(latlng, 15);
                  } catch (_) {}
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ubicación seleccionada: ${latlng.latitude.toStringAsFixed(5)}, ${latlng.longitude.toStringAsFixed(5)}')));
              },
              onLongPress: (tapPos, latlng) {
                setState(() {
                  _picked = latlng;
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  try {
                    _mapController.move(latlng, 15);
                  } catch (_) {}
                });
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ubicación seleccionada: ${latlng.latitude.toStringAsFixed(5)}, ${latlng.longitude.toStringAsFixed(5)}')));
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.convive',
              ),
              if (_picked != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _picked!,
                    width: 48,
                    height: 48,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                  )
                ]),
            ],
          ),
          // Confirm button at bottom
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _picked == null
                  ? null
                  : () {
                      Navigator.pop(context, {'lat': _picked!.latitude, 'lng': _picked!.longitude});
                    },
              child: const Text('Confirmar ubicación', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnUser,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Future<void> _centerOnUser() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permiso de ubicación denegado')));
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      final latlng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _picked = latlng;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(latlng, 15);
        } catch (e) {
          // ignore
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo obtener la ubicación: $e')));
    }
  }
}
