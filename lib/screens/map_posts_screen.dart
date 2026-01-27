import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/filter_sheet.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// Removed cluster package usage for v7 compatibility; using simple MarkerLayer
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/property.dart';
import '../models/roommate_search.dart';
import '../config/supabase_provider.dart';
import '../utils/colors.dart';
import 'create_property_screen.dart';
import 'create_roommate_search_screen.dart';
import 'user_profile_screen.dart';
import 'property_details_screen.dart';
import 'user_profile_screen.dart';

class MapPostsScreen extends StatefulWidget {
  const MapPostsScreen({Key? key}) : super(key: key);

  @override
  State<MapPostsScreen> createState() => _MapPostsScreenState();
}

class _MapPostsScreenState extends State<MapPostsScreen> {
  bool _loading = true;
  List<Property> _properties = [];
  List<RoommateSearch> _searches = [];
  final Map<String, LatLng> _geocodeCache = {};
  final MapController _mapController = MapController();
  RealtimeChannel? _roommateChannel;
  RealtimeChannel? _propertiesChannel;
  bool _showProperties = true;
  bool _showSearches = true;
  bool _filterOnlyMatches = false;
  double? _filterRadiusKm;
  int? _filterPriceMin;
  int? _filterPriceMax;
  int? _filterMinBedrooms;
  String _filterOrderBy = 'recent';
  LatLng? _currentMapCenter;

  @override
  void initState() {
    super.initState();
    _loadLocalGeocodeCache().then((_) async {
      await _loadData();
      _subscribeToRealtimeChanges();
    });
  }

  void _subscribeToRealtimeChanges() {
    try {
      // Subscribe to changes in roommate_searches
      _roommateChannel = SupabaseProvider.client
          .channel('roommate_searches_channel')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'roommate_searches',
            callback: (payload) {
              // Reload data when roommate searches change (insert/update/delete)
              if (mounted) _loadData();
            },
          )
          .subscribe();

      // Subscribe to changes in properties
      _propertiesChannel = SupabaseProvider.client
          .channel('properties_channel')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'properties',
            callback: (payload) {
              if (mounted) _loadData();
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('No se pudo subscribir a realtime: $e');
    }
  }

