import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';

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
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20)],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Filtros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SwitchListTile(
                value: _showProperties,
                title: const Text('Mostrar propiedades'),
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _showProperties = v),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                value: _showSearches,
                title: const Text('Mostrar búsquedas'),
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _showSearches = v),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                value: _onlyMatches,
                title: const Text('Solo mis matches'),
                subtitle: const Text('Mostrar solo ubicaciones de usuarios con match mutuo'),
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _onlyMatches = v),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: Text('Radio (km):', style: TextStyle(color: AppColors.textSecondary))),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    initialValue: _radiusKm?.toString(),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(hintText: 'ej. 5', filled: true, fillColor: AppColors.inputFill, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                    onChanged: (v) => setState(() => _radiusKm = double.tryParse(v)),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Precio min', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue: _priceMin?.toString(),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(hintText: 'Min', filled: true, fillColor: AppColors.inputFill, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                      onChanged: (v) => setState(() => _priceMin = int.tryParse(v)),
                    ),
                  ]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Precio max', style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      initialValue: _priceMax?.toString(),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(hintText: 'Max', filled: true, fillColor: AppColors.inputFill, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                      onChanged: (v) => setState(() => _priceMax = int.tryParse(v)),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Habitaciones min:', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(8)),
                    child: DropdownButton<int>(
                      value: _minBedrooms,
                      hint: const Text('1+'),
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: List.generate(6, (i) => i+1).map((n) => DropdownMenuItem(value: n, child: Text(n.toString()))).toList(),
                      onChanged: (v) => setState(() => _minBedrooms = v),
                    ),
                  ),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Ordenar por:', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(8)),
                    child: DropdownButton<String>(
                      value: _orderBy,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(value: 'recent', child: Text('Más recientes')),
                        DropdownMenuItem(value: 'price_asc', child: Text('Precio ↑')),
                        DropdownMenuItem(value: 'price_desc', child: Text('Precio ↓')),
                      ],
                      onChanged: (v) => setState(() => _orderBy = v ?? 'recent'),
                    ),
                  ),
                ])),
              ]),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.primary.withOpacity(0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: Text('Cancelar', style: TextStyle(color: AppColors.primary)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saveAndClose,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), foregroundColor: Colors.white),
                    child: const Padding(padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: Text('Aplicar')),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
