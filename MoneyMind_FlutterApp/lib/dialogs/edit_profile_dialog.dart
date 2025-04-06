import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';

class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({Key? key}) : super(key: key);

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _occupationController;
  late TextEditingController _locationController;
  late TextEditingController _dateOfBirthController;
  late TextEditingController _annualIncomeController;
  late TextEditingController _riskToleranceController;

  @override
  void initState() {
    super.initState();
    final profileData = Provider.of<ProfileProvider>(context, listen: false).profileData;

    _nameController = TextEditingController(text: profileData.name);
    _occupationController = TextEditingController(text: profileData.occupation);
    _locationController = TextEditingController(text: profileData.location);
    _dateOfBirthController = TextEditingController(text: profileData.dateOfBirth);
    _annualIncomeController = TextEditingController(text: profileData.annualIncome);
    _riskToleranceController = TextEditingController(text: profileData.riskTolerance);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _occupationController.dispose();
    _locationController.dispose();
    _dateOfBirthController.dispose();
    _annualIncomeController.dispose();
    _riskToleranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(_nameController, 'Name', Icons.person),
            const SizedBox(height: 16),
            _buildTextField(_occupationController, 'Occupation', Icons.work),
            const SizedBox(height: 16),
            _buildTextField(_locationController, 'Location', Icons.location_on),
            const SizedBox(height: 16),
            _buildTextField(_dateOfBirthController, 'Date of Birth', Icons.calendar_today,
                onTap: () => _selectDate(context)),
            const SizedBox(height: 16),
            _buildTextField(_annualIncomeController, 'Annual Income', Icons.wallet),
            const SizedBox(height: 16),
            _buildDropdownField('Risk Tolerance'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            _saveProfile(context);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        VoidCallback? onTap,
      }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onTap: onTap,
      readOnly: onTap != null,
    );
  }

  Widget _buildDropdownField(String label) {
    final riskOptions = ['Low', 'Moderate', 'High'];

    return DropdownButtonFormField(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.trending_up),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      value: _riskToleranceController.text,
      items: riskOptions.map((String option) {
        return DropdownMenuItem(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _riskToleranceController.text = newValue!;
        });
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // 18 years ago
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      // Format date as "19th April 2004"
      final String day = _getDayWithSuffix(picked.day);
      final String month = _getMonthName(picked.month);
      final String formattedDate = '$day $month ${picked.year}';

      setState(() {
        _dateOfBirthController.text = formattedDate;
      });
    }
  }

  String _getDayWithSuffix(int day) {
    if (day >= 11 && day <= 13) {
      return '${day}th';
    }

    switch (day % 10) {
      case 1: return '${day}st';
      case 2: return '${day}nd';
      case 3: return '${day}rd';
      default: return '${day}th';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  void _saveProfile(BuildContext context) {
    final provider = Provider.of<ProfileProvider>(context, listen: false);

    // Update basic info
    provider.updateBasicInfo(
      name: _nameController.text,
      occupation: _occupationController.text,
      location: _locationController.text,
    );

    // Update financial info
    provider.updateFinancialInfo(
      dateOfBirth: _dateOfBirthController.text,
      annualIncome: _annualIncomeController.text,
      riskTolerance: _riskToleranceController.text,
    );
  }
}