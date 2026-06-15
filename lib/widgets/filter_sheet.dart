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
  final int? minBedrooms;
  final String orderBy;

  FilterSheetResult({
    required this.showProperties,
    required this.showSearches,
    required this.onlyMatches,
    required this.orderBy,
    this.radiusKm,
    this.priceMin,
    this.priceMax,
    this.minBedrooms,
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
  final String initialOrderBy;

  const FilterSheet({
    Key? key,
    required this.initialShowProperties,
    required this.initialShowSearches,
    required this.initialOnlyMatches,
    this.initialRadiusKm,
    this.initialPriceMin,
    this.initialPriceMax,
    this.initialMinBedrooms,
    this.initialOrderBy = 'recent',
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
    _orderBy = widget.initialOrderBy;
    final initBedrooms = widget.initialMinBedrooms;
    _minBedrooms =
        initBedrooms != null && initBedrooms >= 1 && initBedrooms <= 6
            ? initBedrooms
            : null;
  }

  Future<void> _saveAndClose() async {
    if (_priceMin != null && (_priceMin! <= 0 || _priceMin! > 9999)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El precio minimo debe estar entre 1 y 9999'),
        ),
      );
      return;
    }

    if (_priceMax != null && (_priceMax! <= 0 || _priceMax! > 9999)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El precio maximo debe estar entre 1 y 9999'),
        ),
      );
      return;
    }

    if (_priceMin != null && _priceMax != null && _priceMin! > _priceMax!) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El precio minimo no puede ser mayor al maximo'),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('map_show_properties', _showProperties);
    await prefs.setBool('map_show_searches', _showSearches);
    await prefs.setBool('map_filter_only_matches', _onlyMatches);

    if (_radiusKm != null) {
      await prefs.setDouble('map_filter_radius_km', _radiusKm!);
    } else {
      await prefs.remove('map_filter_radius_km');
    }

    if (_priceMin != null) {
      await prefs.setInt('map_filter_price_min', _priceMin!);
    } else {
      await prefs.remove('map_filter_price_min');
    }

    if (_priceMax != null) {
      await prefs.setInt('map_filter_price_max', _priceMax!);
    } else {
      await prefs.remove('map_filter_price_max');
    }

    if (_minBedrooms != null) {
      await prefs.setInt('map_filter_min_bedrooms', _minBedrooms!);
    } else {
      await prefs.remove('map_filter_min_bedrooms');
    }

    await prefs.setString('map_filter_order_by', _orderBy);

    if (!mounted) return;
    Navigator.of(context).pop(
      FilterSheetResult(
        showProperties: _showProperties,
        showSearches: _showSearches,
        onlyMatches: _onlyMatches,
        radiusKm: _radiusKm,
        priceMin: _priceMin,
        priceMax: _priceMax,
        minBedrooms: _minBedrooms,
        orderBy: _orderBy,
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
      filled: true,
      fillColor: const Color(0xFFF7F8FB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _filterTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAF0)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.25,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 360;
    final maxHeight = size.height * 0.88;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(compact ? 6 : 10),
        child: Container(
          constraints: BoxConstraints(maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9ECF2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 18,
            14,
            compact ? 12 : 18,
            16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filtros',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Ajusta lo que quieres ver en el mapa',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle('Contenido'),
                      _filterTile(
                        icon: Icons.apartment_rounded,
                        title: 'Mostrar propiedades',
                        value: _showProperties,
                        onChanged: (v) => setState(() => _showProperties = v),
                      ),
                      _filterTile(
                        icon: Icons.people_alt_rounded,
                        title: 'Mostrar búsquedas',
                        value: _showSearches,
                        onChanged: (v) => setState(() => _showSearches = v),
                      ),
                      _filterTile(
                        icon: Icons.favorite_rounded,
                        title: 'Solo mis matches',
                        subtitle:
                            'Muestra ubicaciones de usuarios con match mutuo.',
                        value: _onlyMatches,
                        onChanged: (v) => setState(() => _onlyMatches = v),
                      ),
                      const Divider(height: 26),
                      _sectionTitle('Rango y precio'),
                      TextFormField(
                        initialValue: _radiusKm?.toString(),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: _fieldDecoration(
                          hint: 'Radio en km, ej. 5',
                          icon: Icons.radar_rounded,
                        ),
                        onChanged: (v) =>
                            setState(() => _radiusKm = double.tryParse(v)),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final stackFields = constraints.maxWidth < 310;
                          final minField = _priceField(
                            label: 'Precio min',
                            hint: 'Min',
                            initialValue: _priceMin?.toString(),
                            onChanged: (v) => setState(
                              () => _priceMin = int.tryParse(v),
                            ),
                          );
                          final maxField = _priceField(
                            label: 'Precio max',
                            hint: 'Max',
                            initialValue: _priceMax?.toString(),
                            onChanged: (v) => setState(
                              () => _priceMax = int.tryParse(v),
                            ),
                          );

                          if (stackFields) {
                            return Column(
                              children: [
                                minField,
                                const SizedBox(height: 12),
                                maxField,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(child: minField),
                              const SizedBox(width: 12),
                              Expanded(child: maxField),
                            ],
                          );
                        },
                      ),
                      const Divider(height: 28),
                      _sectionTitle('Orden y habitaciones'),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Habitaciones min',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _dropdownShell(
                                  child: DropdownButton<int?>(
                                    value: _minBedrooms,
                                    hint: const Text('Todas'),
                                    isExpanded: true,
                                    underline: const SizedBox.shrink(),
                                    items: [
                                      const DropdownMenuItem<int?>(
                                        value: null,
                                        child: Text('Todas'),
                                      ),
                                      ...List.generate(6, (i) => i + 1).map(
                                        (n) => DropdownMenuItem<int?>(
                                          value: n,
                                          child: Text('$n+'),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) =>
                                        setState(() => _minBedrooms = v),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ordenar por',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _dropdownShell(
                                  child: DropdownButton<String>(
                                    value: _orderBy,
                                    isExpanded: true,
                                    underline: const SizedBox.shrink(),
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'recent',
                                        child: Text('Mas recientes'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'price_asc',
                                        child: Text('Precio ↑'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'price_desc',
                                        child: Text('Precio ↓'),
                                      ),
                                    ],
                                    onChanged: (v) => setState(
                                      () => _orderBy = v ?? 'recent',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: AppColors.primary.withOpacity(0.28),
                          width: 1.3,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveAndClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Aplicar',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceField({
    required String label,
    required String hint,
    required String? initialValue,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue,
          keyboardType: TextInputType.number,
          decoration: _fieldDecoration(
            hint: hint,
            icon: Icons.attach_money_rounded,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _dropdownShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }
}
