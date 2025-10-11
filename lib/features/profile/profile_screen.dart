import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_service.dart';
import '../../shared/models/user_model.dart';
import 'package:flutter/services.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final DatabaseService db = DatabaseService.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  // ✅ NOVO: controladores para peso e altura
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  String _selectedGender = 'M';


  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _loadUserData();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _birthDateController.dispose();
    // ✅ NOVOS
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);
      final user = await db.getUser();

      if (user != null) {
        setState(() {
          _currentUser = user;
          _nameController.text = user.name;
          _birthDateController.text = user.birthDate;

          // ✅ Novos campos
          _selectedGender = user.gender;
          _weightController.text =
              user.weight.toStringAsFixed(1).replaceAll('.', ',');
          _heightController.text =
              user.height.toStringAsFixed(2).replaceAll('.', ',');
        });

        // mantém o debug opcional
        debugPrint("[BP_MONITOR] [DEBUG] CreatedAt do usuário: ${user.createdAt.toIso8601String()}");
        debugPrint("[BP_MONITOR] [DEBUG] Dias de uso calculado: ${DateTime.now().difference(user.createdAt).inDays}");

        _animationController.forward();
      }
    } catch (e) {
      _showError('Erro ao carregar dados do usuário');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectBirthDate() async {
    if (!_isEditing) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _currentUser != null
          ? DateTime.parse(_currentUser!.birthDate)
          : DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
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

    if (picked != null) {
      setState(() {
        _birthDateController.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Converte os campos de texto em números
      final weight = double.parse(_weightController.text.replaceAll(',', '.'));
      final height = double.parse(_heightController.text.replaceAll(',', '.'));

      final updatedUser = _currentUser!.copyWith(
        name: _nameController.text.trim(),
        birthDate: _birthDateController.text,
        gender: _selectedGender,  // ✅ Novo
        weight: weight,           // ✅ Novo
        height: height,           // ✅ Novo
        updatedAt: DateTime.now(),
      );

      await db.updateUser(updatedUser);

      setState(() {
        _currentUser = updatedUser;
        _isEditing = false;
      });

      _showSuccess('Dados atualizados com sucesso!');
    } catch (e) {
      _showError('Erro ao salvar alterações');
    } finally {
      setState(() => _isSaving = false);
    }
  }


  void _toggleEdit() {
    setState(() {
      if (_isEditing) {
        // Se estava editando e cancelou, restaura os valores originais
        _nameController.text = _currentUser!.name;
        _birthDateController.text = _currentUser!.birthDate;
        _selectedGender = _currentUser!.gender; // ✅ Novo
        _weightController.text = _currentUser!.weight
            .toStringAsFixed(1)
            .replaceAll('.', ',');            // ✅ Novo
        _heightController.text = _currentUser!.height
            .toStringAsFixed(2)
            .replaceAll('.', ',');            // ✅ Novo
      }

      _isEditing = !_isEditing;
    });
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: AppConstants.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: AppConstants.dangerColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(color: AppConstants.primaryColor),
        )
            : _currentUser == null
            ? _buildNoUserState()
            : FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: _buildProfileContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildNoUserState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 80,
              color: AppConstants.textSecondary,
            ),
            SizedBox(height: 16),
            Text(
              'Nenhum usuário cadastrado',
              style: TextStyle(
                fontSize: 18,
                color: AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return Column(
      children: [
        Expanded(
          child: CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildPersonalInfoCard(),
                        const SizedBox(height: 16),
                        _buildStatisticsCard(),
                        const SizedBox(height: 16),
                        _buildHealthCard(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isEditing) _buildSaveButtonSection(),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppConstants.primaryColor,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: AppConstants.splashGradient),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Avatar com primeira letra do nome
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _currentUser != null && _currentUser!.name.isNotEmpty
                          ? _currentUser!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Nome completo
                Text(
                  _currentUser?.name ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                // Idade
                Text(
                  _currentUser != null ? '${_currentUser!.age} anos' : '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isEditing ? Icons.close : Icons.edit,
            color: Colors.white,
          ),
          onPressed: _toggleEdit,
        ),
      ],
    );
  }

  Widget _buildPersonalInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.person, color: AppConstants.primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Informações Pessoais',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Nome
            TextFormField(
              controller: _nameController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Nome completo',
                prefixIcon: const Icon(Icons.person_outline),
                border: _isEditing ? const OutlineInputBorder() : InputBorder.none,
                filled: !_isEditing,
                fillColor: Colors.grey.shade50,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Nome é obrigatório';
                if (value.trim().length < 3) return 'Nome muito curto';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Data de nascimento
            TextFormField(
              controller: _birthDateController,
              enabled: _isEditing,
              readOnly: true,
              onTap: _selectBirthDate,
              decoration: InputDecoration(
                labelText: 'Data de nascimento',
                prefixIcon: const Icon(Icons.cake_outlined),
                suffixIcon: _isEditing ? const Icon(Icons.calendar_today) : null,
                border: _isEditing ? const OutlineInputBorder() : InputBorder.none,
                filled: !_isEditing,
                fillColor: Colors.grey.shade50,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Data de nascimento é obrigatória';
                return null;
              },
            ),

            // ✅ Informações extras somente leitura
            if (!_isEditing && _currentUser != null) ...[
              const SizedBox(height: 20),
              _buildInfoRow(Icons.wc, 'Sexo', _currentUser!.genderName),
              const Divider(height: 24),
              _buildInfoRow(Icons.monitor_weight, 'Peso', _currentUser!.weightFormatted),
              const Divider(height: 24),
              _buildInfoRow(Icons.height, 'Altura', _currentUser!.heightFormatted),
              const Divider(height: 24),
              _buildInfoRow(Icons.analytics, 'IMC', _currentUser!.bmiFormatted),
            ],

            // ✅ Campos editáveis
            if (_isEditing) ...[
              const SizedBox(height: 16),
              // Seletor de gênero
              _buildGenderSelector(),
              const SizedBox(height: 16),
              // Peso
              TextFormField(
                controller: _weightController,
                enabled: _isEditing,
                decoration: const InputDecoration(
                  labelText: 'Peso (kg)',
                  prefixIcon: Icon(Icons.monitor_weight),
                  suffixText: 'kg',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    String text = newValue.text.replaceAll('.', ',');
                    if (text.split(',').length > 2) return oldValue;
                    if (text.contains(',')) {
                      final parts = text.split(',');
                      if (parts[1].length > 1) {
                        text = '${parts[0]},${parts[1].substring(0, 1)}';
                      }
                    }
                    return TextEditingValue(
                      text: text,
                      selection: TextSelection.collapsed(offset: text.length),
                    );
                  }),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Peso é obrigatório';
                  final weight = double.tryParse(value.replaceAll(',', '.'));
                  if (weight == null) return 'Valor inválido';
                  if (weight < AppConstants.minWeight || weight > AppConstants.maxWeight) {
                    return 'Peso deve estar entre ${AppConstants.minWeight}kg e ${AppConstants.maxWeight}kg';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Altura
              TextFormField(
                controller: _heightController,
                enabled: _isEditing,
                decoration: const InputDecoration(
                  labelText: 'Altura (m)',
                  prefixIcon: Icon(Icons.height),
                  suffixText: 'm',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                  TextInputFormatter.withFunction((oldValue, newValue) {
                    String text = newValue.text.replaceAll('.', ',');
                    if (text.split(',').length > 2) return oldValue;
                    if (text.contains(',')) {
                      final parts = text.split(',');
                      if (parts[1].length > 2) {
                        text = '${parts[0]},${parts[1].substring(0, 2)}';
                      }
                    }
                    return TextEditingValue(
                      text: text,
                      selection: TextSelection.collapsed(offset: text.length),
                    );
                  }),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Altura é obrigatória';
                  final height = double.tryParse(value.replaceAll(',', '.'));
                  if (height == null) return 'Valor inválido';
                  if (height < AppConstants.minHeight || height > AppConstants.maxHeight) {
                    return 'Altura deve estar entre ${AppConstants.minHeight}m e ${AppConstants.maxHeight}m';
                  }
                  return null;
                },
              ),
              // Preview do IMC
              if (_weightController.text.isNotEmpty && _heightController.text.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildBMIPreview(),
              ],
            ],

            // Idade (apenas leitura)
            if (!_isEditing) _buildAgeInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppConstants.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppConstants.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppConstants.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sexo',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppConstants.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildGenderOption('M', Icons.male, 'Masculino')),
            const SizedBox(width: 12),
            Expanded(child: _buildGenderOption('F', Icons.female, 'Feminino')),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderOption(String gender, IconData icon, String label) {
    final isSelected = _selectedGender == gender;

    return InkWell(
      onTap: _isEditing
          ? () {
        setState(() {
          _selectedGender = gender;
        });
      }
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppConstants.primaryColor.withOpacity(0.1)
              : Colors.grey.shade100,
          border: Border.all(
            color: isSelected ? AppConstants.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? AppConstants.primaryColor : AppConstants.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppConstants.primaryColor : AppConstants.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildBMIPreview() {
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final height = double.tryParse(_heightController.text.replaceAll(',', '.'));

    if (weight == null || height == null || height <= 0) {
      return const SizedBox.shrink();
    }

    final bmi = AppConstants.calculateBMI(weight, height);
    final category = AppConstants.getBMICategory(bmi);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppConstants.successColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.analytics, size: 20, color: AppConstants.successColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seu IMC',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppConstants.textSecondary,
                  ),
                ),
                Text(
                  '${bmi.toStringAsFixed(1)} - $category',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.successColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildAgeInfo() {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppConstants.primaryColor.withOpacity(0.1),
                AppConstants.primaryColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppConstants.primaryColor.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cake, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Idade atual',
                    style: TextStyle(fontSize: 12, color: AppConstants.textSecondary),
                  ),
                  Text(
                    '${_currentUser!.age} anos',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard() {
    final createdDate = _currentUser!.createdAt;
    final daysSinceCreation = DateTime.now().difference(createdDate).inDays;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.analytics, color: AppConstants.successColor, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Estatísticas de Uso',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    Icons.today,
                    'Dias de uso',
                    '$daysSinceCreation',
                    AppConstants.primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    Icons.calendar_month,
                    'Membro desde',
                    '${createdDate.day}/${createdDate.month}/${createdDate.year}',
                    AppConstants.successColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              Icons.update,
              'Última atualização',
              '${_currentUser!.updatedAt.day}/${_currentUser!.updatedAt.month}/${_currentUser!.updatedAt.year} às ${_currentUser!.updatedAt.hour}:${_currentUser!.updatedAt.minute.toString().padLeft(2, '0')}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppConstants.dangerColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.favorite, color: AppConstants.dangerColor, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Saúde e Monitoramento',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildHealthTip(Icons.schedule, 'Meça sua pressão sempre no mesmo horário', 'Preferencialmente pela manhã, em jejum'),
            const SizedBox(height: 12),
            _buildHealthTip(Icons.self_improvement, 'Descanse 5 minutos antes da medição', 'Evite atividades físicas 30 min antes'),
            const SizedBox(height: 12),
            _buildHealthTip(Icons.medical_information, 'Compartilhe seus dados com seu médico', 'Use os relatórios para acompanhamento'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppConstants.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppConstants.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppConstants.textSecondary),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppConstants.textPrimary),
        ),
      ],
    );
  }

  Widget _buildHealthTip(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 16, color: AppConstants.primaryColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppConstants.textPrimary),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: AppConstants.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSaving
            ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : const Text(
          'Salvar Alterações',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSaveButtonSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _buildSaveButton(),
    );
  }
}