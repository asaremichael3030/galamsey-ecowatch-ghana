import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class AdminInvestigationsScreen extends StatefulWidget {
  const AdminInvestigationsScreen({super.key});

  @override
  State<AdminInvestigationsScreen> createState() => _AdminInvestigationsScreenState();
}

class _AdminInvestigationsScreenState extends State<AdminInvestigationsScreen> {
  List<Map<String, dynamic>> _investigations = [];
  bool _isLoading = true;
  String _selectedStatus = 'All';
  final List<String> _statuses = ['All', 'not_started', 'active', 'completed', 'closed'];

  @override
  void initState() {
    super.initState();
    _loadInvestigations();
  }

  Future<void> _loadInvestigations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = context.read<AuthProvider>().apiService;
      final response = await apiService.get('/investigations');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data']['investigations'] ?? [];
        setState(() {
          _investigations = data.map((item) => {
            'id': item['id'],
            'title': item['title'] ?? 'Untitled Investigation',
            'report_id': item['report_id'],
            'report_title': item['report_title'],
            'report_code': item['report_code'],
            'officer_id': item['officer_id'],
            'officer_name': item['officer_name'] ?? 'Unassigned',
            'findings': item['findings'] ?? '',
            'notes': item['notes'] ?? '',
            'recommendation': item['recommendation'] ?? '',
            'status': item['status'] ?? 'not_started',
            'started_at': item['started_at'] != null ? DateTime.parse(item['started_at']) : null,
            'completed_at': item['completed_at'] != null ? DateTime.parse(item['completed_at']) : null,
            'created_at': item['created_at'] != null ? DateTime.parse(item['created_at']) : DateTime.now(),
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading investigations: $e');
      setState(() {
        _investigations = [
          {
            'id': 1,
            'title': 'Offin River Pollution Investigation',
            'report_id': 1,
            'report_title': 'River Pollution Report',
            'report_code': 'ECO-2024-000001',
            'officer_id': 2,
            'officer_name': 'Jane Smith',
            'findings': 'Water samples show high mercury levels',
            'notes': 'Need to interview local fishermen',
            'recommendation': 'Refer to Environmental Protection Agency',
            'status': 'active',
            'started_at': DateTime.now().subtract(const Duration(days: 2)),
            'completed_at': null,
            'created_at': DateTime.now().subtract(const Duration(days: 3)),
          },
          {
            'id': 2,
            'title': 'Illegal Mining Site Investigation',
            'report_id': 2,
            'report_title': 'Illegal Mining Report',
            'report_code': 'ECO-2024-000002',
            'officer_id': null,
            'officer_name': 'Unassigned',
            'findings': '',
            'notes': 'Site visit required',
            'recommendation': '',
            'status': 'not_started',
            'started_at': null,
            'completed_at': null,
            'created_at': DateTime.now().subtract(const Duration(days: 1)),
          },
        ];
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _createInvestigation() async {
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedStatus = 'not_started';
    int? reportId;
    int? officerId;

    final apiService = context.read<AuthProvider>().apiService;
    List<Map<String, dynamic>> reports = [];
    List<Map<String, dynamic>> officers = [];

    try {
      final reportsResponse = await apiService.get('/reports/admin/all?status=pending');
      if (reportsResponse.statusCode == 200 && reportsResponse.data['success'] == true) {
        final List<dynamic> reportsData = reportsResponse.data['data']['reports'] ?? [];
        reports = reportsData.map((r) => {
          'id': r['id'],
          'title': r['title'] ?? 'Untitled Report',
          'code': r['report_code'] ?? '',
        }).toList();
      }

      final usersResponse = await apiService.get('/users/admin/all?role=officer');
      if (usersResponse.statusCode == 200 && usersResponse.data['success'] == true) {
        final List<dynamic> usersData = usersResponse.data['data']['users'] ?? [];
        officers = usersData.map((u) => {
          'id': u['id'],
          'name': u['full_name'] ?? 'Unknown',
        }).toList();
      }
    } catch (e) {
      print('Error loading data: $e');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start New Investigation'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int?>(
                  value: reportId,
                  decoration: const InputDecoration(
                    labelText: 'Select Report *',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    ...reports.map((report) {
                      return DropdownMenuItem<int?>(
                        value: report['id'],
                        child: Text('${report['code']} - ${report['title']}'),
                      );
                    }).toList(),
                  ],
                  validator: (value) {
                    if (value == null) return 'Please select a report';
                    return null;
                  },
                  onChanged: (value) {
                    reportId = value;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Investigation Title *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Title is required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  value: officerId,
                  decoration: const InputDecoration(
                    labelText: 'Assign Officer',
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
                    officerId = value;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Initial Notes',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: ['not_started', 'active', 'completed', 'closed'].map((status) {
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
                final response = await apiService.post('/investigations', data: {
                  'report_id': reportId,
                  'title': titleController.text.trim(),
                  'officer_id': officerId,
                  'notes': notesController.text.trim(),
                  'status': selectedStatus,
                });
                
                if (response.statusCode == 201 && response.data['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Investigation started successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadInvestigations();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response.data['message'] ?? 'Failed to create investigation'),
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
            child: const Text('Start Investigation'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateInvestigationStatus(int id, String newStatus) async {
    try {
      final apiService = context.read<AuthProvider>().apiService;
      final response = await apiService.patch('/investigations/$id/status', data: {
        'status': newStatus,
      });
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _loadInvestigations();
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

  List<Map<String, dynamic>> _getFilteredInvestigations() {
    if (_selectedStatus == 'All') return _investigations;
    return _investigations.where((inv) => inv['status'] == _selectedStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredInvestigations();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Investigations'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF2E7D32),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createInvestigation,
            tooltip: 'Start Investigation',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvestigations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _statuses.map((status) {
                        final isSelected = _selectedStatus == status;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(status.split('_').map((word) => 
                              word[0].toUpperCase() + word.substring(1)
                            ).join(' ')),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedStatus = selected ? status : 'All';
                              });
                            },
                            backgroundColor: Colors.white,
                            selectedColor: const Color(0xFF2E7D32).withOpacity(0.2),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${filtered.length} investigations found',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No investigations found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Start a new investigation for a report',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _createInvestigation,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                ),
                                child: const Text('Start Investigation'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final inv = filtered[index];
                            return _buildInvestigationCard(inv);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildInvestigationCard(Map<String, dynamic> inv) {
    final status = inv['status'] ?? 'not_started';
    final statusDisplay = status.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
    
    Color statusColor;
    switch (status) {
      case 'not_started':
        statusColor = Colors.grey;
        break;
      case 'active':
        statusColor = Colors.blue;
        break;
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'closed':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
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
                    inv['title'],
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
            if (inv['report_code'] != null)
              Row(
                children: [
                  Icon(
                    Icons.assignment,
                    size: 14,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Report: ${inv['report_code']} - ${inv['report_title']}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            if (inv['findings'] != null && inv['findings'].isNotEmpty)
              Text(
                inv['findings'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            if (inv['notes'] != null && inv['notes'].isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Notes: ${inv['notes']}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _buildInfoChip(Icons.person, inv['officer_name'] ?? 'Unassigned'),
                if (inv['started_at'] != null)
                  _buildInfoChip(
                    Icons.calendar_today,
                    'Started: ${inv['started_at'].day}/${inv['started_at'].month}/${inv['started_at'].year}',
                  ),
                if (inv['completed_at'] != null)
                  _buildInfoChip(
                    Icons.check_circle,
                    'Completed: ${inv['completed_at'].day}/${inv['completed_at'].month}/${inv['completed_at'].year}',
                    color: Colors.green,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (status != 'completed' && status != 'closed')
                  DropdownButton<String>(
                    value: status,
                    items: ['not_started', 'active', 'completed', 'closed'].map((s) {
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
                        _updateInvestigationStatus(inv['id'], newStatus);
                      }
                    },
                    underline: const SizedBox(),
                    icon: const Icon(Icons.edit, size: 18),
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}