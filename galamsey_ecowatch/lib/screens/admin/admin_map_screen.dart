import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/report_provider.dart';
import '../../models/report_model.dart';
import '../report_detail_screen.dart';

class AdminMapScreen extends StatefulWidget {
  const AdminMapScreen({super.key});

  @override
  State<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends State<AdminMapScreen> {
  String _selectedStatus = 'All';
  String _selectedSeverity = 'All';
  final List<String> _statuses = ['All', 'pending', 'under_review', 'verified', 'under_investigation', 'resolved', 'rejected', 'closed'];
  final List<String> _severities = ['All', 'Low', 'Medium', 'High', 'Critical'];
  List<Report> _mapReports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reportProvider = context.read<ReportProvider>();
      await reportProvider.loadAdminReports();
      
      setState(() {
        _mapReports = reportProvider.reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Report> _getFilteredReports() {
    var filtered = _mapReports;
    
    if (_selectedStatus != 'All') {
      filtered = filtered.where((report) => report.status == _selectedStatus).toList();
    }
    
    if (_selectedSeverity != 'All') {
      filtered = filtered.where((report) => report.severity == _selectedSeverity).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredReports = _getFilteredReports();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Map View'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF2E7D32),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filters
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: _statuses.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(status.split('_').map((word) => 
                                word[0].toUpperCase() + word.substring(1)
                              ).join(' ')),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedStatus = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedSeverity,
                          decoration: InputDecoration(
                            labelText: 'Severity',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: _severities.map((severity) {
                            return DropdownMenuItem(
                              value: severity,
                              child: Text(severity),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSeverity = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Map Container
                Expanded(
                  flex: 2,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: filteredReports.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.map_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No reports to display',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Try adjusting your filters',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.map_outlined,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${filteredReports.length} reports on map',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap a marker to view details',
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: AdminMapMarkerPainter(
                                    reports: filteredReports,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                
                // Report list below map
                Expanded(
                  flex: 1,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Reports (${filteredReports.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            if (_selectedStatus != 'All' || _selectedSeverity != 'All')
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedStatus = 'All';
                                    _selectedSeverity = 'All';
                                  });
                                },
                                child: const Text(
                                  'Clear Filters',
                                  style: TextStyle(color: Color(0xFF2E7D32)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: filteredReports.isEmpty
                              ? Center(
                                  child: Text(
                                    'No reports found',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: filteredReports.length > 5 ? 5 : filteredReports.length,
                                  itemBuilder: (context, index) {
                                    final report = filteredReports[index];
                                    return _buildReportListItem(report);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildReportListItem(Report report) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportDetailScreen(reportId: report.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: report.statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        report.region ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: report.severityColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          report.severity,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: report.severityColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: report.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                report.statusDisplayText,
                style: TextStyle(
                  fontSize: 10,
                  color: report.statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for admin map markers
class AdminMapMarkerPainter extends CustomPainter {
  final List<Report> reports;

  AdminMapMarkerPainter({required this.reports});

  @override
  void paint(Canvas canvas, Size size) {
    final random = _Random(42);
    final positions = <Offset>[];

    for (int i = 0; i < reports.length && i < 20; i++) {
      final x = 40 + (i % 4) * (size.width - 80) / 3 + random.nextDouble() * 20;
      final y = 40 + (i ~/ 4) * (size.height - 80) / 3 + random.nextDouble() * 20;
      positions.add(Offset(x, y));
    }

    for (int i = 0; i < reports.length && i < 20; i++) {
      final report = reports[i];
      final position = positions[i % positions.length];
      
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(position.dx + 2, position.dy + 4),
        14,
        shadowPaint,
      );

      final paint = Paint()
        ..color = report.statusColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(position, 14, paint);

      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(position, 14, borderPaint);

      final pointPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawPath(
        Path()
          ..moveTo(position.dx, position.dy + 10)
          ..lineTo(position.dx + 6, position.dy + 18)
          ..lineTo(position.dx - 6, position.dy + 18)
          ..close(),
        pointPaint,
      );

      final textSpan = TextSpan(
        text: report.status[0].toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class _Random {
  final int seed;
  int _seed;

  _Random(this.seed) : _seed = seed;

  double nextDouble() {
    _seed = (_seed * 9301 + 49297) % 233280;
    return _seed / 233280;
  }
}