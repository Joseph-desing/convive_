import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data';
import '../utils/colors.dart';
import '../config/supabase_provider.dart';
import '../models/index.dart';
import 'package:image_picker/image_picker.dart';

class CreatePropertyScreen extends StatefulWidget {
  final Property? property;

  const CreatePropertyScreen({Key? key, this.property}) : super(key: key);

  @override
  State<CreatePropertyScreen> createState() => _CreatePropertyScreenState();
}

class _CreatePropertyScreenState extends State<CreatePropertyScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  
  // Datos básicos
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  
  // Ubicación
  double? _latitude;
  double? _longitude;
  
  // Comodidades
  final List<String> _selectedAmenities = [];
  final List<String> _availableAmenities = [
    'WiFi',
    'Amueblado',
    'Cocina',
    'Lavadora',
    'Secadora',
    'Parqueadero',
    'Gimnasio',
    'Piscina',
    'Seguridad 24/7',
    'Mascotas OK',
    'Aire acondicionado',
    'Calefacción',
    'Balcón',
    'Terraza',
    'TV Cable',
  ];
  
  // Detalles
  int _bedrooms = 1;
  int _bathrooms = 1;
  bool _isActive = true;
  DateTime _availableFrom = DateTime.now();
  
  // Imágenes
  final List<XFile> _imageFiles = [];
  final List<String> _existingImageUrls = [];
  final List<String> _deletedImageUrls = [];
  final ImagePicker _picker = ImagePicker();
  
  bool _isLoading = false;
  bool _isLoadingImages = false;

  bool get _isEditing => widget.property != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final prop = widget.property!;
      _titleController.text = prop.title;
      _descriptionController.text = prop.description;
      _priceController.text = prop.price.toStringAsFixed(0);
      _addressController.text = prop.address;
      _availableFrom = prop.availableFrom;
      _latitude = prop.latitude;
      _longitude = prop.longitude;
      _isActive = prop.isActive;
      _loadExistingImages();
    }
  }

  Future<void> _loadExistingImages() async {
    setState(() => _isLoadingImages = true);
    try {
      final urls = await SupabaseProvider.databaseService
          .getPropertyImages(widget.property!.id);
      setState(() {
        _existingImageUrls.addAll(urls);
        _isLoadingImages = false;
      });
    } catch (e) {
      setState(() => _isLoadingImages = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.primaryGradient.createShader(bounds),
          child: Text(
            _isEditing ? 'Editar Propiedad' : 'Publicar Propiedad',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Paso ${_currentStep + 1}/3',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: _buildCurrentStep(),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: LinearProgressIndicator(
          value: (_currentStep + 1) / 3,
          minHeight: 6,
          backgroundColor: AppColors.background,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildBasicInfoStep();
      case 1:
        return _buildDetailsStep();
      case 2:
        return _buildPhotosStep();
      default:
        return Container();
    }
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Básica',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cuéntanos sobre tu propiedad',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            
            _buildTextField(
              controller: _titleController,
              label: 'Título del anuncio',
              hint: 'Ej: Habitación acogedora en La Carolina',
              icon: Icons.title,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa un título';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            _buildTextField(
              controller: _descriptionController,
              label: 'Descripción',
              hint: 'Describe tu propiedad, el barrio, qué estás buscando en un roommate...',
              icon: Icons.description_outlined,
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa una descripción';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            _buildTextField(
              controller: _priceController,
              label: 'Precio mensual (USD)',
              hint: '450',
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa el precio';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            _buildTextField(
              controller: _addressController,
              label: 'Dirección',
              hint: 'Av. Amazonas y Naciones Unidas, Quito',
              icon: Icons.location_on_outlined,
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingresa la dirección';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            _buildDateField(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalles de la Propiedad',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agrega más información sobre el espacio',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          
          Row(
            children: [
              Expanded(
                child: _buildCounter(
                  'Habitaciones',
                  _bedrooms,
                  Icons.bed_outlined,
                  (value) => setState(() => _bedrooms = value),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCounter(
                  'Baños',
                  _bathrooms,
                  Icons.bathroom_outlined,
                  (value) => setState(() => _bathrooms = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          Row(
            children: const [
              Icon(Icons.checkroom_outlined, size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Comodidades',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableAmenities.map((amenity) {
              final isSelected = _selectedAmenities.contains(amenity);
              return FilterChip(
                label: Text(amenity),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedAmenities.add(amenity);
                    } else {
                      _selectedAmenities.remove(amenity);
                    }
                  });
                },
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
                backgroundColor: AppColors.background,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fotos de la Propiedad',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agrega fotos atractivas de tu espacio (mínimo 1)',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          
          if (_isLoadingImages)
            const Center(child: CircularProgressIndicator())
          else if (_existingImageUrls.isEmpty && _imageFiles.isEmpty)
            _buildAddPhotoButton()
          else
            _buildPhotoGrid(),
        ],
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return InkWell(
      onTap: _pickImage,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_photo_alternate_outlined,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Agregar Fotos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Toca para seleccionar desde tu galería',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    final totalImages = _existingImageUrls.length + _imageFiles.length;
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: totalImages + 1,
          itemBuilder: (context, index) {
            if (index == totalImages) {
              return _buildAddMoreButton();
            }
            // Primero mostrar imágenes existentes, luego nuevas
            if (index < _existingImageUrls.length) {
              return _buildExistingPhotoItem(_existingImageUrls[index], index);
            } else {
              final newIndex = index - _existingImageUrls.length;
              return _buildPhotoItem(_imageFiles[newIndex], index);
            }
          },
        ),
      ],
    );
  }

  Widget _buildExistingPhotoItem(String imageUrl, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.background,
                child: const Icon(Icons.broken_image, size: 50),
              );
            },
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: InkWell(
            onTap: () {
              setState(() {
                _deletedImageUrls.add(_existingImageUrls[index]);
                _existingImageUrls.removeAt(index);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (index == 0)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Principal',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddMoreButton() {
    return InkWell(
      onTap: _pickImage,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add, size: 32, color: AppColors.primary),
            SizedBox(height: 8),
            Text(
              'Agregar más',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoItem(XFile imageFile, int index) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: kIsWeb
              ? FutureBuilder<Uint8List>(
                  future: imageFile.readAsBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Image.memory(
                        snapshot.data!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      );
                    }
                    return Container(
                      color: AppColors.background,
                      child: const CircularProgressIndicator(),
                    );
                  },
                )
              : Image.file(
                  File(imageFile.path),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: InkWell(
            onTap: () {
              setState(() => _imageFiles.removeAt(index));
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (index == 0)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Principal',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Disponible desde',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _availableFrom,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: AppColors.primary,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date != null) {
              setState(() => _availableFrom = date);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_availableFrom.day}/${_availableFrom.month}/${_availableFrom.year}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCounter(
    String label,
    int value,
    IconData icon,
    Function(int) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: value > 1 ? () => onChanged(value - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.primary,
                disabledColor: AppColors.textSecondary,
              ),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: value < 10 ? () => onChanged(value + 1) : null,
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.primary,
                disabledColor: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.primary, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Anterior',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleNext,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _currentStep == 2
                          ? (_isEditing ? 'Guardar cambios' : 'Publicar')
                          : 'Continuar',
                      style: const TextStyle(
                        fontSize: 16,
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

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _imageFiles.add(image);
      });
    }
  }

  Future<void> _handleNext() async {
    if (_currentStep < 2) {
      if (_currentStep == 0 && _formKey.currentState!.validate()) {
        setState(() => _currentStep++);
      } else if (_currentStep == 1) {
        setState(() => _currentStep++);
      }
    } else {
      await _publishProperty();
    }
  }

  Future<void> _publishProperty() async {
    if (!_isEditing && _imageFiles.isEmpty && _existingImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos una foto')),
      );
      return;
    }

    if (_isEditing && _imageFiles.isEmpty && _existingImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes tener al menos una foto')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authUser = SupabaseProvider.authService.getCurrentUser();
      
      if (authUser == null) {
        throw Exception('No hay usuario autenticado');
      }
      if (authUser == null) {
        throw Exception('Debes iniciar sesión');
      }

      if (_isEditing) {
        await SupabaseProvider.databaseService.updateProperty(
          widget.property!.id,
          {
            'title': _titleController.text,
            'description': _descriptionController.text,
            'price': double.tryParse(_priceController.text) ??
                widget.property!.price,
            'address': _addressController.text,
            'latitude': _latitude ?? widget.property!.latitude,
            'longitude': _longitude ?? widget.property!.longitude,
            'available_from': _availableFrom.toIso8601String(),
            'is_active': _isActive,
          },
        );

        // Eliminar imágenes marcadas para borrar
        for (final url in _deletedImageUrls) {
          await SupabaseProvider.databaseService
              .deletePropertyImageByUrl(widget.property!.id, url);
        }

        if (_imageFiles.isNotEmpty) {
          await _uploadPropertyImages(widget.property!.id);
        }
      } else {
        final property = Property(
          ownerId: authUser.id,
          title: _titleController.text,
          description: _descriptionController.text,
          price: double.parse(_priceController.text),
          address: _addressController.text,
          latitude: _latitude ?? 0.0,
          longitude: _longitude ?? 0.0,
          availableFrom: _availableFrom,
          isActive: _isActive,
        );

        final createdProperty =
            await SupabaseProvider.databaseService.createProperty(property);

        if (_imageFiles.isNotEmpty) {
          await _uploadPropertyImages(createdProperty.id);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Propiedad actualizada'
                  : '¡Propiedad publicada exitosamente!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uploadPropertyImages(String propertyId) async {
    for (final file in _imageFiles) {
      final url = await SupabaseProvider.storageService.uploadPropertyImageXFile(
        propertyId: propertyId,
        file: file,
      );
      await SupabaseProvider.databaseService
          .addPropertyImage(propertyId, url);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
