import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _fullNameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.updateProfile(
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
    );

    if (result['success'] == true) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Update failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF2E7D32),
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  _fullNameController.text = user?.fullName ?? '';
                  _phoneController.text = user?.phone ?? '';
                });
              },
              child: const Text(
                'Edit',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Settings
            _buildSection(
              title: 'Profile Settings',
              icon: Icons.person_outline,
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person, color: Color(0xFF2E7D32)),
                        title: const Text('Full Name'),
                        subtitle: _isEditing
                            ? TextFormField(
                                controller: _fullNameController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Name is required';
                                  }
                                  return null;
                                },
                              )
                            : Text(user?.fullName ?? 'Not set'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.email, color: Color(0xFF2E7D32)),
                        title: const Text('Email'),
                        subtitle: Text(user?.email ?? 'Not set'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.phone, color: Color(0xFF2E7D32)),
                        title: const Text('Phone'),
                        subtitle: _isEditing
                            ? TextFormField(
                                controller: _phoneController,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                              )
                            : Text(user?.phone ?? 'Not set'),
                      ),
                      ListTile(
                        leading: const Icon(Icons.admin_panel_settings, color: Color(0xFF2E7D32)),
                        title: const Text('Role'),
                        subtitle: Text(user?.role?.toUpperCase() ?? 'Not set'),
                      ),
                      if (_isEditing)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                  ),
                                  child: const Text('Save'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = false;
                                      final user = context.read<AuthProvider>().user;
                                      _fullNameController.text = user?.fullName ?? '';
                                      _phoneController.text = user?.phone ?? '';
                                    });
                                  },
                                  child: const Text('Cancel'),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Appearance
            _buildSection(
              title: 'Appearance',
              icon: Icons.palette_outlined,
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Toggle dark/light theme'),
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    themeProvider.setDarkMode(value);
                  },
                  activeColor: const Color(0xFF2E7D32),
                ),
                ListTile(
                  leading: const Icon(Icons.color_lens, color: Color(0xFF2E7D32)),
                  title: const Text('Primary Color'),
                  subtitle: const Text('Green (Default)'),
                  trailing: Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // System
            _buildSection(
              title: 'System',
              icon: Icons.settings_outlined,
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Color(0xFF2E7D32)),
                  title: const Text('Version'),
                  subtitle: const Text('1.0.0'),
                ),
                ListTile(
                  leading: const Icon(Icons.build_outlined, color: Color(0xFF2E7D32)),
                  title: const Text('Environment'),
                  subtitle: const Text('Development'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(icon, color: const Color(0xFF2E7D32), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}