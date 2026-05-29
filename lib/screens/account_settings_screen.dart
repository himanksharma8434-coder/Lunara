import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cycle_provider.dart';
import '../theme/app_theme.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _cycleLengthController;
  late TextEditingController _periodDurationController;
  late TextEditingController _trackedPersonNameController;

  String _selectedGender = 'Female';
  bool _isTrackingForSomeoneElse = false;
  String _trackedPersonRelation = 'Partner';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<CycleProvider>(context, listen: false);
    _nameController = TextEditingController(text: provider.userName);
    _selectedGender = ['Female', 'Male', 'Other'].contains(provider.userGender)
        ? provider.userGender
        : 'Female';
    _ageController = TextEditingController(
        text: provider.age > 0 ? provider.age.toString() : '');
    _heightController = TextEditingController(text: provider.height.toString());
    _weightController = TextEditingController(text: provider.weight.toString());
    _cycleLengthController =
        TextEditingController(text: provider.cycleLength.toString());
    _periodDurationController =
        TextEditingController(text: provider.periodDuration.toString());

    _isTrackingForSomeoneElse = provider.isTrackingForSomeoneElse;
    _trackedPersonNameController =
        TextEditingController(text: provider.trackedPersonName);
    _trackedPersonRelation = [
      'Partner',
      'Mother',
      'Sister',
      'Friend',
      'Daughter',
      'Other'
    ].contains(provider.trackedPersonRelation)
        ? provider.trackedPersonRelation
        : 'Partner';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _cycleLengthController.dispose();
    _periodDurationController.dispose();
    _trackedPersonNameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = Provider.of<CycleProvider>(context, listen: false);

    try {
      await provider.updateProfile(
        name: _nameController.text.trim(),
        gender: _selectedGender,
        age: int.tryParse(_ageController.text) ?? provider.age,
        height: int.tryParse(_heightController.text) ?? provider.height,
        weight: int.tryParse(_weightController.text) ?? provider.weight,
        cycleLength:
            int.tryParse(_cycleLengthController.text) ?? provider.cycleLength,
        periodDuration: int.tryParse(_periodDurationController.text) ??
            provider.periodDuration,
        isTrackingForSomeoneElse: _isTrackingForSomeoneElse,
        trackedPersonName: _trackedPersonNameController.text.trim(),
        trackedPersonRelation: _trackedPersonRelation,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully'),
            backgroundColor: AppTheme.primary(context),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: Text(
          'Account Settings',
          style: TextStyle(color: AppTheme.textDark(context)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textDark(context)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, 'Personal Information'),
                const SizedBox(height: 16),
                _buildTextField(
                  context,
                  controller: _nameController,
                  label: 'Name',
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildGenderDropdown(context),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        context,
                        controller: _ageController,
                        label: 'Age',
                        icon: Icons.cake_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildTrackingForSomeoneElseSection(context),
                const SizedBox(height: 32),
                _buildSectionHeader(context, 'Body Metrics'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        context,
                        controller: _heightController,
                        label: 'Height (cm)',
                        icon: Icons.height,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        context,
                        controller: _weightController,
                        label: 'Weight (kg)',
                        icon: Icons.monitor_weight_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        context,
                        controller: _cycleLengthController,
                        label: 'Cycle (days)',
                        icon: Icons.loop,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        context,
                        controller: _periodDurationController,
                        label: 'Period (days)',
                        icon: Icons.water_drop_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildSectionHeader(context, 'Critical Data'),
                const SizedBox(height: 16),
                _buildHighlightedDatePicker(context),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary(context),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textDark(context),
      ),
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: AppTheme.textDark(context)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.textLight(context)),
        prefixIcon: Icon(icon, color: AppTheme.primary(context)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primary(context), width: 1.5),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Required';
        }
        return null;
      },
    );
  }

  Widget _buildGenderDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      style: TextStyle(color: AppTheme.textDark(context)),
      decoration: InputDecoration(
        labelText: 'Gender',
        labelStyle: TextStyle(color: AppTheme.textLight(context)),
        prefixIcon:
            Icon(Icons.people_outline, color: AppTheme.primary(context)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primary(context), width: 1.5),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'Female', child: Text('Female')),
        DropdownMenuItem(value: 'Male', child: Text('Male')),
        DropdownMenuItem(value: 'Other', child: Text('Other')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedGender = value;
            if (value == 'Male') {
              _isTrackingForSomeoneElse = true;
            }
          });
        }
      },
    );
  }

  Widget _buildTrackingForSomeoneElseSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: Text(
            'Track for someone else',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark(context),
            ),
          ),
          subtitle: Text(
            'Use this app for a partner, relative, or friend',
            style: TextStyle(color: AppTheme.textLight(context), fontSize: 13),
          ),
          value: _isTrackingForSomeoneElse,
          activeColor: AppTheme.primary(context),
          contentPadding: EdgeInsets.zero,
          onChanged: (bool value) {
            setState(() {
              _isTrackingForSomeoneElse = value;
            });
          },
        ),
        if (_isTrackingForSomeoneElse) ...[
          const SizedBox(height: 16),
          _buildTextField(
            context,
            controller: _trackedPersonNameController,
            label: "Their Name",
            icon: Icons.person_pin,
          ),
          const SizedBox(height: 16),
          _buildRelationDropdown(context),
        ]
      ],
    );
  }

  Widget _buildRelationDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: _trackedPersonRelation,
      style: TextStyle(color: AppTheme.textDark(context)),
      decoration: InputDecoration(
        labelText: 'Relationship to you',
        labelStyle: TextStyle(color: AppTheme.textLight(context)),
        prefixIcon: Icon(Icons.family_restroom_outlined,
            color: AppTheme.primary(context)),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppTheme.primary(context), width: 1.5),
        ),
      ),
      items: const [
        DropdownMenuItem(value: 'Partner', child: Text('Partner')),
        DropdownMenuItem(value: 'Mother', child: Text('Mother')),
        DropdownMenuItem(value: 'Sister', child: Text('Sister')),
        DropdownMenuItem(value: 'Friend', child: Text('Friend')),
        DropdownMenuItem(value: 'Daughter', child: Text('Daughter')),
        DropdownMenuItem(value: 'Other', child: Text('Other')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _trackedPersonRelation = value;
          });
        }
      },
    );
  }

  Widget _buildHighlightedDatePicker(BuildContext context) {
    final provider = Provider.of<CycleProvider>(context);
    final lastDate = provider.lastPeriodDate;
    final dateStr = lastDate != null
        ? "${lastDate.day} ${_getMonth(lastDate.month)} ${lastDate.year}"
        : 'Not set';

    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: lastDate ?? DateTime.now(),
          firstDate: DateTime.now().subtract(const Duration(days: 90)),
          lastDate: DateTime.now(),
          builder: (context, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: isDark
                    ? ColorScheme.dark(
                        primary: AppTheme.primary(context),
                        onPrimary: Colors.white,
                        surface: const Color(0xFF1E1E1E),
                        onSurface: Colors.white,
                      )
                    : ColorScheme.light(
                        primary: AppTheme.primary(context),
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: const Color(0xFF3E2723),
                      ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          provider.updateLastPeriodDate(picked);
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primary(context),
              AppTheme.primary(context).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary(context).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_month, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Last Period Date',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_calendar_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  String _getMonth(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month];
  }
}
