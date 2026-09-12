import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

class EditAlertDialog extends StatefulWidget {
  final Map<String, dynamic> alert;
  final VoidCallback onUpdated;

  const EditAlertDialog({
    super.key,
    required this.alert,
    required this.onUpdated,
  });

  @override
  State<EditAlertDialog> createState() => _EditAlertDialogState();
}

class _EditAlertDialogState extends State<EditAlertDialog> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController categoryController;
  late TextEditingController regionController;
  late String selectedSeverity;
  late DateTime? startDate;
  late DateTime? endDate;
  late bool isActive;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.alert['title']);
    descriptionController = TextEditingController(text: widget.alert['description']);
    categoryController = TextEditingController(text: widget.alert['category'] ?? 'General');
    regionController = TextEditingController(text: widget.alert['region'] ?? '');
    selectedSeverity = widget.alert['severity'] ?? 'Medium';
    startDate = widget.alert['start_date'];
    endDate = widget.alert['end_date'];
    isActive = widget.alert['is_active'] ?? true;
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    regionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final apiService = context.read<AuthProvider>().apiService;
      final response = await apiService.put('/alerts/${widget.alert['id']}', data: {
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'category': categoryController.text.trim(),
        'severity': selectedSeverity,
        'region': regionController.text.trim().isEmpty ? null : regionController.text.trim(),
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'is_active': isActive,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        if (!mounted) return;
        Navigator.pop(context);
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? 'Failed to update alert'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Alert'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Alert Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Title is required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Description is required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedSeverity,
                decoration: const InputDecoration(
                  labelText: 'Severity',
                  border: OutlineInputBorder(),
                ),
                items: ['Low', 'Medium', 'High', 'Critical'].map((severity) {
                  return DropdownMenuItem(
                    value: severity,
                    child: Text(severity),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedSeverity = value!;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: regionController,
                decoration: const InputDecoration(
                  labelText: 'Region',
                  border: OutlineInputBorder(),
                  hintText: 'Leave blank for all regions',
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Start Date'),
                subtitle: Text(
                  startDate != null
                      ? '${startDate!.day}/${startDate!.month}/${startDate!.year}'
                      : 'Select date',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: startDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      startDate = date;
                    });
                  }
                },
              ),
              ListTile(
                title: const Text('End Date (Optional)'),
                subtitle: Text(
                  endDate != null
                      ? '${endDate!.day}/${endDate!.month}/${endDate!.year}'
                      : 'Not set',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: endDate ?? DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      endDate = date;
                    });
                  }
                },
              ),
              SwitchListTile(
                title: const Text('Active'),
                value: isActive,
                onChanged: (value) {
                  setState(() {
                    isActive = value;
                  });
                },
                activeColor: const Color(0xFF2E7D32),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
          ),
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}