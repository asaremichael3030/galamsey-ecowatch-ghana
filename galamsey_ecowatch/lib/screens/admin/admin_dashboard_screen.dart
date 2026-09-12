import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/notification_provider.dart';
import 'admin_reports_screen.dart';
import 'admin_users_screen.dart';
import 'admin_alerts_screen.dart';
import 'admin_tasks_screen.dart';
import 'admin_education_screen.dart';
import 'admin_news_screen.dart';
import 'admin_analytics_screen.dart';
import 'admin_settings_screen.dart';
import 'admin_map_screen.dart';
import 'admin_investigations_screen.dart';
import '../../screens/notifications_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  bool _isSidebarOpen = true;

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard, 'label': 'Dashboard'},
    {'icon': Icons.assignment, 'label': 'Reports'},
    {'icon': Icons.people, 'label': 'Users'},
    {'icon': Icons.map, 'label': 'Map'},
    {'icon': Icons.notifications, 'label': 'Alerts'},
    {'icon': Icons.task, 'label': 'Tasks'},
    {'icon': Icons.search, 'label': 'Investigations'},
    {'icon': Icons.school, 'label': 'Education'},
    {'icon': Icons.article, 'label': 'News'},
    {'icon': Icons.analytics, 'label': 'Analytics'},
    {'icon': Icons.settings, 'label': 'Settings'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadAdminReports();
      context.read<ReportProvider>().loadAdminStats();
      context.read<NotificationProvider>().refreshUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final reportProvider = context.watch<ReportProvider>();

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          _buildSidebar(authProvider),
          
          // Main content
          Expanded(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(authProvider),
                
                // Content
                Expanded(
                  child: _buildContent(reportProvider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(AuthProvider authProvider) {
    return Container(
      width: _isSidebarOpen ? 260 : 60,
      decoration: const BoxDecoration(
        color: Color(0xFF1B5E20),
      ),
      child: Column(
        children: [
          // Logo
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.eco,
                    color: Color(0xFF2E7D32),
                    size: 24,
                  ),
                ),
                if (_isSidebarOpen) ...[
                  const SizedBox(width: 12),
                  const Text(
                    'EcoWatch',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          
          // Menu items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final isSelected = _selectedIndex == index;
                return ListTile(
                  leading: Icon(
                    item['icon'] as IconData,
                    color: isSelected ? Colors.white : Colors.white70,
                    size: 22,
                  ),
                  title: _isSidebarOpen
                      ? Text(
                          item['label'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        )
                      : null,
                  selected: isSelected,
                  selectedTileColor: const Color(0xFF388E3C),
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                );
              },
            ),
          ),
          
          // Toggle button
          IconButton(
            onPressed: () {
              setState(() {
                _isSidebarOpen = !_isSidebarOpen;
              });
            },
            icon: Icon(
              _isSidebarOpen ? Icons.chevron_left : Icons.chevron_right,
              color: Colors.white70,
            ),
          ),
          
          const Divider(color: Colors.white24),
          
          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white70),
            title: _isSidebarOpen
                ? const Text(
                    'Logout',
                    style: TextStyle(color: Colors.white70),
                  )
                : null,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await context.read<AuthProvider>().logout();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(AuthProvider authProvider) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  authProvider.user?.role?.toUpperCase() ?? 'ADMIN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Notification button with badge
              Consumer<NotificationProvider>(
                builder: (context, notificationProvider, child) {
                  return Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationsScreen(),
                            ),
                          ).then((_) {
                            // Refresh unread count when coming back
                            notificationProvider.refreshUnreadCount();
                          });
                        },
                        icon: const Icon(Icons.notifications_outlined),
                      ),
                      if (notificationProvider.unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              notificationProvider.unreadCount > 9 
                                  ? '9+' 
                                  : notificationProvider.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: Colors.green[100],
                child: Text(
                  authProvider.user?.fullName?.substring(0, 1).toUpperCase() ?? 'A',
                  style: const TextStyle(
                    color: Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (_isSidebarOpen && authProvider.user != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      authProvider.user!.fullName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      authProvider.user!.email,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ReportProvider reportProvider) {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboard(reportProvider);
      case 1:
        return const AdminReportsScreen();
      case 2:
        return const AdminUsersScreen();
      case 3:
        return const AdminMapScreen();
      case 4:
        return const AdminAlertsScreen();
      case 5:
        return const AdminTasksScreen();
      case 6:
        return const AdminInvestigationsScreen();
      case 7:
        return const AdminEducationScreen();
      case 8:
        return const AdminNewsScreen();
      case 9:
        return const AdminAnalyticsScreen();
      case 10:
        return const AdminSettingsScreen();
      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.developer_mode,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Page under development',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildDashboard(ReportProvider reportProvider) {
    final stats = [
      {'label': 'Total Reports', 'value': reportProvider.adminTotalReports, 'color': const Color(0xFF2E7D32)},
      {'label': 'Pending', 'value': reportProvider.adminPendingReports, 'color': Colors.orange},
      {'label': 'Under Review', 'value': reportProvider.adminUnderReview, 'color': Colors.blue},
      {'label': 'Verified', 'value': reportProvider.adminVerified, 'color': Colors.green},
      {'label': 'Resolved', 'value': reportProvider.adminResolved, 'color': const Color(0xFF4CAF50)},
    ];

    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Good Morning! Here\'s what\'s happening with your reports.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          
          // Stats cards
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: stats.map((stat) {
              return Container(
                width: 200,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stat['value'].toString(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: stat['color'] as Color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stat['label'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          
          // Quick Action Buttons
          Row(
            children: [
              _buildActionButton(
                icon: Icons.assignment_add,
                label: 'New Report',
                color: const Color(0xFF2E7D32),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Create new report from admin'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: Icons.person_add,
                label: 'Add Officer',
                color: Colors.blue,
                onTap: () {
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                icon: Icons.notifications_active,
                label: 'Create Alert',
                color: Colors.orange,
                onTap: () {
                  setState(() {
                    _selectedIndex = 4;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Recent Reports
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Reports',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (reportProvider.reports.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No reports found'),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: reportProvider.reports.length > 5 ? 5 : reportProvider.reports.length,
                    itemBuilder: (context, index) {
                      final report = reportProvider.reports[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: report.statusColor.withOpacity(0.2),
                          child: Icon(
                            Icons.assignment,
                            size: 16,
                            color: report.statusColor,
                          ),
                        ),
                        title: Text(
                          report.title,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${report.region ?? 'Unknown'} • ${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: report.statusColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            report.statusDisplayText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        onTap: () {},
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}