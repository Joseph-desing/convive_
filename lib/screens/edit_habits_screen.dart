import 'package:flutter/material.dart';
import '../utils/colors.dart';
import '../models/index.dart';
import '../config/supabase_provider.dart';

class EditHabitsScreen extends StatefulWidget {
  final Habits habits;

  const EditHabitsScreen({
    Key? key,
    required this.habits,
  }) : super(key: key);

  @override
  State<EditHabitsScreen> createState() => _EditHabitsScreenState();
}

class _EditHabitsScreenState extends State<EditHabitsScreen> {
  late int _cleanlinessLevel;
  late int _noiseTolerance;
  late int _partyFrequency;
  late int _guestsTolerance;
  late int _timeAtHome;
  late int _responsibilityLevel;
  late int _petTolerance;
  late TimeOfDay _sleepStart;
  late TimeOfDay _sleepEnd;
  WorkMode? _workMode;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cleanlinessLevel = widget.habits.cleanlinessLevel;
    _noiseTolerance = widget.habits.noiseTolerance;
    _partyFrequency = widget.habits.partyFrequency;
    _guestsTolerance = widget.habits.guestsTolerance;
    _timeAtHome = widget.habits.timeAtHome;
    _responsibilityLevel = widget.habits.responsibilityLevel;
    _petTolerance = widget.habits.petTolerance;
    _workMode = widget.habits.workMode;
    
    // Convert sleep hours to TimeOfDay
    _sleepStart = TimeOfDay(hour: widget.habits.sleepStart, minute: 0);
    _sleepEnd = TimeOfDay(hour: widget.habits.sleepEnd, minute: 0);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveHabits() async {
    setState(() => _isSaving = true);

    try {
      await SupabaseProvider.databaseService.updateHabits(
        widget.habits.id,
        {
          'cleanliness_level': _cleanlinessLevel,
          'noise_tolerance': _noiseTolerance,
          'party_frequency': _partyFrequency,
          'guests_tolerance': _guestsTolerance,
          'time_at_home': _timeAtHome,
          'responsibility_level': _responsibilityLevel,
          'pet_tolerance': _petTolerance > 5, // Convertir a boolean
          'sleep_start': _formatTimeOfDay(_sleepStart),
          'sleep_end': _formatTimeOfDay(_sleepEnd),
          'work_mode': _workMode?.name,
        },
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hábitos actualizados exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Editar hábitos',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Hábitos de convivencia'),
                  const SizedBox(height: 20),
                  _buildSlider(
                    'Nivel de limpieza',
                    Icons.cleaning_services_outlined,
                    _cleanlinessLevel,
                    (value) => setState(() => _cleanlinessLevel = value.round()),
                  ),
                  const SizedBox(height: 16),
                  _buildSlider(
                    'Tolerancia al ruido',
                    Icons.volume_up_outlined,
                    _noiseTolerance,
                    (value) => setState(() => _noiseTolerance = value.round()),
                  ),
                  const SizedBox(height: 16),
                  _buildSlider(
                    'Frecuencia de fiestas (días/semana)',
                    Icons.celebration_outlined,
                    _partyFrequency,
                    (value) => setState(() => _partyFrequency = value.round()),
                  ),
                  const SizedBox(height: 16),
                  _buildSlider(
                    'Tolerancia a invitados',
                    Icons.people_outline,
                    _guestsTolerance,
                    (value) => setState(() => _guestsTolerance = value.round()),
                  ),
                  const SizedBox(height: 16),
                  _buildSlider(
                    'Tiempo en casa',
                    Icons.home_outlined,
                    _timeAtHome,
                    (value) => setState(() => _timeAtHome = value.round()),
                  ),
                  const SizedBox(height: 16),
                  _buildSlider(
                    'Nivel de responsabilidad',
                    Icons.verified_user_outlined,
                    _responsibilityLevel,
                    (value) => setState(() => _responsibilityLevel = value.round()),
                  ),
                  const SizedBox(height: 16),
                  _buildSlider(
                    'Tolerancia a mascotas',
                    Icons.pets_outlined,
                    _petTolerance,
                    (value) => setState(() => _petTolerance = value.round()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Rutina y horarios'),
                  const SizedBox(height: 20),
                  _buildTimeSelector(
                    'Horario de sueño',
                    Icons.bedtime_outlined,
                    _sleepStart,
                    _sleepEnd,
                  ),
                  const SizedBox(height: 16),
                  _buildWorkModeSelector(),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
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
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveHabits,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Guardar cambios',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.psychology_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSlider(
    String label,
    IconData icon,
    int value,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$value/10',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.primary.withOpacity(0.2),
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 10,
            divisions: 10,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector(
    String label,
    IconData icon,
    TimeOfDay start,
    TimeOfDay end,
  ) {
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
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _sleepStart,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: AppColors.primary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (time != null) {
                    setState(() => _sleepStart = time);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTimeOfDay(_sleepStart),
                        style: const TextStyle(fontSize: 14),
                      ),
                      Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text('-', style: TextStyle(fontSize: 16)),
            ),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: _sleepEnd,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: AppColors.primary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (time != null) {
                    setState(() => _sleepEnd = time);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatTimeOfDay(_sleepEnd),
                        style: const TextStyle(fontSize: 14),
                      ),
                      Icon(Icons.access_time, size: 18, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWorkModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.work_outline, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text(
              'Modo de trabajo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: WorkMode.values.map((mode) {
            final isSelected = _workMode == mode;
            String label;
            switch (mode) {
              case WorkMode.office:
                label = 'Oficina';
                break;
              case WorkMode.remote:
                label = 'Remoto';
                break;
              case WorkMode.hybrid:
                label = 'Híbrido';
                break;
            }

            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _workMode = mode);
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: Colors.grey[200],
            );
          }).toList(),
        ),
      ],
    );
  }
}
