import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';

class EditFinancialInfoDialog extends StatefulWidget {
  final int infoIndex;

  const EditFinancialInfoDialog({
    Key? key,
    required this.infoIndex,
  }) : super(key: key);

  @override
  State<EditFinancialInfoDialog> createState() => _EditFinancialInfoDialogState();
}

class _EditFinancialInfoDialogState extends State<EditFinancialInfoDialog> {
  late TextEditingController _controller;
  late String _title;
  late IconData _icon;
  late bool _isDatePicker;
  late bool _isDropdown;

  @override
  void initState() {
    super.initState();
    final profileData = Provider.of<ProfileProvider>(context, listen: false).profileData;

    // Configure based on index
    switch (widget.infoIndex) {
      case 0: // Date of Birth
        _title = 'Date of Birth';
        _icon = Icons.calendar_today;
        _controller = TextEditingController(text: profileData.dateOfBirth);
        _isDatePicker = true;
        _isDropdown = false;
        break;
      case 1: // Annual Income
        _title = 'Annual Income';
        _icon = Icons.wallet;
        _controller = TextEditingController(text: profileData.annualIncome);
        _isDatePicker = false;
        _isDropdown = false;
        break;
      case 2: // Risk Tolerance
        _title = 'Risk Tolerance';
        _icon = Icons.trending_up;
        _controller = TextEditingController(text: profileData.riskTolerance);
        _isDatePicker = false;
        _isDropdown = true;
        break;
      default:
        _title = '';
        _icon = Icons.info;
        _controller = TextEditingController();
        _isDatePicker = false;
        _isDropdown = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit $_title'),
      content: _isDropdown
          ? _buildRiskToleranceDropdown()
          : _buildTextField(),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            _saveChanges(context);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: _title,
        prefixIcon: Icon(_icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      onTap: _isDatePicker ? () => _selectDate(context) : null,
      readOnly: _isDatePicker,
    );
  }

  Widget _buildRiskToleranceDropdown() {
    final riskOptions = ['Low', 'Moderate', 'High'];

    return DropdownButtonFormField(
      decoration: InputDecoration(
        labelText: _title,
        prefixIcon: Icon(_icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      value: _controller.text,
      items: riskOptions.map((String option) {
        return DropdownMenuItem(
          value: option,
          child: Text(option),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _controller.text = newValue!;
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
        _controller.text = formattedDate;
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

  void _saveChanges(BuildContext context) {
    final provider = Provider.of<ProfileProvider>(context, listen: false);

    switch (widget.infoIndex) {
      case 0: // Date of Birth
        provider.updateFinancialInfo(dateOfBirth: _controller.text);
        break;
      case 1: // Annual Income
        provider.updateFinancialInfo(annualIncome: _controller.text);
        break;
      case 2: // Risk Tolerance
        provider.updateFinancialInfo(riskTolerance: _controller.text);
        break;
    }
  }
}