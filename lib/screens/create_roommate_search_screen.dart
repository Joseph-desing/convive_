import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../utils/colors.dart';
import '../models/roommate_search.dart';

class CreateRoommateSearchScreen extends StatefulWidget {
  const CreateRoommateSearchScreen({Key? key}) : super(key: key);

  @override
  State<CreateRoommateSearchScreen> createState() =>
      _CreateRoommateSearchScreenState();
}

class _CreateRoommateSearchScreenState extends State<CreateRoommateSearchScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  // Controladores de formulario
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _addressController = TextEditingController();

  // Variables de selección
  String? _selectedGender;
  final List<String> _selectedHabits = [];
  final List<File> _selectedImages = [];

  // Listas de opciones
  final List<String> _genderOptions = [
    'Sin preferencia',
    'Hombre',
    'Mujer',
  ];

  final List<String> _habitOptions = [
    'Limpieza',
    'Silencioso',
    'Social',
    'Tranquilo',
    'Ordenado',
    'Responsable',
    'Respetuoso',
    'Madrugador',
    'Noctámbulo',
    'Amante de mascotas',
  ];

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildProgressIndicator(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1_BasicInfo(),
                    _buildStep2_Preferences(),
                    _buildStep3_Photos(),
                  ],
                ),
              ),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white.withOpacity(0.95),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                child: const Text(
                  'Buscar Roommate',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.close, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Publica que estás buscando roommate',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white.withOpacity(0.95),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressStep(1, 'Información'),
              _buildProgressStep(2, 'Preferencias'),
              _buildProgressStep(3, 'Fotos'),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_tabController.index + 1) / 3,
              minHeight: 4,
              backgroundColor: AppColors.borderColor,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String label) {
    final isActive = _tabController.index >= step - 1;
    final isCurrent = _tabController.index == step - 1;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCurrent
                ? AppColors.primary
                : isActive
                    ? AppColors.primary.withOpacity(0.3)
                    : AppColors.borderColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isCurrent ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isCurrent ? AppColors.primary : AppColors.textSecondary,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildStep1_BasicInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Título de tu búsqueda'),
          _buildTextField(
            controller: _titleController,
            hint: 'Ej: Busco roommate responsable para apto en La Mariscal',
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Cuéntanos más sobre ti'),
          _buildTextField(
            controller: _descriptionController,
            hint:
                'Soy estudiante universitario, busco alguien ordenado, tranquilo y responsable con los gastos compartidos...',
            maxLines: 5,
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Presupuesto mensual'),
          _buildTextField(
            controller: _budgetController,
            hint: 'Ej: 450',
            keyboardType: TextInputType.number,
            suffixText: '\$',
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Dónde necesitas roommate'),
          _buildTextField(
            controller: _addressController,
            hint: 'Ej: La Mariscal, Calle Pinto con Diego de Almagro',
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2_Preferences() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Género preferido del roommate'),
          _buildDropdown(
            hint: 'Selecciona una opción',
            value: _selectedGender,
            items: _genderOptions,
            onChanged: (value) {
              setState(() => _selectedGender = value);
            },
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('¿Qué características buscas?'),
          const Text(
            'Selecciona las características importantes para ti',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _buildCheckboxGrid(),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mientras más detalles des, mayor será tu compatibilidad',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primary.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3_Photos() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Agregar fotos'),
          const Text(
            'Las fotos te ayudarán a conseguir roommate más rápido',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _buildPhotoUpload(),
          const SizedBox(height: 20),
          if (_selectedImages.isNotEmpty) ...[
            _buildSectionTitle('Fotos seleccionadas (${_selectedImages.length})'),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb
                          ? Image.network(
                              _selectedImages[index].path,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.background,
                                  child: const Icon(Icons.image, size: 50),
                                );
                              },
                            )
                          : Image.file(
                              _selectedImages[index],
                              fit: BoxFit.cover,
                            ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImages.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhotoUpload() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.primary.withOpacity(0.05),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 48,
              color: AppColors.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'Toca para agregar fotos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Mínimo 1 foto, máximo 5',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _habitOptions.map((habit) {
        final isSelected = _selectedHabits.contains(habit);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedHabits.remove(habit);
              } else {
                _selectedHabits.add(habit);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.borderColor,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              habit,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? suffixText,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        suffixText: suffixText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      style: const TextStyle(color: AppColors.textPrimary),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        hint: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            hint,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        value: value,
        onChanged: onChanged,
        isExpanded: true,
        underline: const SizedBox(),
        items: items
            .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(item),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Colors.white.withOpacity(0.95),
      child: Row(
        children: [
          if (_tabController.index > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  _tabController.animateTo(_tabController.index - 1);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Anterior',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          if (_tabController.index > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _tabController.index == 2 ? 'Publicar' : 'Siguiente',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext() {
    if (_tabController.index < 2) {
      // Validar paso actual
      if (_tabController.index == 0) {
        if (_titleController.text.isEmpty) {
          _showSnackBar('Por favor completa el título');
          return;
        }
        if (_descriptionController.text.isEmpty) {
          _showSnackBar('Por favor cuéntanos más sobre ti');
          return;
        }
        if (_budgetController.text.isEmpty) {
          _showSnackBar('Por favor indica tu presupuesto');
          return;
        }
        if (_addressController.text.isEmpty) {
          _showSnackBar('Por favor indica tu dirección');
          return;
        }
      }

      if (_tabController.index == 1) {
        if (_selectedGender == null) {
          _showSnackBar('Por favor selecciona una preferencia de género');
          return;
        }
        if (_selectedHabits.isEmpty) {
          _showSnackBar('Por favor selecciona al menos una característica');
          return;
        }
      }

      _tabController.animateTo(_tabController.index + 1);
    } else {
      // Publicar
      _handlePublish();
    }
  }

  void _handlePublish() {
    if (_selectedImages.isEmpty) {
      _showSnackBar('Por favor agrega al menos una foto');
      return;
    }

    setState(() => _isLoading = true);

    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _isLoading = false);

      // Aquí irá la lógica para guardar en Supabase
      _showSnackBar('✅ ¡Tu búsqueda ha sido publicada!');

      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pop(context);
      });
    });
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      _showSnackBar('Máximo 5 fotos permitidas');
      return;
    }

    final List<XFile>? pickedFiles = await _imagePicker.pickMultiImage();

    if (pickedFiles != null) {
      setState(() {
        for (var file in pickedFiles) {
          if (_selectedImages.length < 5) {
            _selectedImages.add(File(file.path));
          }
        }
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        backgroundColor:
            message.startsWith('✅') ? Colors.green : Colors.orange,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
