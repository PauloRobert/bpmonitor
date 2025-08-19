import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
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
  final DatabaseHelper _dbHelper = DatabaseHelper();

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
        warnings.add('A pressão sistólica geralmente é maior que a diastólica');
      }

      if (systolic >= 180 || diastolic >= 120) {
        warnings.add('Valores muito altos - procure ajuda médica se necessário');
      }
    }

    if (heartRate != null) {
      if (heartRate > 100) {
        warnings.add('Frequência cardíaca acelerada');
      } else if (heartRate < 60) {
        warnings.add('Frequência cardíaca baixa');
      }
    }

    return warnings;
  }

  Future<void> _saveMeasurement() async {
    if (!_formKey.currentState!.validate()) {
      return;
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

      if (widget.measurementToEdit != null) {
        await _dbHelper.updateMeasurement(measurement);
        AppConstants.logInfo('Medição atualizada: ${measurement.systolic}/${measurement.diastolic}');
      } else {
        await _dbHelper.insertMeasurement(measurement);
        AppConstants.logInfo('Nova medição salva: ${measurement.systolic}/${measurement.diastolic}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text(AppConstants.measurementSavedSuccess),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop(true);
      }
    } catch (e, stackTrace) {
      AppConstants.logError('Erro ao salvar medição', e, stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao salvar medição. Tente novamente.'),
            backgroundColor: AppConstants.secondaryColor,
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.measurementToEdit != null;
    final warnings = _getWarnings();

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
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInstructionCard(),
              const SizedBox(height: 24),
              _buildMeasurementFields(),
              const SizedBox(height: 24),
              _buildDateTimeSection(),
              const SizedBox(height: 24),
              _buildNotesField(),
              if (warnings.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildWarningsCard(warnings),
              ],
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: AppConstants.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Certifique-se de estar relaxado e em posição adequada para a medição',
                style: TextStyle(
                  fontSize: 14,
                  color: AppConstants.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementFields() {
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
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _systolicController,
                    decoration: const InputDecoration(
                      labelText: 'Sistólica *',
                      suffixText: 'mmHg',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.arrow_upward),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    validator: _validateSystolic,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _diastolicController,
                    decoration: const InputDecoration(
                      labelText: 'Diastólica *',
                      suffixText: 'mmHg',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.arrow_downward),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(3),
                    ],
                    validator: _validateDiastolic,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _heartRateController,
              decoration: const InputDecoration(
                labelText: 'Frequência Cardíaca *',
                suffixText: 'bpm',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.favorite),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              validator: _validateHeartRate,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
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

  Widget _buildWarningsCard(List<String> warnings) {
    return Card(
      elevation: 1,
      color: Colors.orange.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        side: BorderSide(color: Colors.orange.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Text(
                  'Atenção',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade700,
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
                  color: Colors.orange.shade700,
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final isEditing = widget.measurementToEdit != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveMeasurement,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
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
            : Text(
          isEditing ? 'Atualizar Medição' : 'Salvar Medição',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}