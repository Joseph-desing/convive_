import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/filter_sheet.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
// Removed cluster package usage for v7 compatibility; using simple MarkerLayer
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../models/property.dart';
import '../models/roommate_search.dart';
import '../config/supabase_provider.dart';
import '../utils/colors.dart';
import 'map_property_preview_screen.dart';
import 'map_roommate_preview_screen.dart';

class MapPostsScreen extends StatefulWidget {
  final LatLng? initialLocation;
  final Property? singleProperty;
  final RoommateSearch? singleRoommate;

  const MapPostsScreen({
    Key? key,
    this.initialLocation,
    this.singleProperty,
    this.singleRoommate,
  }) : super(key: key);

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

  bool _isValidLatLng(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (lat == 0 && lng == 0) return false;
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  LatLng _fallbackCenter() => LatLng(-0.180653, -78.467834);

  LatLng _initialMapCenter() {
    if (widget.initialLocation != null) return widget.initialLocation!;

    for (final p in _properties) {
      if (_isValidLatLng(p.latitude, p.longitude)) {
        return LatLng(p.latitude, p.longitude);
      }
    }

    for (final s in _searches) {
      if (_isValidLatLng(s.latitude, s.longitude)) {
        return LatLng(s.latitude!, s.longitude!);
      }
      final key = s.id ?? s.address;
      final cached = _geocodeCache[key];
      if (cached != null && _isValidLatLng(cached.latitude, cached.longitude)) {
        return cached;
      }
    }

    return _fallbackCenter();
  }

  @override
  void initState() {
    super.initState();
    _loadLocalGeocodeCache().then((_) async {
      // Si se pasa una propiedad o compañero específico, mostrar solo ese
      if (widget.singleProperty != null) {
        setState(() {
          _properties = [widget.singleProperty!];
          _searches = [];
          _showProperties = true;
          _showSearches = false;
          _loading = false;
        });
        // Centrar en esa propiedad
        final lat = widget.singleProperty!.latitude;
        final lng = widget.singleProperty!.longitude;
        if (_isValidLatLng(lat, lng)) {
          _mapController.move(LatLng(lat, lng), 15);
        }
      } else if (widget.singleRoommate != null) {
        setState(() {
          _properties = [];
          _searches = [widget.singleRoommate!];
          _showProperties = false;
          _showSearches = true;
          _loading = false;
        });
        // Centrar en esa búsqueda de compañero
        final lat = widget.singleRoommate!.latitude;
        final lng = widget.singleRoommate!.longitude;
        if (_isValidLatLng(lat, lng)) {
          _mapController.move(LatLng(lat!, lng!), 15);
        }
      } else {
        // Cargar todos los datos normalmente
        await _loadData();
        _subscribeToRealtimeChanges();
      }
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
      LatLng center = _currentMapCenter ?? _initialMapCenter();
      final dist = Distance();

      if (partnerIds != null) {
        searches = searches.where((s) => partnerIds!.contains(s.userId)).toList();
        props = props.where((p) => partnerIds!.contains(p.ownerId)).toList();
      }

      if (_filterRadiusKm != null) {
        searches = searches.where((s) {
          final lat = s.latitude;
          final lng = s.longitude;
          if (!_isValidLatLng(lat, lng)) return false;
          final dkm =
              dist.as(LengthUnit.Kilometer, center, LatLng(lat!, lng!));
          return dkm <= _filterRadiusKm!;
        }).toList();
        props = props.where((p) {
          if (!_isValidLatLng(p.latitude, p.longitude)) return false;
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
    final initialCenter = _initialMapCenter();
    final summaryTop = MediaQuery.of(context).padding.top + kToolbarHeight + 12;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        titleSpacing: 0,
        title: const Text(
          'Mapa de publicaciones',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        backgroundColor: Colors.white.withOpacity(0.94),
        foregroundColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.tune_rounded),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary.withOpacity(0.08),
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final result = await showModalBottomSheet<FilterSheetResult>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
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
            ),
          ),
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
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.convive',
                      tileProvider: CancellableNetworkTileProvider(),
                    ),
                    // Simple marker layer (cluster removed for compatibility)
                    MarkerLayer(markers: _buildMarkers()),
                  ],
                ),

                Positioned(
                  left: 14,
                  right: 14,
                  top: summaryTop,
                  child: _buildMapSummary(),
                ),
              ],
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.my_location_rounded),
          onPressed: _centerOnUser,
        ),
      ),
    );
  }

  Widget _buildMapSummary() {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MapSummaryButton(
              icon: Icons.home_rounded,
              label: '${_showProperties ? _properties.length : 0}',
              caption: 'Propiedades',
              color: Colors.red,
              active: _showProperties,
              onTap: () async {
                setState(() => _showProperties = !_showProperties);
                await _saveLocalGeocodeCache();
              },
            ),
            const SizedBox(height: 6),
            _MapSummaryButton(
              icon: Icons.person_pin_circle_rounded,
              label: '${_showSearches ? _searches.length : 0}',
              caption: 'Busquedas',
              color: Colors.blue,
              active: _showSearches,
              onTap: () async {
                setState(() => _showSearches = !_showSearches);
                await _saveLocalGeocodeCache();
              },
            ),
          ],
        ),
      ),
    );
  }

  /*
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
  */

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
        if (!_isValidLatLng(p.latitude, p.longitude)) continue;
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
        if (_isValidLatLng(s.latitude, s.longitude)) {
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
          if (!_isValidLatLng(pos.latitude, pos.longitude)) continue;
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

  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 44,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E3E7),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }

  Widget _sheetHeader({
    required IconData icon,
    required String label,
    required String title,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sheetLocation({
    required String address,
    required String coordinates,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE7EAF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address.isNotEmpty ? address : 'Ubicación seleccionada',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  coordinates,
                  style: const TextStyle(
                    color: Color(0xFF7B8494),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetActions({
    required BuildContext sheetContext,
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onOpen,
  }) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onOpen,
              icon: Icon(icon, size: 19),
              label: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 52,
          height: 52,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(sheetContext),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF4B5563),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE0E4EA)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: EdgeInsets.zero,
            ),
            child: const Icon(Icons.close_rounded, size: 22),
          ),
        ),
      ],
    );
  }

  String _genderLabel(String? value) {
    switch ((value ?? '').toLowerCase().trim()) {
      case 'male':
      case 'hombre':
        return 'Hombre';
      case 'female':
      case 'mujer':
        return 'Mujer';
      case 'any':
      case 'sin preferencia':
        return 'Sin preferencia';
      default:
        return 'Sin preferencia';
    }
  }

  void _openPropertyBottomSheet(Property p) {
    const color = Color(0xFFE91E63);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF7FA),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(),
                const SizedBox(height: 18),
                _sheetHeader(
                  icon: Icons.home_rounded,
                  label: 'Departamento',
                  title: p.title,
                  color: color,
                ),
                const SizedBox(height: 16),
                _sheetLocation(
                  address: p.address,
                  coordinates:
                      'Lat: ${p.latitude.toStringAsFixed(5)}, Lng: ${p.longitude.toStringAsFixed(5)}',
                  color: color,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _sheetChip(
                      icon: Icons.attach_money_rounded,
                      label: '\$${p.price.toStringAsFixed(0)}/mes',
                      color: color,
                    ),
                    _sheetChip(
                      icon: Icons.bed_rounded,
                      label: '${p.bedrooms} hab',
                      color: const Color(0xFF2563EB),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _sheetActions(
                  sheetContext: sheetContext,
                  color: color,
                  icon: Icons.visibility_rounded,
                  label: 'Ver publicación',
                  onOpen: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (BuildContext ctx) =>
                            MapPropertyPreviewScreen(property: p),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openSearchBottomSheet(RoommateSearch s) {
    const color = Color(0xFFFF9800);
    final lat = s.latitude;
    final lng = s.longitude;
    final coordinates = lat != null && lng != null
        ? 'Lat: ${lat.toStringAsFixed(5)}, Lng: ${lng.toStringAsFixed(5)}'
        : 'Ubicación aproximada';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFBF3),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(),
                const SizedBox(height: 18),
                _sheetHeader(
                  icon: Icons.person_pin_circle_rounded,
                  label: 'Busqueda de roomie',
                  title: s.title,
                  color: color,
                ),
                const SizedBox(height: 16),
                _sheetLocation(
                  address: s.address,
                  coordinates: coordinates,
                  color: color,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _sheetChip(
                      icon: Icons.attach_money_rounded,
                      label: '\$${s.budget.toStringAsFixed(0)}/mes',
                      color: color,
                    ),
                    _sheetChip(
                      icon: Icons.person_rounded,
                      label: _genderLabel(s.genderPreference),
                      color: const Color(0xFFE91E63),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _sheetActions(
                  sheetContext: sheetContext,
                  color: color,
                  icon: Icons.person_search_rounded,
                  label: 'Ver búsqueda',
                  onOpen: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (BuildContext ctx) =>
                            MapRoommatePreviewScreen(search: s),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MapSummaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String caption;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _MapSummaryButton({
    required this.icon,
    required this.label,
    required this.caption,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = active ? color : Colors.grey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 116,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        decoration: BoxDecoration(
          color: active ? effectiveColor.withOpacity(0.08) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? effectiveColor.withOpacity(0.20)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: effectiveColor.withOpacity(active ? 0.14 : 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: effectiveColor, size: 17),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: active ? const Color(0xFF1F2937) : Colors.grey,
                    ),
                  ),
                  Text(
                    caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.grey[600] : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
