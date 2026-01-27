import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FilterSheetResult {
  final bool showProperties;
  final bool showSearches;
  final bool onlyMatches;
  final double? radiusKm;
  final int? priceMin;
  final int? priceMax;

  FilterSheetResult({
    required this.showProperties,
    required this.showSearches,
    required this.onlyMatches,
    this.radiusKm,
    this.priceMin,
    this.priceMax,
  });
}

class FilterSheet extends StatefulWidget {
  final bool initialShowProperties;
  final bool initialShowSearches;
  final bool initialOnlyMatches;
  final double? initialRadiusKm;
  final int? initialPriceMin;
  final int? initialPriceMax;
  final int? initialMinBedrooms;

  const FilterSheet({
    Key? key,
    required this.initialShowProperties,
    required this.initialShowSearches,
    required this.initialOnlyMatches,
    this.initialRadiusKm,
    this.initialPriceMin,
    this.initialPriceMax,
    this.initialMinBedrooms,
  }) : super(key: key);

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late bool _showProperties;
  late bool _showSearches;
  late bool _onlyMatches;
  double? _radiusKm;
  int? _priceMin;
  int? _priceMax;
  int? _minBedrooms;
  String _orderBy = 'recent';

  @override
  void initState() {
    super.initState();
    _showProperties = widget.initialShowProperties;
    _showSearches = widget.initialShowSearches;
    _onlyMatches = widget.initialOnlyMatches;
    _radiusKm = widget.initialRadiusKm;
    _priceMin = widget.initialPriceMin;
    _priceMax = widget.initialPriceMax;
    // initialize min bedrooms from a dedicated field when provided
    final int? initBedrooms = widget.initialMinBedrooms;
    if (initBedrooms != null && initBedrooms >= 1 && initBedrooms <= 6) {
      _minBedrooms = initBedrooms;
    } else {
      _minBedrooms = null;
    }
    _orderBy = 'recent';
  }

  Future<void> _saveAndClose() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('map_filter_show_properties', _showProperties);
    await prefs.setBool('map_filter_show_searches', _showSearches);
    await prefs.setBool('map_filter_only_matches', _onlyMatches);
    if (_radiusKm != null) {
      await prefs.setDouble('map_filter_radius_km', _radiusKm!);
    } else {
      await prefs.remove('map_filter_radius_km');
    }
    if (_priceMin != null) await prefs.setInt('map_filter_price_min', _priceMin!); else await prefs.remove('map_filter_price_min');
    if (_priceMax != null) await prefs.setInt('map_filter_price_max', _priceMax!); else await prefs.remove('map_filter_price_max');
    if (_minBedrooms != null) await prefs.setInt('map_filter_min_bedrooms', _minBedrooms!); else await prefs.remove('map_filter_min_bedrooms');
    await prefs.setString('map_filter_order_by', _orderBy);

    Navigator.of(context).pop(FilterSheetResult(
      showProperties: _showProperties,
      showSearches: _showSearches,
      onlyMatches: _onlyMatches,
      radiusKm: _radiusKm,
      priceMin: _priceMin,
      priceMax: _priceMax,
      // Note: bedrooms and ordering will be retrieved from SharedPreferences by the caller
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filtros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _showProperties,
              title: const Text('Mostrar propiedades'),
              onChanged: (v) => setState(() => _showProperties = v),
            ),
            SwitchListTile(
              value: _showSearches,
              title: const Text('Mostrar búsquedas'),
              onChanged: (v) => setState(() => _showSearches = v),
            ),
            SwitchListTile(
              value: _onlyMatches,
              title: const Text('Solo mis matches'),
              subtitle: const Text('Mostrar solo ubicaciones de usuarios con match mutuo'),
              onChanged: (v) => setState(() => _onlyMatches = v),
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Text('Radio (km):'),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: _radiusKm?.toString(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(hintText: 'ej. 5'),
                  onChanged: (v) => setState(() => _radiusKm = double.tryParse(v)),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Text('Precio min:'),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: _priceMin?.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Min'),
                  onChanged: (v) => setState(() => _priceMin = int.tryParse(v)),
                ),
              ),
              const SizedBox(width: 12),
              const Text('max:'),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: _priceMax?.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Max'),
                  onChanged: (v) => setState(() => _priceMax = int.tryParse(v)),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Text('Habitaciones min:'),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _minBedrooms,
                hint: const Text('1+'),
                items: List.generate(6, (i) => i+1).map((n) => DropdownMenuItem(value: n, child: Text(n.toString()))).toList(),
                onChanged: (v) => setState(() => _minBedrooms = v),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              const Text('Ordenar por:'),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _orderBy,
                items: const [
                  DropdownMenuItem(value: 'recent', child: Text('Más recientes')),
                  DropdownMenuItem(value: 'price_asc', child: Text('Precio ↑')),
                  DropdownMenuItem(value: 'price_desc', child: Text('Precio ↓')),
                ],
                onChanged: (v) => setState(() => _orderBy = v ?? 'recent'),
              ),
            ]),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _saveAndClose, child: const Text('Aplicar')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
