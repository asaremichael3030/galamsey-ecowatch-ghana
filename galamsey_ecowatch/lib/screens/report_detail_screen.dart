import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/report_provider.dart';
import '../providers/auth_provider.dart';
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
  String? _evidenceError;

  // ⚠️ Production base URL for images (Render backend)
  static const String baseUrl = 'https://galamsey-ecowatch-ghana.onrender.com';

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
      _evidenceError = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final apiService = context.read<ReportProvider>().apiService;

      print('📖 Loading evidence for report ${widget.reportId}');
      print('   User role: ${auth.user?.role}');

      final response = await apiService.get(
        '/reports/${widget.reportId}/evidence',
      );

      print('📖 Evidence response: ${response.statusCode}');
      print('📖 Evidence data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> evidenceData =
            response.data['data']['evidence'] ?? [];

        setState(() {
          _evidence = evidenceData.map((item) {
            String fileUrl = item['file_url'] ?? '';

            // Prepend base URL if the path is relative
            if (fileUrl.startsWith('/')) {
              fileUrl = '$baseUrl$fileUrl';
            }

            return {
              'id': item['id'],
              'file_url': fileUrl,
              'file_type': item['file_type'] ?? '',
              'created_at': item['created_at'] != null
                  ? DateTime.parse(item['created_at'])
                  : DateTime.now(),
            };
          }).toList();
        });

        print('📖 Loaded ${_evidence.length} evidence items');
        for (final e in _evidence) {
          print('   → ${e['file_url']}');
        }
      } else {
        setState(() {
          _evidenceError = response.data['message'] ?? 'Failed to load';
        });
        print('❌ Evidence error: ${response.data}');
      }
    } catch (e) {
      print('❌ Evidence exception: $e');
      setState(() => _evidenceError = e.toString());
    }

    if (mounted) {
      setState(() => _isLoadingEvidence = false);
    }
  }

  Future<void> _shareReport(Report report) async {
    setState(() => _isSharing = true);
    final text = '''
🌍 EcoWatch Ghana - Report Details

📋 ID: ${report.reportCode}
📌 Title: ${report.title}
📝 ${report.description}
🏷️ Category: ${report.categoryName ?? 'N/A'}
⚠️ Severity: ${report.severity}
📍 Location: ${report.region ?? 'Unknown'}
📊 Status: ${report.statusDisplayText}
''';
    try {
      await Share.share(text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => _isSharing = false);
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = context.watch<ReportProvider>();
    final auth = context.watch<AuthProvider>();
    final report = reportProvider.currentReport;
    final isAdminOrOfficer =
        auth.user?.role == 'admin' || auth.user?.role == 'officer';

    if (reportProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (report == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Report Details')),
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
                    width: 20,
                    height: 20,
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
            // Report header
            Container(
              padding: const EdgeInsets.all(16),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.reportCode,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          report.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        if (isAdminOrOfficer && report.reporterName != null) ...
                          [
                            const SizedBox(height: 4),
                            Text(
                              'Reporter: ${report.reporterName}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: report.statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      report.statusDisplayText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Container(
              padding: const EdgeInsets.all(16),
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
                    'Description',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(report.description,
                      style: const TextStyle(fontSize: 15, height: 1.5)),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  _infoRow('Category', report.categoryName ?? 'N/A'),
                  _infoRow('Severity', report.severity),
                  _infoRow(
                    'Submitted',
                    '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}',
                  ),
                  _infoRow('Anonymous', report.anonymous ? 'Yes' : 'No'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ============ EVIDENCE SECTION ============
            Container(
              padding: const EdgeInsets.all(16),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Evidence',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                      if (!_isLoadingEvidence)
                        Text(
                          '${_evidence.length} item(s)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Loading state
                  if (_isLoadingEvidence)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )

                  // Error state
                  else if (_evidenceError != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Failed to load evidence: $_evidenceError',
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    )

                  // Empty state
                  else if (_evidence.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.image_not_supported_outlined,
                                size: 40, color: Colors.grey),
                            SizedBox(height: 8),
                            Text(
                              'No evidence attached',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )

                  // Evidence grid
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: _evidence.length,
                      itemBuilder: (context, index) {
                        final e = _evidence[index];
                        final url = e['file_url'] as String;
                        final type = e['file_type'] as String;
                        final isVideo = type.startsWith('video/');

                        return GestureDetector(
                          onTap: () => _showFullScreen(context, url, isVideo),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: Colors.grey[300],
                                      child: const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.broken_image,
                                              color: Colors.grey, size: 36),
                                          SizedBox(height: 4),
                                          Text('Cannot load',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (isVideo)
                                    Container(
                                      color: Colors.black.withOpacity(0.3),
                                      child: const Center(
                                        child: Icon(
                                          Icons.play_circle_filled,
                                          color: Colors.white,
                                          size: 44,
                                        ),
                                      ),
                                    ),
                                ],
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void _showFullScreen(BuildContext context, String url, bool isVideo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: isVideo
                ? const Icon(Icons.play_circle_filled,
                    color: Colors.white, size: 80)
                : InteractiveViewer(
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white)),
                      ),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}