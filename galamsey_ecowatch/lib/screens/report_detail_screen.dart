import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/report_provider.dart';
import '../models/report_model.dart';

class ReportDetailScreen extends StatefulWidget {
  final int reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  List<Map<String, dynamic>> _evidence = [];
  bool _isLoadingEvidence = false;
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().loadReportById(widget.reportId);
      _loadEvidence();
    });
  }

  Future<void> _loadEvidence() async {
    setState(() {
      _isLoadingEvidence = true;
    });

    try {
      final apiService = context.read<ReportProvider>().apiService;
      final response = await apiService.get('/reports/${widget.reportId}/evidence');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> evidenceData = response.data['data']['evidence'] ?? [];
        // Use the full URL - since the backend serves static files, we need the base URL
        const String baseUrl = 'http://localhost:5000';
        setState(() {
          _evidence = evidenceData.map((item) {
            String fileUrl = item['file_url'] ?? '';
            // If relative, prepend base URL
            if (fileUrl.startsWith('/')) {
              fileUrl = '$baseUrl$fileUrl';
            }
            return {
              'id': item['id'],
              'file_url': fileUrl,
              'file_type': item['file_type'],
              'created_at': item['created_at'] != null
                  ? DateTime.parse(item['created_at'])
                  : DateTime.now(),
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading evidence: $e');
    }

    setState(() {
      _isLoadingEvidence = false;
    });
  }

  Future<void> _shareReport(Report report) async {
    setState(() {
      _isSharing = true;
    });
    final String shareText = '''
🌍 EcoWatch Ghana - Report Details
📋 Report ID: ${report.reportCode}
📌 Title: ${report.title}
📝 Description: ${report.description}
🏷️ Category: ${report.categoryName ?? 'Not specified'}
⚠️ Severity: ${report.severity}
📍 Location: ${report.region ?? 'Unknown'}
📅 Submitted: ${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}
📊 Status: ${report.statusDisplayText}
''';
    try {
      await Share.share(shareText);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
    setState(() {
      _isSharing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final report = reportProvider.currentReport;

    if (reportProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report Details'), backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: Text('Report not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Report Details'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF2E7D32),
        actions: [
          IconButton(
            icon: _isSharing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_outlined),
            onPressed: _isSharing ? null : () => _shareReport(report),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ID & Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.reportCode, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(report.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: report.statusColor, borderRadius: BorderRadius.circular(20)),
                    child: Text(report.statusDisplayText, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
                  const SizedBox(height: 8),
                  Text(report.description, style: const TextStyle(fontSize: 15, color: Colors.grey, height: 1.5)),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildInfoRow('Category', report.categoryName ?? 'Not specified'),
                  _buildInfoRow('Severity', report.severity),
                  _buildInfoRow('Date Observed', report.observedAt != null ? '${report.observedAt!.day}/${report.observedAt!.month}/${report.observedAt!.year}' : 'Not specified'),
                  _buildInfoRow('Submitted', '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}'),
                  _buildInfoRow('Anonymous', report.anonymous ? 'Yes' : 'No'),
                  if (report.assignedOfficerName != null) _buildInfoRow('Assigned To', report.assignedOfficerName!),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Location
            if (report.region != null || report.district != null || report.community != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Location', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
                    const SizedBox(height: 8),
                    if (report.community != null) Text(report.community!, style: const TextStyle(fontSize: 15)),
                    if (report.district != null) Text(report.district!, style: const TextStyle(fontSize: 15)),
                    if (report.region != null) Text(report.region!, style: const TextStyle(fontSize: 15)),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // ==================== EVIDENCE SECTION ====================
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Evidence', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32))),
                  const SizedBox(height: 12),
                  if (_isLoadingEvidence)
                    const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                  else if (_evidence.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: Text('No evidence attached', style: TextStyle(color: Colors.grey))),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: _evidence.length,
                      itemBuilder: (context, index) {
                        final item = _evidence[index];
                        final url = item['file_url'];
                        return GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                child: InteractiveViewer(
                                  child: CachedNetworkImage(
                                    imageUrl: url,
                                    placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                                    errorWidget: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 50)),
                                  ),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(color: Colors.grey[200], child: const Center(child: CircularProgressIndicator())),
                                errorWidget: (_, __, ___) => Container(
                                  color: Colors.grey[300],
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image, color: Colors.grey, size: 40),
                                      SizedBox(height: 4),
                                      Text('Failed to load', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600]))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}