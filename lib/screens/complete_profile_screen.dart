import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../config/supabase_provider.dart';
import '../models/index.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String userId;
  final String email;
  
  const CompleteProfileScreen({
    Key? key,
    required this.userId,
    required this.email,
  }) : super(key: key);

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  
  // Datos del perfil
  final _fullNameController = TextEditingController();
  final _bioController = TextEditingController();
  DateTime? _birthDate;
  Gender? _gender;
  
  // Datos de hábitos
  int _cleanlinessLevel = 5;
  int _noiseTolerance = 5;
  int _partyFrequency = 1;
  int _guestsTolerance = 5;
  bool _pets = false;
  int _petTolerance = 5;
  WorkMode _workMode = WorkMode.hybrid;
  int _sleepStartHour = 23;
  int _sleepEndHour = 7;
  int _timeAtHome = 5;
  int _responsibilityLevel = 5;
  
  bool _isLoading = false;

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
              Expanded(
                child: _currentStep == 0
                    ? _buildProfileStep()
                    : _buildHabitsStep(),
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
                  'ConVive',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                'Paso ${_currentStep + 1} de 2',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 2,
              minHeight: 6,
              backgroundColor: AppColors.background,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Completa tu perfil',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ayúdanos a conocerte mejor para encontrar tu match perfecto',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 32),
            
            _buildWhiteCard(
              child: Column(
                children: [
                  _buildTextField(
                    controller: _fullNameController,
                    label: 'Nombre completo',
                    hint: 'Juan Pérez García',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa tu nombre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  _buildDateField(),
                  const SizedBox(height: 20),
                  
                  _buildGenderField(),
                  const SizedBox(height: 20),
                  
                  _buildTextField(
                    controller: _bioController,
                    label: 'Sobre ti',
                    hint: '¿Qué te gusta hacer? ¿Cómo eres como compañero/a?',
                    icon: Icons.edit_outlined,
                    maxLines: 4,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tus hábitos',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esto nos ayuda a encontrar el mejor match para ti',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 32),
          
          _buildWhiteCard(
            child: Column(
              children: [
                _buildSlider(
                  'Nivel de limpieza',
                  _cleanlinessLevel,
                  Icons.cleaning_services_outlined,
                  (value) => setState(() => _cleanlinessLevel = value),
                ),
                const SizedBox(height: 24),
                
                _buildSlider(
                  'Tolerancia al ruido',
                  _noiseTolerance,
                  Icons.volume_up_outlined,
                  (value) => setState(() => _noiseTolerance = value),
                ),
                const SizedBox(height: 24),
                
                _buildSlider(
                  'Fiestas por semana',
                  _partyFrequency,
                  Icons.celebration_outlined,
                  (value) => setState(() => _partyFrequency = value),
                  max: 7,
                ),
                const SizedBox(height: 24),
                
                _buildSlider(
                  'Tolerancia a invitados',
                  _guestsTolerance,
                  Icons.people_outline,
                  (value) => setState(() => _guestsTolerance = value),
                ),
                const SizedBox(height: 24),
                
                _buildSwitchTile(
                  '¿Tienes mascotas?',
                  _pets,
                  Icons.pets_outlined,
                  (value) => setState(() => _pets = value),
                ),
                const SizedBox(height: 16),
                
                _buildSlider(
                  'Tolerancia a mascotas',
                  _petTolerance,
                  Icons.pets_outlined,
                  (value) => setState(() => _petTolerance = value),
                ),
                const SizedBox(height: 24),
                
                _buildWorkModeField(),
                const SizedBox(height: 24),
                
                _buildSleepSchedule(),
                const SizedBox(height: 24),
                
                _buildSlider(
                  'Tiempo en casa (horas/día)',
                  _timeAtHome,
                  Icons.home_outlined,
                  (value) => setState(() => _timeAtHome = value),
                ),
                const SizedBox(height: 24),
                
                _buildSlider(
                  'Nivel de responsabilidad',
                  _responsibilityLevel,
                  Icons.verified_user_outlined,
                  (value) => setState(() => _responsibilityLevel = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhiteCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
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
            Icon(Icons.cake_outlined, size: 20, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Fecha de nacimiento',
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
              initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
              firstDate: DateTime(1950),
              lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
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
              setState(() => _birthDate = date);
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
                  _birthDate != null
                      ? '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}'
                      : 'Selecciona tu fecha',
                  style: TextStyle(
                    fontSize: 15,
                    color: _birthDate != null
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
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

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.wc_outlined, size: 20, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Género',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: [
            _buildGenderChip('Masculino', Gender.male),
            _buildGenderChip('Femenino', Gender.female),
            _buildGenderChip('Otro', Gender.other),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderChip(String label, Gender value) {
    final isSelected = _gender == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _gender = selected ? value : null);
      },
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.background,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildWorkModeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.work_outline, size: 20, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Modo de trabajo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          children: [
            _buildWorkModeChip('Remoto', WorkMode.remote),
            _buildWorkModeChip('Presencial', WorkMode.office),
            _buildWorkModeChip('Híbrido', WorkMode.hybrid),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkModeChip(String label, WorkMode value) {
    final isSelected = _workMode == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _workMode = value);
      },
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.background,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildSleepSchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.bedtime_outlined, size: 20, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'Horario de sueño',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTimeSelector(
                'Duermes',
                _sleepStartHour,
                (value) => setState(() => _sleepStartHour = value),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTimeSelector(
                'Despiertas',
                _sleepEndHour,
                (value) => setState(() => _sleepEndHour = value),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSelector(String label, int hour, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<int>(
            value: hour,
            isExpanded: true,
            underline: const SizedBox(),
            items: List.generate(24, (index) {
              return DropdownMenuItem(
                value: index,
                child: Text('${index.toString().padLeft(2, '0')}:00'),
              );
            }),
            onChanged: (value) => onChanged(value!),
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(
    String label,
    int value,
    IconData icon,
    Function(int) onChanged, {
    int max = 10,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$value/${max}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: max == 7 ? 0 : 1,
          max: max.toDouble(),
          divisions: max == 7 ? 7 : (max - 1),
          activeColor: AppColors.primary,
          onChanged: (newValue) => onChanged(newValue.toInt()),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    String label,
    bool value,
    IconData icon,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
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
                      _currentStep == 0 ? 'Continuar' : 'Finalizar',
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

  Future<void> _handleNext() async {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        if (_fullNameController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Completa tu nombre')),
          );
          return;
        }
        setState(() => _currentStep++);
      }
    } else {
      await _saveProfile();
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      // Crear perfil
      final profile = Profile(
        userId: widget.userId,
        fullName: _fullNameController.text,
        birthDate: _birthDate,
        gender: _gender,
        bio: _bioController.text.isEmpty ? null : _bioController.text,
      );

      await SupabaseProvider.databaseService.createProfile(profile);

      // Crear hábitos
      final habits = Habits(
        userId: widget.userId,
        sleepStart: _sleepStartHour,
        sleepEnd: _sleepEndHour,
        cleanlinessLevel: _cleanlinessLevel,
        noiseTolerance: _noiseTolerance,
        partyFrequency: _partyFrequency,
        guestsTolerance: _guestsTolerance,
        pets: _pets,
        petTolerance: _petTolerance,
        workMode: _workMode,
        timeAtHome: _timeAtHome,
        responsibilityLevel: _responsibilityLevel,
      );

      await SupabaseProvider.databaseService.createHabits(habits);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Perfil completado exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navegar a home
        Navigator.of(context).pushReplacementNamed('/home');
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

  @override
  void dispose() {
    _fullNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
