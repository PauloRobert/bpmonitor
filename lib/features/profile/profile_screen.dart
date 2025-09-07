import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import '../../shared/models/user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() => _isLoading = true);

      final user = await _dbHelper.getUser();
      if (user != null) {
        setState(() {
          _currentUser = user;
          _nameController.text = user.name;
          _birthDateController.text = user.birthDate;
        });
      }
    } catch (e) {
      _showError('Erro ao carregar dados do usuário');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _currentUser != null
          ? DateTime.parse(_currentUser!.birthDate)
          : DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
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
      final updatedUser = _currentUser!.copyWith(
        name: _nameController.text.trim(),
        birthDate: _birthDateController.text,
        updatedAt: DateTime.now(),
      );

      await _dbHelper.updateUser(updatedUser);

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
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _toggleEdit() {
    setState(() {
      if (_isEditing) {
        // Cancelar edição - restaurar valores originais
        _nameController.text = _currentUser!.name;
        _birthDateController.text = _currentUser!.birthDate;
      }
      _isEditing = !_isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isLoading && _currentUser != null)
            IconButton(
              icon: Icon(
                _isEditing ? Icons.close : Icons.edit,
                color: AppConstants.textPrimary,
              ),
              onPressed: _toggleEdit,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
          ? _buildNoUserState()
          : _buildProfileContent(),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildAvatar(),
            const SizedBox(height: 32),
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildStatisticsCard(),
            if (_isEditing) ...[
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: AppConstants.logoGradient,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              _currentUser!.name.isNotEmpty
                  ? _currentUser!.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        if (_isEditing)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppConstants.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Upload de foto em desenvolvimento'),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informações Pessoais',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // Campo Nome
            TextFormField(
              controller: _nameController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Nome completo',
                prefixIcon: const Icon(Icons.person),
                border: _isEditing ? const OutlineInputBorder() : InputBorder.none,
                filled: !_isEditing,
                fillColor: Colors.grey.shade50,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nome é obrigatório';
                }
                if (value.trim().length < 3) {
                  return 'Nome muito curto';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Campo Data de Nascimento
            TextFormField(
              controller: _birthDateController,
              enabled: _isEditing,
              readOnly: true,
              onTap: _isEditing ? _selectBirthDate : null,
              decoration: InputDecoration(
                labelText: 'Data de nascimento',
                prefixIcon: const Icon(Icons.cake),
                suffixIcon: _isEditing ? const Icon(Icons.calendar_today) : null,
                border: _isEditing ? const OutlineInputBorder() : InputBorder.none,
                filled: !_isEditing,
                fillColor: Colors.grey.shade50,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Data de nascimento é obrigatória';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Idade calculada
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month,
                    color: AppConstants.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Idade: ${_currentUser!.age} anos',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppConstants.primaryColor,
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

  Widget _buildStatisticsCard() {
    final createdDate = _currentUser!.createdAt;
    final daysSinceCreation = DateTime.now().difference(createdDate).inDays;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estatísticas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              Icons.today,
              'Usando o app há',
              '$daysSinceCreation dias',
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              Icons.calendar_today,
              'Cadastro em',
              '${createdDate.day}/${createdDate.month}/${createdDate.year}',
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              Icons.update,
              'Última atualização',
              '${_currentUser!.updatedAt.day}/${_currentUser!.updatedAt.month}/${_currentUser!.updatedAt.year}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppConstants.textSecondary),
        const SizedBox(width: 8),
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

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isSaving
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}