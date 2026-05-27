import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class MapLocationPicker extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapLocationPicker({Key? key, this.initialLat, this.initialLng})
      : super(key: key);

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  LatLng _center = LatLng(-0.180653, -78.467834); // Quito fallback
  LatLng? _picked;
  String? _pickedAddress;
  bool _isLoadingAddress = false;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _center = LatLng(widget.initialLat!, widget.initialLng!);
      _picked = _center;
      _pickedAddress = 'Ubicación de la recomendación';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar ubicación'),
        actions: [
          TextButton(
            onPressed: () {
              final LatLng chosen = _picked ??
                  LatLng(
                    widget.initialLat ?? _center.latitude,
                    widget.initialLng ?? _center.longitude,
                  );
              debugPrint(
                  'MapLocationPicker: returning ${chosen.latitude}, ${chosen.longitude}');
              Navigator.pop(context, {
                'lat': chosen.latitude,
                'lng': chosen.longitude,
                'address': _pickedAddress ?? 'Ubicación no disponible',
              });
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
              initialCenter: widget.initialLat != null &&
                      widget.initialLng != null
                  ? LatLng(widget.initialLat!, widget.initialLng!)
                  : _center,
              initialZoom: 13,
              onTap: (tapPos, latlng) async {
                await _getAddressFromCoordinates(latlng);
                setState(() => _picked = latlng);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  try {
                    _mapController.move(latlng, 15);
                  } catch (_) {}
                });
              },
              onLongPress: (tapPos, latlng) async {
                await _getAddressFromCoordinates(latlng);
                setState(() => _picked = latlng);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  try {
                    _mapController.move(latlng, 15);
                  } catch (_) {}
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.convive',
                tileProvider: CancellableNetworkTileProvider(),
              ),
              if (_picked != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _picked!,
                    width: 48,
                    height: 48,
                    child: const Icon(Icons.location_on,
                        color: Colors.red, size: 36),
                  )
                ]),
            ],
          ),
          // Card de dirección en la parte inferior
          Positioned(
            left: 16,
            right: 16,
            bottom: 100,
            child: _picked == null
                ? _buildAddressCard(
                    '📍 Toca en el mapa para seleccionar una ubicación',
                    Colors.grey[100]!,
                    Colors.grey,
                  )
                : _isLoadingAddress
                    ? _buildAddressCard(
                        'Buscando dirección...',
                        Colors.amber[50]!,
                        Colors.amber,
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildAddressCard(
                            _pickedAddress ?? '📍 Ubicación seleccionada',
                            Colors.green[50]!,
                            Colors.green,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE91E63),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                                shadowColor: const Color(0xFFE91E63)
                                    .withOpacity(0.5),
                              ),
                              onPressed: () {
                                Navigator.pop(context, {
                                  'lat': _picked!.latitude,
                                  'lng': _picked!.longitude,
                                  'address': _pickedAddress ??
                                      'Ubicación no disponible',
                                });
                              },
                              icon: const Icon(Icons.check_circle, size: 20),
                              label: const Text(
                                'Confirmar ubicación',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
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

  /// Card para mostrar la dirección legible
  Widget _buildAddressCard(
      String address, Color bgColor, Color? accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: (accentColor ?? Colors.grey).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: (accentColor ?? Colors.grey).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: accentColor ?? Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                'Dirección',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: (accentColor ?? Colors.grey).withOpacity(0.7),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            address,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C3E50),
              height: 1.4,
              letterSpacing: 0.3,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          if (_picked != null) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.navigation_outlined,
                    size: 14,
                    color: (accentColor ?? Colors.grey).withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_picked!.latitude.toStringAsFixed(5)}, '
                    '${_picked!.longitude.toStringAsFixed(5)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Obtiene dirección legible desde coordenadas usando Nominatim (OpenStreetMap).
  /// Usa dart:convert para decodificar correctamente en Android (tildes, UTF-8).
  Future<void> _getAddressFromCoordinates(LatLng latlng) async {
    setState(() => _isLoadingAddress = true);
    try {
      // Construir URI con parámetros correctos
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'format': 'json',
        'lat': latlng.latitude.toString(),
        'lon': latlng.longitude.toString(),
        'zoom': '18',
        'addressdetails': '1',
        'accept-language': 'es',
      });

      debugPrint('🌐 Nominatim GET: $uri');

      final response = await http.get(
        uri,
        headers: {
          // Nominatim requiere User-Agent identificatorio;
          // sin él puede bloquear la petición en Android
          'User-Agent':
              'ConVive/1.0 (contacto: changoluizajoseph@gmail.com)',
          'Accept': 'application/json',
          'Accept-Language': 'es',
        },
      ).timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw Exception('Timeout en geocoding'),
      );

      debugPrint('📡 Nominatim status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // utf8.decode + jsonDecode → correcto en Android y Web.
        // response.body puede fallar con tildes en Android; bodyBytes no.
        final Map<String, dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

        final addr = (data['address'] as Map<String, dynamic>?) ?? {};
        debugPrint('📍 address obj: $addr');

        // --- Construir dirección bonita ---
        final parts = <String>[];

        // 1. Calle / vía / sector
        final street =
            (addr['road'] ?? addr['street'] ?? addr['hamlet'] ?? '') as String;
        if (street.isNotEmpty) parts.add(street);

        // 2. Número de casa — pegar al final de la calle
        final houseNumber = (addr['house_number'] ?? '') as String;
        if (houseNumber.isNotEmpty && parts.isNotEmpty) {
          parts[0] = '${parts[0]} $houseNumber';
        }

        // 3. Barrio / urbanización / poblado
        final neighbourhood = (addr['neighbourhood'] ??
                addr['suburb'] ??
                addr['village'] ??
                addr['town'] ??
                '') as String;
        if (neighbourhood.isNotEmpty && !parts.contains(neighbourhood)) {
          parts.add(neighbourhood);
        }

        // 4. Ciudad / municipio / cantón
        final city = (addr['city'] ??
                addr['municipality'] ??
                addr['county'] ??
                '') as String;
        if (city.isNotEmpty && !parts.contains(city)) parts.add(city);

        // 5. Provincia / estado
        final state = (addr['state'] ?? '') as String;
        if (state.isNotEmpty && !parts.contains(state)) parts.add(state);

        // Eliminar duplicados manteniendo orden
        final seen = <String>{};
        final unique =
            parts.where((p) => seen.add(p.trim())).toList();

        String finalAddress = unique.join(', ');

        // Fallback: display_name si no se pudo armar la dirección
        if (finalAddress.trim().isEmpty) {
          finalAddress = (data['display_name'] as String?) ??
              'Ubicación: ${latlng.latitude.toStringAsFixed(5)}, '
                  '${latlng.longitude.toStringAsFixed(5)}';
        }

        debugPrint('✅ Dirección final: $finalAddress');

        if (!mounted) return;
        setState(() {
          _pickedAddress = finalAddress;
          _isLoadingAddress = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(finalAddress),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Nominatim HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Geocoding error: $e');
      if (!mounted) return;
      setState(() {
        // Fallback de coordenadas SOLO si la API falla completamente
        _pickedAddress =
            'Ubicación: ${latlng.latitude.toStringAsFixed(5)}, '
            '${latlng.longitude.toStringAsFixed(5)}';
        _isLoadingAddress = false;
      });
    }
  }

  /// Centra el mapa en la ubicación actual del dispositivo
  Future<void> _centerOnUser() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de ubicación denegado')),
          );
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      final latlng = LatLng(pos.latitude, pos.longitude);

      await _getAddressFromCoordinates(latlng);

      if (!mounted) return;
      setState(() => _picked = latlng);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(latlng, 15);
        } catch (_) {}
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo obtener la ubicación: $e')),
      );
    }
  }
}
