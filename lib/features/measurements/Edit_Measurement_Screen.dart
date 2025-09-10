import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_service.dart';
import '../../shared/models/measurement_model.dart';

class EditMeasurementScreen extends StatefulWidget {
  final MeasurementModel measurement;

  const EditMeasurementScreen({
    super.key,
    required this.measurement,
  });

  @override
  State<EditMeasurementScreen> createState() => _EditMeasurementScreenState();
}

class _EditMeasurementScreenState extends State<EditMeasurementScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final db = DatabaseService.instance;

  // Controllers
  final TextEditingController _systolicController = TextEditingController();
  final TextEditingController _diastolicController = TextEditingController();
  final TextEditingController _heartRateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // State
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;
  bool _hasChanges = false;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _initializeFields();
    _setupChangeListeners();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));

    _animationController.forward();
  }

  void _initializeFields() {
    final measurement = widget.measurement;
    _systolicController.text = measurement.systolic.toString();
    _diastolicController.text = measurement.diastolic.toString();
    _heartRateController.text = measurement.heartRate.toString();
    _notesController.text = measurement.notes ?? '';
    _selectedDate = measurement.measuredAt;
    _selectedTime = TimeOfDay.fromDateTime(measurement.measuredAt);
  }

  void _setupChangeListeners() {
    _systolicController.addListener(_onFieldChange);
    _diastolicController.addListener(_onFieldChange);
    _heartRateController.addListener(_onFieldChange);
    _notesController.addListener(_onFieldChange);
  }

  void _onFieldChange() {
    final hasChanges = _checkForChanges();
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  bool _checkForChanges() {
    final original = widget.measurement;

    final measuredAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    return _systolicController.text != original.systolic.toString() ||
        _diastolicController.text != original.diastolic.toString() ||
        _heartRateController.text != original.heartRate.toString() ||
        _notesController.text != (original.notes ?? '') ||
        !measuredAt.isAtSameMomentAs(original.measuredAt);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _systolicController.dispose();
    _diastolicController.dispose();
    _heartRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppConstants.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppConstants.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String? _validateSystolic(String? value) {
    if (value == null || value.isEmpty) return 'Campo obrigatório';
    final intValue = int.tryParse(value);
    if (intValue == null) return 'Valor inválido';
    if (intValue < AppConstants.minSystolic || intValue > AppConstants.maxSystolic) {
      return 'Entre ${AppConstants.minSystolic} e ${AppConstants.maxSystolic}';
    }
    return null;
  }

  String? _validateDiastolic(String? value) {
    if (value == null || value.isEmpty) return 'Campo obrigatório';
    final intValue = int.tryParse(value);
    if (intValue == null) return 'Valor inválido';
    if (intValue < AppConstants.minDiastolic || intValue > AppConstants.maxDiastolic) {
      return 'Entre ${AppConstants.minDiastolic} e ${AppConstants.maxDiastolic}';
    }
    return null;
  }

  String? _validateHeartRate(String? value) {
    if (value == null || value.isEmpty) return 'Campo obrigatório';
    final intValue = int.tryParse(value);
    if (intValue == null) return 'Valor inválido';
    if (intValue < AppConstants.minHeartRate || intValue > AppConstants.maxHeartRate) {
      return 'Entre ${AppConstants.minHeartRate} e ${AppConstants.maxHeartRate}';
    }
    return null;
  }

  MeasurementModel? _getPreviewMeasurement() {
    final systolic = int.tryParse(_systolicController.text);
    final diastolic = int.tryParse(_diastolicController.text);
    final heartRate = int.tryParse(_heartRateController.text);

    if (systolic != null && diastolic != null && heartRate != null) {
      return MeasurementModel(
        systolic: systolic,
        diastolic: diastolic,
        heartRate: heartRate,
        measuredAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
    }
    return null;
  }

  Future<void> _saveMeasurement() async {
    if (!_formKey.currentState!.validate()) return;

    final preview = _getPreviewMeasurement();
    if (preview != null && preview.needsUrgentAttention) {
      final shouldContinue = await _showCriticalAlert();
      if (shouldContinue != true) return;
    }

    setState(() => _isLoading = true);

    try {
      final measuredAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final updatedMeasurement = widget.measurement.copyWith(
        systolic: int.parse(_systolicController.text),
        diastolic: int.parse(_diastolicController.text),
        heartRate: int.parse(_heartRateController.text),
        measuredAt: measuredAt,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await db.updateMeasurement(updatedMeasurement);

      AppConstants.logUserAction('edit_measurement', {
        'id': updatedMeasurement.id,
        'systolic': updatedMeasurement.systolic,
        'diastolic': updatedMeasurement.diastolic,
        'category': updatedMeasurement.category,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(AppConstants.measurementUpdatedSuccess),
              ],
            ),
            backgroundColor: AppConstants.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao atualizar medição', e, stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Erro ao atualizar medição'),
              ],
            ),
            backgroundColor: AppConstants.dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool?> _showCriticalAlert() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppConstants.criticalColor, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Atenção Médica',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Os valores informados indicam uma possível situação que requer atenção médica.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              '⚠️ Considere procurar orientação médica.',
              style: TextStyle(
                color: AppConstants.criticalColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text('Deseja continuar com a atualização?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.criticalColor,
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Descartar alterações?'),
        content: const Text('Você tem alterações não salvas. Deseja sair sem salvar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Descartar'),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        appBar: AppBar(
          title: const Text('Editar Medição'),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppConstants.textPrimary),
          titleTextStyle: const TextStyle(
            color: AppConstants.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          actions: [
            if (_hasChanges)
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: _isLoading ? null : _saveMeasurement,
                  icon: _isLoading
                      ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppConstants.primaryColor,
                    ),
                  )
                      : const Icon(Icons.check, color: AppConstants.successColor),
                  tooltip: 'Salvar alterações',
                ),
              ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SafeArea(
              child: Column(
                children: [
                  // Progress indicator se tiver alterações
                  if (_hasChanges)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: AppConstants.warningColor.withOpacity(0.1),
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16, color: AppConstants.warningColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Você tem alterações não salvas',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppConstants.warningColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildOriginalValuesCard(),
                            const SizedBox(height: 16),
                            _buildEditForm(),
                            const SizedBox(height: 16),
                            _buildPreviewCard(),
                          ],
                        ),
                      ),
                    ),
                  ),

                  if (_hasChanges) _buildBottomActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOriginalValuesCard() {
    final original = widget.measurement;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: AppConstants.textSecondary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Valores Originais',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildReadOnlyValue(
                    'Sistólica',
                    '${original.systolic}',
                    'mmHg',
                    Icons.arrow_upward,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildReadOnlyValue(
                    'Diastólica',
                    '${original.diastolic}',
                    'mmHg',
                    Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildReadOnlyValue(
                    'Batimentos',
                    '${original.heartRate}',
                    'bpm',
                    Icons.favorite,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: original.categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.analytics,
                    color: original.categoryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    original.categoryName,
                    style: TextStyle(
                      fontSize: 12,
                      color: original.categoryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    original.formattedDateTime,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppConstants.textSecondary,
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

  Widget _buildReadOnlyValue(String label, String value, String unit, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppConstants.textSecondary),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 10,
              color: AppConstants.textSecondary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: AppConstants.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit, color: AppConstants.primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Novos Valores',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Campos de pressão
            Row(
              children: [
                Expanded(
                  child: _buildEditableField(
                    label: 'Sistólica',
                    controller: _systolicController,
                    validator: _validateSystolic,
                    icon: Icons.arrow_upward,
                    suffix: 'mmHg',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildEditableField(
                    label: 'Diastólica',
                    controller: _diastolicController,
                    validator: _validateDiastolic,
                    icon: Icons.arrow_downward,
                    suffix: 'mmHg',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Frequência cardíaca
            _buildEditableField(
              label: 'Frequência Cardíaca',
              controller: _heartRateController,
              validator: _validateHeartRate,
              icon: Icons.favorite,
              suffix: 'bpm',
            ),

            const SizedBox(height: 16),

            // Data e hora
            Row(
              children: [
                Expanded(
                  child: _buildDateTimePicker(
                    icon: Icons.calendar_today,
                    label: 'Data',
                    text: '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                    onTap: _selectDate,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateTimePicker(
                    icon: Icons.access_time,
                    label: 'Hora',
                    text: '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                    onTap: _selectTime,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Observações
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Observações',
                hintText: 'Adicione observações sobre esta medição...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required IconData icon,
    required String suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Ex: 120',
            border: const OutlineInputBorder(),
            prefixIcon: Icon(icon),
            suffixText: suffix,
            errorMaxLines: 2,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildDateTimePicker({
    required IconData icon,
    required String label,
    required String text,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(text, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard() {
    final preview = _getPreviewMeasurement();

    if (preview == null) return const SizedBox.shrink();

    return Card(
      elevation: 1,
      color: preview.categoryColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview, color: preview.categoryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Pré-visualização',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: preview.categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: preview.categoryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.analytics, color: preview.categoryColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Classificação: ${preview.categoryName}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: preview.categoryColor,
                    ),
                  ),
                ],
              ),
            ),

            if (preview.medicalAlerts.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...preview.medicalAlerts.take(2).map(
                    (alert) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $alert',
                    style: TextStyle(
                      fontSize: 12,
                      color: preview.categoryColor,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
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
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () async {
                final shouldDiscard = await _onWillPop();
                if (shouldDiscard && mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveMeasurement,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                'Salvar Alterações',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}