import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

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
  String? _pickedAddress; // 🆕 Guardar dirección legible
  bool _isLoadingAddress = false; // 🆕 Indicador de carga
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
  }

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
                  // 🆕 Pasar también la dirección legible
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
              initialCenter: widget.initialLat != null && widget.initialLng != null
                  ? LatLng(widget.initialLat!, widget.initialLng!)
                  : _center,
              initialZoom: 13,
              onTap: (tapPos, latlng) async {
                // 🆕 Obtener dirección desde coordenadas
                await _getAddressFromCoordinates(latlng);
                setState(() {
                  _picked = latlng;
                });
                // Center map on the picked point and show feedback
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  try {
                    _mapController.move(latlng, 15);
                  } catch (_) {}
                });
              },
              onLongPress: (tapPos, latlng) async {
                // 🆕 Obtener dirección desde coordenadas
                await _getAddressFromCoordinates(latlng);
                setState(() {
                  _picked = latlng;
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  try {
                    _mapController.move(latlng, 15);
                  } catch (_) {}
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
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
          // 🆕 Card con dirección legible en la parte inferior
          Positioned(
            left: 16,
            right: 16,
            bottom: 100,
            child: _picked == null
                ? _buildAddressCardImproved(
                    '📍 Toca en el mapa para seleccionar una ubicación',
                    Colors.grey[100]!,
                    Colors.grey,
                  )
                : _isLoadingAddress
                    ? _buildAddressCardImproved(
                        'Buscando dirección...',
                        Colors.amber[50]!,
                        Colors.amber,
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildAddressCardImproved(
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
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 4,
                                shadowColor: const Color(0xFFE91E63).withOpacity(0.5),
                              ),
                              onPressed: () {
                                Navigator.pop(context, {
                                  'lat': _picked!.latitude,
                                  'lng': _picked!.longitude,
                                  'address': _pickedAddress ?? 'Ubicación no disponible',
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

  /// 🆕 Widget mejorado para mostrar la dirección
  Widget _buildAddressCardImproved(String address, Color bgColor, Color? accentColor) {
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
          // Etiqueta superior
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
          // Dirección principal
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
          // Coordenadas (opcional)
          if (_picked != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    '${_picked!.latitude.toStringAsFixed(5)}, ${_picked!.longitude.toStringAsFixed(5)}',
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

  /// 🆕 Widget para mostrar la dirección de forma legible (anterior)
  Widget _buildAddressCard(String address, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Dirección:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            address,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (_picked != null) ...[
            const SizedBox(height: 8),
            Text(
              'Coordenadas: ${_picked!.latitude.toStringAsFixed(5)}, ${_picked!.longitude.toStringAsFixed(5)}',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ]
        ],
      ),
    );
  }

  /// 🆕 Función para obtener dirección desde coordenadas usando Nominatim API
  Future<void> _getAddressFromCoordinates(LatLng latlng) async {
    setState(() => _isLoadingAddress = true);
    try {
      // Usar Nominatim API (OpenStreetMap) - Gratuito y confiable
      final url = 'https://nominatim.openstreetmap.org/reverse'
          '?format=json'
          '&lat=${latlng.latitude}'
          '&lon=${latlng.longitude}'
          '&zoom=18'
          '&addressdetails=1';

      print('🌐 Consultando Nominatim: $url');

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout en geocoding'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = _parseJson(response.body);
        
        print('📍 Respuesta Nominatim:');
        print('  - address: ${data['address']}');
        print('  - display_name: ${data['display_name']}');

        // Extraer componentes de dirección
        final address = data['address'] as Map<String, dynamic>? ?? {};
        final parts = <String>[];

        // Orden de prioridad para mostrar
        // 1. Nombre de ruta (calle/avenida)
        if (address['road']?.isNotEmpty ?? false) {
          parts.add(address['road']);
        } else if (address['street']?.isNotEmpty ?? false) {
          parts.add(address['street']);
        } else if (address['hamlet']?.isNotEmpty ?? false) {
          parts.add(address['hamlet']);
        }

        // 2. Número de casa
        if (address['house_number']?.isNotEmpty ?? false) {
          if (parts.isNotEmpty) {
            parts[0] = '${parts[0]} ${address['house_number']}';
          }
        }

        // 3. Barrio/Municipio
        if (address['suburb']?.isNotEmpty ?? false) {
          parts.add(address['suburb']);
        } else if (address['village']?.isNotEmpty ?? false) {
          parts.add(address['village']);
        } else if (address['town']?.isNotEmpty ?? false) {
          parts.add(address['town']);
        }

        // 4. Ciudad
        if (address['city']?.isNotEmpty ?? false) {
          parts.add(address['city']);
        } else if (address['municipality']?.isNotEmpty ?? false) {
          parts.add(address['municipality']);
        }

        // 5. Provincia/Estado
        if (address['state']?.isNotEmpty ?? false) {
          parts.add(address['state']);
        }

        String finalAddress = parts.join(', ');

        // Si está vacío, usar el display_name completo
        if (finalAddress.isEmpty) {
          finalAddress = data['display_name'] ?? 
              'Ubicación: ${latlng.latitude.toStringAsFixed(5)}, ${latlng.longitude.toStringAsFixed(5)}';
        }

        setState(() {
          _pickedAddress = finalAddress;
          _isLoadingAddress = false;
        });

        print('✅ Dirección final: $_pickedAddress');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_pickedAddress!),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error en Nominatim: $e');
      setState(() {
        _pickedAddress = 'Ubicación: ${latlng.latitude.toStringAsFixed(5)}, ${latlng.longitude.toStringAsFixed(5)}';
        _isLoadingAddress = false;
      });
    }
  }

  /// Parse JSON de forma segura
  Map<String, dynamic> _parseJson(String jsonString) {
    try {
      // Simple JSON parser (sin import necesario)
      final start = jsonString.indexOf('{');
      final end = jsonString.lastIndexOf('}');
      if (start != -1 && end != -1) {
        final jsonStr = jsonString.substring(start, end + 1);
        // Para este caso, hacemos parse manual simple
        return _simpleJsonParse(jsonStr);
      }
      return {};
    } catch (e) {
      print('Error parseando JSON: $e');
      return {};
    }
  }

  /// Parse JSON simple sin dependencias
  Map<String, dynamic> _simpleJsonParse(String json) {
    final result = <String, dynamic>{};
    try {
      // Buscar "display_name"
      final displayNameRegex = RegExp(r'"display_name"\s*:\s*"([^"]+)"');
      final displayNameMatch = displayNameRegex.firstMatch(json);
      if (displayNameMatch != null) {
        result['display_name'] = displayNameMatch.group(1);
      }

      // Buscar "address" { ... }
      final addressStart = json.indexOf('"address"');
      if (addressStart != -1) {
        final addressBraceStart = json.indexOf('{', addressStart);
        int braceCount = 1;
        int i = addressBraceStart + 1;
        while (i < json.length && braceCount > 0) {
          if (json[i] == '{') braceCount++;
          if (json[i] == '}') braceCount--;
          i++;
        }
        final addressJson = json.substring(addressBraceStart, i);
        result['address'] = _parseAddressObject(addressJson);
      }
    } catch (e) {
      print('Error en parse simple: $e');
    }
    return result;
  }

  /// Parse del objeto address
  Map<String, dynamic> _parseAddressObject(String json) {
    final result = <String, dynamic>{};
    final fields = [
      'road', 'street', 'hamlet', 'house_number', 'suburb', 'village', 
      'town', 'city', 'municipality', 'state', 'country'
    ];

    for (final field in fields) {
      final regex = RegExp('"$field"\\s*:\\s*"([^"]+)"');
      final match = regex.firstMatch(json);
      if (match != null) {
        result[field] = match.group(1);
      }
    }
    return result;
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
      
      // 🆕 Obtener dirección desde tu ubicación actual
      await _getAddressFromCoordinates(latlng);
      
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