  Future<void> _loadLocalGeocodeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('geocode_cache') ?? '{}';
      final Map<String, dynamic> decoded = json.decode(raw) as Map<String, dynamic>;
      decoded.forEach((key, value) {
        try {
          final lat = (value['lat'] as num).toDouble();
          final lng = (value['lng'] as num).toDouble();
          _geocodeCache[key] = LatLng(lat, lng);
        } catch (_) {}
      });
      // load saved filters
      _showProperties = prefs.getBool('map_show_properties') ?? true;
      _showSearches = prefs.getBool('map_show_searches') ?? true;
      _filterOnlyMatches = prefs.getBool('map_filter_only_matches') ?? false;
      _filterRadiusKm = prefs.getDouble('map_filter_radius_km');
      _filterPriceMin = prefs.getInt('map_filter_price_min');
      _filterPriceMax = prefs.getInt('map_filter_price_max');
      _filterMinBedrooms = prefs.getInt('map_filter_min_bedrooms');
      _filterOrderBy = prefs.getString('map_filter_order_by') ?? 'recent';
    } catch (e) {
      debugPrint('No se pudo cargar cache local de geocoding: $e');
    }
  }

  Future<void> _saveLocalGeocodeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String, Map<String, double>>{};
      _geocodeCache.forEach((key, val) {
        map[key] = {'lat': val.latitude, 'lng': val.longitude};
      });
      await prefs.setString('geocode_cache', json.encode(map));
      await prefs.setBool('map_show_properties', _showProperties);
      await prefs.setBool('map_show_searches', _showSearches);
      await prefs.setBool('map_filter_only_matches', _filterOnlyMatches);
      if (_filterRadiusKm != null) await prefs.setDouble('map_filter_radius_km', _filterRadiusKm!); else await prefs.remove('map_filter_radius_km');
      if (_filterPriceMin != null) await prefs.setInt('map_filter_price_min', _filterPriceMin!); else await prefs.remove('map_filter_price_min');
      if (_filterPriceMax != null) await prefs.setInt('map_filter_price_max', _filterPriceMax!); else await prefs.remove('map_filter_price_max');
    } catch (e) {
      debugPrint('No se pudo guardar cache local de geocoding: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final currentUserId = SupabaseProvider.client.auth.currentUser?.id;
      // Cargar propiedades activas (excluir las del usuario actual)
      var props = await SupabaseProvider.databaseService.getProperties(limit: 200, offset: 0, excludeUserId: currentUserId);

      // Cargar roommate searches activas
      final response = await SupabaseProvider.client
          .from('roommate_searches')
          .select()
          .eq('status', 'active');

      var searches = (response as List)
          .map((d) => RoommateSearch.fromJson(Map<String, dynamic>.from(d)))
          .toList();

      // Apply client-side filters
      // onlyMatches: fetch matches and build partner set
      Set<String>? partnerIds;
      if (_filterOnlyMatches && currentUserId != null) {
        final matches = await SupabaseProvider.databaseService.getUserMatches(currentUserId);
        partnerIds = <String>{};
        for (final m in matches) {
          if (m.userA == currentUserId) partnerIds.add(m.userB); else partnerIds.add(m.userA);
        }
      }

      // radius filtering: use current map center if available (track via onPositionChanged)
      LatLng center = _currentMapCenter ?? (_properties.isNotEmpty ? LatLng(_properties.first.latitude, _properties.first.longitude) : LatLng(-0.180653, -78.467834));
      final dist = Distance();

      if (partnerIds != null) {
        searches = searches.where((s) => partnerIds!.contains(s.userId)).toList();
        props = props.where((p) => partnerIds!.contains(p.ownerId)).toList();
      }

      if (_filterRadiusKm != null) {
        searches = searches.where((s) {
          final lat = s.latitude;
          final lng = s.longitude;
          if (lat == null || lng == null) return false;
          final dkm = dist.as(LengthUnit.Kilometer, center, LatLng(lat, lng));
          return dkm <= _filterRadiusKm!;
        }).toList();
        props = props.where((p) {
          final dkm = dist.as(LengthUnit.Kilometer, center, LatLng(p.latitude, p.longitude));
          return dkm <= _filterRadiusKm!;
        }).toList();
      }

      if (_filterPriceMin != null) {
        props = props.where((p) => p.price >= _filterPriceMin!).toList();
        searches = searches.where((s) => s.budget >= _filterPriceMin!).toList();
      }
      if (_filterPriceMax != null) {
        props = props.where((p) => p.price <= _filterPriceMax!).toList();
        searches = searches.where((s) => s.budget <= _filterPriceMax!).toList();
      }
      if (_filterMinBedrooms != null) {
        try {
          props = props.where((p) => p.bedrooms >= _filterMinBedrooms!).toList();
        } catch (_) {}
      }

      // Ordering
      switch (_filterOrderBy) {
        case 'price_asc':
          props.sort((a,b) => a.price.compareTo(b.price));
          break;
        case 'price_desc':
          props.sort((a,b) => b.price.compareTo(a.price));
          break;
        case 'recent':
        default:
          props.sort((a,b) => b.createdAt.compareTo(a.createdAt));
      }

      setState(() {
        _properties = props;
        _searches = searches;
      });

      // Geocodificar direcciones de roommate searches (si no tienen lat/lng)
      for (final s in _searches) {
        if ((s.latitude == null || s.longitude == null) && s.address.isNotEmpty) {
          await _maybeGeocodeSearch(s);
        }
      }
    } catch (e) {
      debugPrint('Error cargando datos de mapa: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _maybeGeocodeSearch(RoommateSearch s) async {
    final key = s.id ?? s.address;
    if (_geocodeCache.containsKey(key)) return;
    // Nominatim does not allow cross-origin requests from browsers (CORS).
    // Avoid calling it directly when running on the web; use a server-side
    // proxy / edge function or precomputed coordinates instead.
    if (kIsWeb) {
      debugPrint('Skipping geocoding on web for "$key" (CORS). Use server-side proxy).');
      return;
    }
    try {
      final coords = await _geocodeAddress(s.address);
      if (coords != null) {
        _geocodeCache[key] = coords;
        await _saveLocalGeocodeCache();
      }
    } catch (e) {
      // ignore
    }
  }

  Future<LatLng?> _geocodeAddress(String address) async {
    final q = Uri.encodeComponent(address);
    final url = 'https://nominatim.openstreetmap.org/search?format=json&q=$q&limit=1';
    final resp = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'ConviveApp/1.0 (contact@convive.example)'
    });
    if (resp.statusCode != 200) return null;
    final body = json.decode(resp.body) as List;
    if (body.isEmpty) return null;
    final first = body.first as Map<String, dynamic>;
    final lat = double.tryParse(first['lat']?.toString() ?? '');
    final lon = double.tryParse(first['lon']?.toString() ?? '');
    if (lat == null || lon == null) return null;
    return LatLng(lat, lon);
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _properties.isNotEmpty
        ? LatLng(_properties.first.latitude, _properties.first.longitude)
        : LatLng(-0.180653, -78.467834); // Quito as fallback

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de publicaciones'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primary,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () async {
              final result = await showModalBottomSheet<FilterSheetResult>(
                context: context,
                isScrollControlled: true,
                builder: (_) => FilterSheet(
                  initialShowProperties: _showProperties,
                  initialShowSearches: _showSearches,
                  initialOnlyMatches: _filterOnlyMatches,
                  initialRadiusKm: _filterRadiusKm,
                  initialPriceMin: _filterPriceMin,
                  initialPriceMax: _filterPriceMax,
                    initialMinBedrooms: _filterMinBedrooms,
                ),
              );
              if (result != null) {
                setState(() {
                  _showProperties = result.showProperties;
                  _showSearches = result.showSearches;
                  _filterOnlyMatches = result.onlyMatches;
                  _filterRadiusKm = result.radiusKm;
                  _filterPriceMin = result.priceMin;
                  _filterPriceMax = result.priceMax;
                });
                await _saveLocalGeocodeCache();
                await _loadData();
              }
            },
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: 12,
                    onPositionChanged: (pos, _) {
                      try {
                        final c = pos.center;
                        if (c != null) {
                          setState(() => _currentMapCenter = LatLng(c.latitude, c.longitude));
                        }
                      } catch (_) {}
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c'],
                      userAgentPackageName: 'com.example.convive',
                    ),
                    // Simple marker layer (cluster removed for compatibility)
                    MarkerLayer(markers: _buildMarkers()),
                  ],
                ),

                // Leyenda / conteo y filtros en esquina superior derecha
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                setState(() => _showProperties = !_showProperties);
                                await _saveLocalGeocodeCache();
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.home, color: _showProperties ? Colors.red : Colors.grey, size: 18),
                                  const SizedBox(width: 8),
                                  Text('${_showProperties ? _properties.length : 0} propiedades', style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () async {
                                setState(() => _showSearches = !_showSearches);
                                await _saveLocalGeocodeCache();
                              },
                              child: Row(
                                children: [
                                  Icon(Icons.person_pin_circle, color: _showSearches ? Colors.blue : Colors.grey, size: 18),
                                  const SizedBox(width: 8),
                                  Text('${_showSearches ? _searches.length : 0} búsquedas', style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.my_location),
        onPressed: _centerOnUser,
      ),
    );
  }

  @override
  void dispose() {
    try {
      if (_roommateChannel != null) {
        SupabaseProvider.client.removeChannel(_roommateChannel!);
        _roommateChannel = null;
      }
      if (_propertiesChannel != null) {
        SupabaseProvider.client.removeChannel(_propertiesChannel!);
        _propertiesChannel = null;
      }
    } catch (e) {}
    super.dispose();
  }

  Future<void> _centerOnUser() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final req = await Geolocator.requestPermission();
        if (req == LocationPermission.denied || req == LocationPermission.deniedForever) return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      final latlng = LatLng(pos.latitude, pos.longitude);
      // Ensure the FlutterMap has been laid out before moving the controller
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.move(latlng, 14);
        } catch (e) {
          debugPrint('MapController not ready: $e');
        }
      });
    } catch (e) {
      debugPrint('No se pudo obtener ubicación: $e');
    }
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Propiedades (rojo con icono de casa)
    if (_showProperties) {
      for (final p in _properties) {
        markers.add(
          Marker(
            width: 48,
            height: 48,
            point: LatLng(p.latitude, p.longitude),
            child: GestureDetector(
              onTap: () => _openPropertyBottomSheet(p),
              child: const Icon(Icons.home, color: Colors.red, size: 30),
            ),
          ),
        );
      }
    }

    // Roommate searches: usar geocoded coords si están disponibles
    if (_showSearches) {
      for (final s in _searches) {
        // Preferir coordenadas guardadas en la búsqueda
        if (s.latitude != null && s.longitude != null) {
          final pos = LatLng(s.latitude!, s.longitude!);
          markers.add(
            Marker(
              width: 44,
              height: 44,
              point: pos,
              child: GestureDetector(
                onTap: () => _openSearchBottomSheet(s),
                child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 34),
              ),
            ),
          );
          continue;
        }

        final key = s.id ?? s.address;
        if (_geocodeCache.containsKey(key)) {
          final pos = _geocodeCache[key]!;
          markers.add(
            Marker(
              width: 44,
              height: 44,
              point: pos,
              child: GestureDetector(
                onTap: () => _openSearchBottomSheet(s),
                child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 34),
              ),
            ),
          );
        }
      }
    }

    return markers;
  }

  void _openPropertyBottomSheet(Property p) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(p.address),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Ir al detalle de la propiedad (solo lectura)
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(builder: (BuildContext ctx) => PropertyDetailsScreen(property: p)),
                    );
                  },
                  child: const Text('Ver publicación'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ],
        ),
      );
      },
    );
  }

  void _openSearchBottomSheet(RoommateSearch s) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(s.address),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Abrir perfil público del autor de la búsqueda
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(builder: (BuildContext ctx) => UserProfileScreen(userId: s.userId)),
                    );
                  },
                  child: const Text('Ver perfil'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ],
        ),
      );
      },
    );
  }
}
