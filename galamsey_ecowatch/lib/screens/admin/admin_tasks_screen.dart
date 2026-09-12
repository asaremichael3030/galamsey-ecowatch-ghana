import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'admin_edit_task_dialog.dart';

class AdminTasksScreen extends StatefulWidget {
  const AdminTasksScreen({super.key});

  @override
  State<AdminTasksScreen> createState() => _AdminTasksScreenState();
}

class _AdminTasksScreenState extends State<AdminTasksScreen> {
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  String _selectedStatus = 'All';
  final List<String> _statuses = ['All', 'Pending', 'Assigned', 'In Progress', 'Completed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = context.read<AuthProvider>().apiService;
      final response = await apiService.get('/tasks');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> tasksData = response.data['data']['tasks'] ?? [];
        setState(() {
          _tasks = tasksData.map((task) => {
            'id': task['id'],
            'title': task['title'] ?? 'Untitled Task',
            'description': task['description'] ?? '',
            'priority': task['priority'] ?? 'Medium',
            'status': task['status'] ?? 'pending',
            'assigned_to': task['assigned_to'],
            'assigned_name': task['assigned_name'] ?? 'Unassigned',
            'due_date': task['due_date'] != null ? DateTime.parse(task['due_date']) : null,
            'report_id': task['report_id'],
            'report_title': task['report_title'],
            'created_at': task['created_at'] != null ? DateTime.parse(task['created_at']) : DateTime.now(),
            'completed_at': task['completed_at'] != null ? DateTime.parse(task['completed_at']) : null,
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading tasks: $e');
      setState(() {
        _tasks = [
          {
            'id': 1,
            'title': 'Investigate Offin River Pollution',
            'description': 'Visit Offin River site and collect water samples for testing.',
            'priority': 'High',
            'status': 'in_progress',
            'assigned_to': 2,
            'assigned_name': 'Jane Smith',
            'due_date': DateTime.now().add(const Duration(days: 3)),
            'report_id': 1,
            'report_title': 'River Pollution Report',
            'created_at': DateTime.now().subtract(const Duration(days: 2)),
            'completed_at': null,
          },
          {
            'id': 2,
            'title': 'Community Engagement Meeting',
            'description': 'Organize meeting with community leaders about illegal mining awareness.',
            'priority': 'Medium',
            'status': 'pending',
            'assigned_to': null,
            'assigned_name': 'Unassigned',
            'due_date': DateTime.now().add(const Duration(days: 5)),
            'report_id': null,
            'report_title': null,
            'created_at': DateTime.now().subtract(const Duration(days: 1)),
            'completed_at': null,
          },
        ];
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _createTask() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedPriority = 'Medium';
    String selectedStatus = 'pending';
    DateTime? dueDate;
    int? assignedTo;
    int? reportId;

    final apiService = context.read<AuthProvider>().apiService;
    List<Map<String, dynamic>> officers = [];
    List<Map<String, dynamic>> reports = [];

    try {
      final usersResponse = await apiService.get('/users/admin/all?role=officer');
      if (usersResponse.statusCode == 200 && usersResponse.data['success'] == true) {
        final List<dynamic> usersData = usersResponse.data['data']['users'] ?? [];
        officers = usersData.map((user) => {
          'id': user['id'],
          'name': user['full_name'] ?? 'Unknown',
        }).toList();
      }

      final reportsResponse = await apiService.get('/reports/admin/all?status=pending');
      if (reportsResponse.statusCode == 200 && reportsResponse.data['success'] == true) {
        final List<dynamic> reportsData = reportsResponse.data['data']['reports'] ?? [];
        reports = reportsData.map((report) => {
          'id': report['id'],
          'title': report['title'] ?? 'Untitled Report',
        }).toList();
      }
    } catch (e) {
      print('Error loading data for task creation: $e');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Task'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
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
                    return DropdownMenuItem<String>(
                      value: priority,
                      child: Text(priority),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedPriority = value!;
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
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status.split('_').map((word) => 
                        word[0].toUpperCase() + word.substring(1)
                      ).join(' ')),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedStatus = value!;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  value: assignedTo,
                  decoration: const InputDecoration(
                    labelText: 'Assign To (Optional)',
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
                    assignedTo = value;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  value: reportId,
                  decoration: const InputDecoration(
                    labelText: 'Related Report (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('No related report'),
                    ),
                    ...reports.map((report) {
                      return DropdownMenuItem<int?>(
                        value: report['id'],
                        child: Text(report['title']),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    reportId = value;
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
                      initialDate: DateTime.now().add(const Duration(days: 7)),
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
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              
              Navigator.pop(context);
              
              try {
                final apiService = context.read<AuthProvider>().apiService;
                final response = await apiService.post('/tasks', data: {
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'priority': selectedPriority,
                  'status': selectedStatus,
                  'assigned_to': assignedTo,
                  'report_id': reportId,
                  'due_date': dueDate?.toIso8601String(),
                });
                
                if (response.statusCode == 201 && response.data['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Task created successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadTasks();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response.data['message'] ?? 'Failed to create task'),
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text('Create Task'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateTaskStatus(int taskId, String newStatus) async {
    try {
      final apiService = context.read<AuthProvider>().apiService;
      final response = await apiService.patch('/tasks/$taskId/status', data: {
        'status': newStatus,
      });
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task status updated'),
            backgroundColor: Colors.green,
          ),
        );
        _loadTasks();
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

  List<Map<String, dynamic>> _getFilteredTasks() {
    if (_selectedStatus == 'All') return _tasks;
    return _tasks.where((task) {
      final status = task['status'] ?? 'pending';
      final statusDisplay = status.split('_').map((word) => 
        word[0].toUpperCase() + word.substring(1)
      ).join(' ');
      return statusDisplay == _selectedStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _getFilteredTasks();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Manage Tasks'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF2E7D32),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task),
            onPressed: _createTask,
            tooltip: 'Create Task',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Status filter
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _statuses.map((status) {
                        final isSelected = _selectedStatus == status;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(status),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedStatus = selected ? status : 'All';
                              });
                            },
                            backgroundColor: Colors.white,
                            selectedColor: const Color(0xFF2E7D32).withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[600],
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                // Task count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${filteredTasks.length} tasks found',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                
                // Tasks list
                Expanded(
                  child: filteredTasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.task_alt,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No tasks found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create a new task to assign work',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _createTask,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                ),
                                child: const Text('Create Task'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            return _buildTaskCard(task);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final status = task['status'] ?? 'pending';
    final priority = task['priority'] ?? 'Medium';
    final statusDisplay = status.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
    
    Color statusColor;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'assigned':
        statusColor = Colors.blue;
        break;
      case 'in_progress':
        statusColor = Colors.purple;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    Color priorityColor;
    switch (priority) {
      case 'High':
        priorityColor = Colors.red;
        break;
      case 'Medium':
        priorityColor = Colors.orange;
        break;
      case 'Low':
        priorityColor = Colors.green;
        break;
      default:
        priorityColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusDisplay,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task['description'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildInfoChip(Icons.flag, priority, color: priorityColor),
                _buildInfoChip(Icons.person, task['assigned_name'] ?? 'Unassigned'),
                if (task['report_title'] != null)
                  _buildInfoChip(Icons.assignment, 'Report: ${task['report_title']}'),
                if (task['due_date'] != null)
                  _buildInfoChip(
                    Icons.calendar_today,
                    'Due: ${task['due_date'].day}/${task['due_date'].month}/${task['due_date'].year}',
                  ),
                if (task['completed_at'] != null)
                  _buildInfoChip(
                    Icons.check_circle,
                    'Completed: ${task['completed_at'].day}/${task['completed_at'].month}/${task['completed_at'].year}',
                    color: Colors.green,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status != 'completed' && status != 'cancelled')
                  DropdownButton<String>(
                    value: status,
                    items: ['pending', 'assigned', 'in_progress', 'completed', 'cancelled'].map((s) {
                      final display = s.split('_').map((word) => 
                        word[0].toUpperCase() + word.substring(1)
                      ).join(' ');
                      return DropdownMenuItem<String>(
                        value: s,
                        child: Text(display),
                      );
                    }).toList(),
                    onChanged: (newStatus) {
                      if (newStatus != null) {
                        _updateTaskStatus(task['id'], newStatus);
                      }
                    },
                    underline: const SizedBox(),
                    icon: const Icon(Icons.edit, size: 18),
                  ),
                const SizedBox(width: 8),
                // Edit Button
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => EditTaskDialog(
                        task: task,
                        onUpdated: _loadTasks,
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text(
                    'Edit',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, {Color color = Colors.grey}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}