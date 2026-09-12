import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import 'admin_edit_alert_dialog.dart';

class AdminAlertsScreen extends StatefulWidget {
  const AdminAlertsScreen({super.key});

  @override
  State<AdminAlertsScreen> createState() => _AdminAlertsScreenState();
}

class _AdminAlertsScreenState extends State<AdminAlertsScreen> {
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  String _selectedStatus = 'All';
  final List<String> _statuses = ['All', 'Active', 'Inactive'];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = context.read<AuthProvider>().apiService;
      final response = await apiService.get('/alerts');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> alertsData = response.data['data']['alerts'] ?? [];
        setState(() {
          _alerts = alertsData.map((alert) => {
            'id': alert['id'],
            'title': alert['title'] ?? 'Untitled Alert',
            'description': alert['description'] ?? '',
            'category': alert['category'] ?? 'General',
            'severity': alert['severity'] ?? 'Medium',
            'region': alert['region'] ?? 'All Regions',
            'start_date': alert['start_date'] != null ? DateTime.parse(alert['start_date']) : null,
            'end_date': alert['end_date'] != null ? DateTime.parse(alert['end_date']) : null,
            'is_active': alert['is_active'] ?? true,
            'created_at': alert['created_at'] != null ? DateTime.parse(alert['created_at']) : DateTime.now(),
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading alerts: $e');
      // Fallback sample data
      setState(() {
        _alerts = [
          {
            'id': 1,
            'title': 'Heavy Rainfall Warning',
            'description': 'Heavy rainfall expected in Ashanti Region. Possible flooding in low-lying areas.',
            'category': 'Weather',
            'severity': 'High',
            'region': 'Ashanti Region',
            'start_date': DateTime.now(),
            'end_date': DateTime.now().add(const Duration(days: 2)),
            'is_active': true,
            'created_at': DateTime.now(),
          },
          {
            'id': 2,
            'title': 'Illegal Mining Alert',
            'description': 'Suspected illegal mining activities reported near Offin River.',
            'category': 'Mining',
            'severity': 'Critical',
            'region': 'Western Region',
            'start_date': DateTime.now(),
            'end_date': null,
            'is_active': true,
            'created_at': DateTime.now(),
          },
        ];
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _createAlert() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final categoryController = TextEditingController();
    final regionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedSeverity = 'Medium';
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Alert'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
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
                    hintText: 'e.g., Weather, Mining, Health',
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
                    selectedSeverity = value!;
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
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
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
                      initialDate: DateTime.now().add(const Duration(days: 7)),
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
                final response = await apiService.post('/alerts', data: {
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'category': categoryController.text.trim(),
                  'severity': selectedSeverity,
                  'region': regionController.text.trim().isEmpty ? null : regionController.text.trim(),
                  'start_date': startDate?.toIso8601String(),
                  'end_date': endDate?.toIso8601String(),
                });
                
                if (response.statusCode == 201 && response.data['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alert created successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadAlerts();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response.data['message'] ?? 'Failed to create alert'),
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
            child: const Text('Create Alert'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAlertStatus(int alertId, bool currentStatus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentStatus ? 'Deactivate Alert' : 'Activate Alert'),
        content: Text('Are you sure you want to ${currentStatus ? 'deactivate' : 'activate'} this alert?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              currentStatus ? 'Deactivate' : 'Activate',
              style: TextStyle(
                color: currentStatus ? Colors.orange : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final apiService = context.read<AuthProvider>().apiService;
        final response = await apiService.put('/alerts/$alertId', data: {
          'is_active': !currentStatus,
        });
        
        if (response.statusCode == 200 && response.data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Alert ${currentStatus ? 'deactivated' : 'activated'} successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadAlerts();
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
  }

  List<Map<String, dynamic>> _getFilteredAlerts() {
    if (_selectedStatus == 'All') return _alerts;
    final isActive = _selectedStatus == 'Active';
    return _alerts.where((alert) => alert['is_active'] == isActive).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredAlerts = _getFilteredAlerts();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Manage Alerts'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF2E7D32),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert),
            onPressed: _createAlert,
            tooltip: 'Create Alert',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAlerts,
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
                
                // Alert count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${filteredAlerts.length} alerts found',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                
                // Alerts list
                Expanded(
                  child: filteredAlerts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No alerts found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Create a new alert to notify users',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _createAlert,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                ),
                                child: const Text('Create Alert'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredAlerts.length,
                          itemBuilder: (context, index) {
                            final alert = filteredAlerts[index];
                            return _buildAlertCard(alert);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final isActive = alert['is_active'] ?? true;
    final severity = alert['severity'] ?? 'Medium';
    
    Color severityColor;
    switch (severity) {
      case 'Low':
        severityColor = Colors.green;
        break;
      case 'High':
        severityColor = Colors.orange;
        break;
      case 'Critical':
        severityColor = Colors.red;
        break;
      default:
        severityColor = Colors.blue;
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
                    alert['title'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              alert['description'],
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
                _buildInfoChip(Icons.category, alert['category'] ?? 'General'),
                _buildInfoChip(Icons.warning, severity, color: severityColor),
                if (alert['region'] != null)
                  _buildInfoChip(Icons.location_on, alert['region']),
                _buildInfoChip(
                  Icons.calendar_today,
                  alert['start_date'] != null
                      ? '${alert['start_date'].day}/${alert['start_date'].month}/${alert['start_date'].year}'
                      : 'No date',
                ),
                if (alert['end_date'] != null)
                  _buildInfoChip(
                    Icons.calendar_today,
                    'Until ${alert['end_date'].day}/${alert['end_date'].month}/${alert['end_date'].year}',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _toggleAlertStatus(alert['id'], isActive),
                  style: TextButton.styleFrom(
                    foregroundColor: isActive ? Colors.orange : Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    isActive ? 'Deactivate' : 'Activate',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => EditAlertDialog(
                        alert: alert,
                        onUpdated: _loadAlerts,
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