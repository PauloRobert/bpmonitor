import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_service.dart';
import '../../shared/models/measurement_model.dart';

class AddMeasurementScreen extends StatefulWidget {
  final MeasurementModel? measurementToEdit;

  const AddMeasurementScreen({
    super.key,
    this.measurementToEdit,
  });

  @override
  State<AddMeasurementScreen> createState() => _AddMeasurementScreenState();
}

class _AddMeasurementScreenState extends State<AddMeasurementScreen> {
  final _formKey = GlobalKey<FormState>();
  final db = DatabaseService.instance;

  final TextEditingController _systolicController = TextEditingController();
  final TextEditingController _diastolicController = TextEditingController();
  final TextEditingController _heartRateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _systolicController.addListener(() => setState(() {}));
    _diastolicController.addListener(() => setState(() {}));
    _heartRateController.addListener(() => setState(() {}));
  }

  void _initializeFields() {
    if (widget.measurementToEdit != null) {
      final measurement = widget.measurementToEdit!;
      _systolicController.text = measurement.systolic.toString();
      _diastolicController.text = measurement.diastolic.toString();
      _heartRateController.text = measurement.heartRate.toString();
      _notesController.text = measurement.notes ?? '';
      _selectedDate = measurement.measuredAt;
      _selectedTime = TimeOfDay.fromDateTime(measurement.measuredAt);
    }
  }

  @override
  void dispose() {
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
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String? _validateSystolic(String? value) {
    if (value == null || value.isEmpty) {
      return 'Campo obrigatório';
    }
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return 'Valor inválido';
    }
    if (intValue < AppConstants.minSystolic || intValue > AppConstants.maxSystolic) {
      return 'Valor deve estar entre ${AppConstants.minSystolic} e ${AppConstants.maxSystolic}';
    }
    return null;
  }

  String? _validateDiastolic(String? value) {
    if (value == null || value.isEmpty) {
      return 'Campo obrigatório';
    }
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return 'Valor inválido';
    }
    if (intValue < AppConstants.minDiastolic || intValue > AppConstants.maxDiastolic) {
      return 'Valor deve estar entre ${AppConstants.minDiastolic} e ${AppConstants.maxDiastolic}';
    }
    return null;
  }

  String? _validateHeartRate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Campo obrigatório';
    }
    final intValue = int.tryParse(value);
    if (intValue == null) {
      return 'Valor inválido';
    }
    if (intValue < AppConstants.minHeartRate || intValue > AppConstants.maxHeartRate) {
      return 'Valor deve estar entre ${AppConstants.minHeartRate} e ${AppConstants.maxHeartRate}';
    }
    return null;
  }

  List<String> _getWarnings() {
    final warnings = <String>[];
    final systolic = int.tryParse(_systolicController.text);
    final diastolic = int.tryParse(_diastolicController.text);
    final heartRate = int.tryParse(_heartRateController.text);

    if (systolic != null && diastolic != null) {
      if (systolic <= diastolic) {
        warnings.add('ERRO: A pressão sistólica deve ser maior que a diastólica');
      }

      final tempMeasurement = MeasurementModel(
        systolic: systolic,
        diastolic: diastolic,
        heartRate: heartRate ?? 72,
        measuredAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
      warnings.addAll(tempMeasurement.medicalAlerts);
    }
    return warnings;
  }

  AlertLevel _getAlertLevel() {
    final systolic = int.tryParse(_systolicController.text);
    final diastolic = int.tryParse(_diastolicController.text);

    if (systolic != null && diastolic != null) {
      if (systolic <= diastolic) {
        return AlertLevel.critical;
      }
      final tempMeasurement = MeasurementModel(
        systolic: systolic,
        diastolic: diastolic,
        heartRate: int.tryParse(_heartRateController.text) ?? 72,
        measuredAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
      if (tempMeasurement.needsUrgentAttention) {
        return AlertLevel.critical;
      }
      switch (tempMeasurement.category) {
        case 'crisis':
          return AlertLevel.critical;
        case 'high_stage2':
          return AlertLevel.high;
        case 'high_stage1':
          return AlertLevel.medium;
        case 'elevated':
          return AlertLevel.low;
        default:
          return AlertLevel.none;
      }
    }
    return AlertLevel.none;
  }

  Future<void> _saveMeasurement() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final alertLevel = _getAlertLevel();
    if (alertLevel == AlertLevel.critical) {
      final shouldContinue = await _showCriticalAlert();
      if (shouldContinue != true) {
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final measuredAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final measurement = MeasurementModel(
        id: widget.measurementToEdit?.id,
        systolic: int.parse(_systolicController.text),
        diastolic: int.parse(_diastolicController.text),
        heartRate: int.parse(_heartRateController.text),
        measuredAt: measuredAt,
        createdAt: widget.measurementToEdit?.createdAt ?? DateTime.now(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      AppConstants.logUserAction(
        widget.measurementToEdit != null ? 'update_measurement' : 'add_measurement',
        {
          'systolic': measurement.systolic,
          'diastolic': measurement.diastolic,
          'heartRate': measurement.heartRate,
          'category': measurement.category,
        },
      );

      if (widget.measurementToEdit != null) {
        await db.updateMeasurement(measurement);
        AppConstants.logInfo('Medição atualizada: ${measurement.systolic}/${measurement.diastolic}');
      } else {
        await db.insertMeasurement(measurement);
        AppConstants.logInfo('Nova medição salva: ${measurement.systolic}/${measurement.diastolic}');
      }

      if (mounted) {
        final isEditing = widget.measurementToEdit != null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(isEditing
                    ? AppConstants.measurementUpdatedSuccess
                    : AppConstants.measurementSavedSuccess),
              ],
            ),
            backgroundColor: AppConstants.successColor,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao salvar medição', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text('Erro ao salvar medição. Tente novamente.'),
              ],
            ),
            backgroundColor: AppConstants.secondaryColor,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool?> _showCriticalAlert() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: AppConstants.criticalColor),
            const SizedBox(width: 8),
            const Expanded( // Garante que o texto se adapte à largura
              child: Text(
                'Atenção Médica Urgente',
                softWrap: true, // Habilita quebra de linha
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Os valores informados indicam uma possível emergência hipertensiva.',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 12),
            Text(
              '⚠️ Recomendamos procurar atendimento médico imediatamente.',
              style: TextStyle(color: Colors.red),
            ),
            SizedBox(height: 8),
            Text(
              'Deseja continuar salvando esta medição?',
            ),
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
              foregroundColor: Colors.white,
            ),
            child: const Text('Salvar Mesmo Assim'),
          ),
        ],
      ),
    );
  }

  Future<void> _showTipsDialog() async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dicas para uma medição precisa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTipItem('Descanse 5 minutos antes da medição'),
            _buildTipItem('Mantenha os pés no chão e costas apoiadas'),
            _buildTipItem('Evite falar durante a medição'),
            _buildTipItem('Não consuma cafeína 30min antes'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ok'),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            size: 16,
            color: AppConstants.successColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.measurementToEdit != null;
    final warnings = _getWarnings();
    final alertLevel = _getAlertLevel();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Medição' : 'Nova Medição'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppConstants.textPrimary),
        titleTextStyle: const TextStyle(
          color: AppConstants.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showTipsDialog,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMeasurementFieldsCard(),
              const SizedBox(height: 24),
              _buildDateTimeSection(),
              const SizedBox(height: 24),
              _buildNotesField(),
              if (warnings.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildWarningsCard(warnings, alertLevel),
              ],
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurementFieldsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Valores da Medição',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            _buildPressureInputs(),
            const SizedBox(height: 20),
            _buildHeartRateInput(),
            if (_systolicController.text.isNotEmpty && _diastolicController.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildClassificationPreview(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPressureInputs() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sistólica (mmHg)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: TextFormField(
                  controller: _systolicController,
                  decoration: InputDecoration(
                    hintText: 'Ex: 120',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.arrow_upward),
                    errorMaxLines: 2,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  validator: _validateSystolic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Diastólica (mmHg)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppConstants.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: TextFormField(
                  controller: _diastolicController,
                  decoration: InputDecoration(
                    hintText: 'Ex: 80',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.arrow_downward),
                    errorMaxLines: 2,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  validator: _validateDiastolic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeartRateInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequência Cardíaca (bpm)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppConstants.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: TextFormField(
            controller: _heartRateController,
            decoration: InputDecoration(
              hintText: 'Ex: 72',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.favorite),
              errorMaxLines: 2,
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            validator: _validateHeartRate,
          ),
        ),
      ],
    );
  }

  Widget _buildClassificationPreview() {
    final systolic = int.tryParse(_systolicController.text);
    final diastolic = int.tryParse(_diastolicController.text);
    final heartRate = int.tryParse(_heartRateController.text);

    if (systolic == null || diastolic == null) {
      return const SizedBox.shrink();
    }

    final tempMeasurement = MeasurementModel(
      systolic: systolic,
      diastolic: diastolic,
      heartRate: heartRate ?? 72,
      measuredAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tempMeasurement.categoryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: tempMeasurement.categoryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.analytics,
            color: tempMeasurement.categoryColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Classificação: ${tempMeasurement.categoryName}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: tempMeasurement.categoryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data e Hora da Medição',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Observações (opcional)',
            hintText: 'Ex: Após exercício, estresse, medicação...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.note),
          ),
          maxLines: 3,
          maxLength: 200,
        ),
      ),
    );
  }

  Widget _buildWarningsCard(List<String> warnings, AlertLevel level) {
    Color cardColor;
    Color borderColor;
    Color textColor;
    IconData icon;

    switch (level) {
      case AlertLevel.critical:
        cardColor = AppConstants.criticalColor.withOpacity(0.1);
        borderColor = AppConstants.criticalColor;
        textColor = AppConstants.criticalColor;
        icon = Icons.emergency;
        break;
      case AlertLevel.high:
        cardColor = AppConstants.dangerColor.withOpacity(0.1);
        borderColor = AppConstants.dangerColor;
        textColor = AppConstants.dangerColor;
        icon = Icons.warning;
        break;
      case AlertLevel.medium:
        cardColor = Colors.orange.shade50;
        borderColor = Colors.orange.shade200;
        textColor = Colors.orange.shade700;
        icon = Icons.warning_amber;
        break;
      case AlertLevel.low:
        cardColor = AppConstants.warningColor.withOpacity(0.1);
        borderColor = AppConstants.warningColor;
        textColor = AppConstants.warningColor;
        icon = Icons.info;
        break;
      default:
        cardColor = Colors.blue.shade50;
        borderColor = Colors.blue.shade200;
        textColor = Colors.blue.shade700;
        icon = Icons.info_outline;
    }

    return Card(
      elevation: level == AlertLevel.critical ? 3 : 1,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        side: BorderSide(color: borderColor, width: level == AlertLevel.critical ? 2 : 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: textColor),
                const SizedBox(width: 8),
                Text(
                  level == AlertLevel.critical ? 'ATENÇÃO URGENTE' : 'Atenção',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...warnings.map((warning) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '• $warning',
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                  fontWeight: level == AlertLevel.critical ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            )),
            if (level == AlertLevel.critical) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Em caso de emergência, ligue 192 (SAMU) ou vá ao hospital mais próximo'),
                        backgroundColor: AppConstants.criticalColor,
                        duration: Duration(seconds: 5),
                      ),
                    );
                  },
                  icon: const Icon(Icons.phone),
                  label: const Text('Orientações de Emergência'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(color: textColor),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final isEditing = widget.measurementToEdit != null;
    final alertLevel = _getAlertLevel();

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveMeasurement,
        style: ElevatedButton.styleFrom(
          backgroundColor: alertLevel == AlertLevel.critical
              ? AppConstants.criticalColor
              : AppConstants.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
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
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (alertLevel == AlertLevel.critical)
              const Icon(Icons.warning, size: 18),
            if (alertLevel == AlertLevel.critical)
              const SizedBox(width: 8),
            Text(
              isEditing ? 'Atualizar Medição' : 'Salvar Medição',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum AlertLevel {
  none,
  low,
  medium,
  high,
  critical,
}