import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

class EditTaskDialog extends StatefulWidget {
  final Map<String, dynamic> task;
  final VoidCallback onUpdated;

  const EditTaskDialog({
    super.key,
    required this.task,
    required this.onUpdated,
  });

  @override
  State<EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<EditTaskDialog> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late String selectedPriority;
  late String selectedStatus;
  late int? assignedTo;
  late DateTime? dueDate;
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> officers = [];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.task['title']);
    descriptionController = TextEditingController(text: widget.task['description']);
    selectedPriority = widget.task['priority'] ?? 'Medium';
    selectedStatus = widget.task['status'] ?? 'pending';
    assignedTo = widget.task['assigned_to'];
    dueDate = widget.task['due_date'];
    _loadOfficers();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadOfficers() async {
    try {
      final apiService = context.read<AuthProvider>().apiService;
      final response = await apiService.get('/users/admin/all?role=officer');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> usersData = response.data['data']['users'] ?? [];
        setState(() {
          officers = usersData.map((u) => {
            'id': u['id'],
            'name': u['full_name'] ?? 'Unknown',
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading officers: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final apiService = context.read<AuthProvider>().apiService;
      final response = await apiService.put('/tasks/${widget.task['id']}', data: {
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'priority': selectedPriority,
        'status': selectedStatus,
        'assigned_to': assignedTo,
        'due_date': dueDate?.toIso8601String(),
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        if (!mounted) return;
        Navigator.pop(context);
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? 'Failed to update task'),
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
      title: const Text('Edit Task'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title *',
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
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: ['Low', 'Medium', 'High'].map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedPriority = value!;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                ),
                items: ['pending', 'assigned', 'in_progress', 'completed', 'cancelled'].map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status.split('_').map((word) => 
                      word[0].toUpperCase() + word.substring(1)
                    ).join(' ')),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value!;
                  });
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: assignedTo,
                decoration: const InputDecoration(
                  labelText: 'Assign To',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Unassigned'),
                  ),
                  ...officers.map((officer) {
                    return DropdownMenuItem<int?>(
                      value: officer['id'],
                      child: Text(officer['name']),
                    );
                  }).toList(),
                ],
                onChanged: (value) {
                  setState(() {
                    assignedTo = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Due Date'),
                subtitle: Text(
                  dueDate != null
                      ? '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'
                      : 'Select date',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: dueDate ?? DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      dueDate = date;
                    });
                  }
                },
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