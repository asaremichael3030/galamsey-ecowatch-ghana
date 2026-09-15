import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../models/report_model.dart';

class ReportProvider extends ChangeNotifier {
  final ApiService apiService;

  List<Report> _reports = [];
  Report? _currentReport;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  // User stats
  int _totalReports = 0;
  int _pendingReports = 0;
  int _underReview = 0;
  int _verified = 0;
  int _resolved = 0;

  // Admin stats
  int _adminTotalReports = 0;
  int _adminPendingReports = 0;
  int _adminUnderReview = 0;
  int _adminVerified = 0;
  int _adminResolved = 0;
  int _adminRejected = 0;
  int _adminClosed = 0;

  // Getters
  List<Report> get reports => _reports;
  Report? get currentReport => _currentReport;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  int get totalReports => _totalReports;
  int get pendingReports => _pendingReports;
  int get underReview => _underReview;
  int get verified => _verified;
  int get resolved => _resolved;

  int get adminTotalReports => _adminTotalReports;
  int get adminPendingReports => _adminPendingReports;
  int get adminUnderReview => _adminUnderReview;
  int get adminVerified => _adminVerified;
  int get adminResolved => _adminResolved;
  int get adminRejected => _adminRejected;
  int get adminClosed => _adminClosed;

  ReportProvider(this.apiService);

  // -------- LOAD USER REPORTS --------
  Future<void> loadReports({String? status}) async {
    if (!apiService.isAuthenticated) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final Map<String, dynamic> queryParams = {};
      if (status != null) queryParams['status'] = status;

      final response =
          await apiService.get('/reports', queryParams: queryParams);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data']['reports'];
        _reports = data.map((j) => Report.fromJson(j)).toList();
      } else {
        _error = response.data['message'] ?? 'Failed to load reports';
      }
    } on DioException catch (e) {
      if (e.response?.statusCode != 401) {
        _error = 'Network error';
      }
    } catch (e) {
      _error = 'Unexpected error';
    }

    _isLoading = false;
    notifyListeners();
  }

  // -------- LOAD ADMIN REPORTS (all) --------
  Future<void> loadAdminReports({String? status}) async {
    if (!apiService.isAuthenticated) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final Map<String, dynamic> queryParams = {};
      if (status != null) queryParams['status'] = status;

      final response = await apiService.get('/reports/admin/all',
          queryParams: queryParams);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data']['reports'];
        _reports = data.map((j) => Report.fromJson(j)).toList();
        await loadAdminStats();
      } else {
        _error = response.data['message'] ?? 'Failed to load reports';
      }
    } on DioException catch (e) {
      if (e.response?.statusCode != 401) {
        _error = 'Network error';
      }
    } catch (e) {
      _error = 'Unexpected error';
    }

    _isLoading = false;
    notifyListeners();
  }

  // -------- LOAD ADMIN DASHBOARD STATS --------
  Future<void> loadAdminStats() async {
    if (!apiService.isAuthenticated) return;

    try {
      final response = await apiService.get('/reports/stats/dashboard');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final stats = response.data['data']['stats'];
        _adminTotalReports = int.parse(stats['total']?.toString() ?? '0');
        _adminPendingReports =
            int.parse(stats['pending']?.toString() ?? '0');
        _adminUnderReview =
            int.parse(stats['under_review']?.toString() ?? '0');
        _adminVerified = int.parse(stats['verified']?.toString() ?? '0');
        _adminResolved = int.parse(stats['resolved']?.toString() ?? '0');
        _adminRejected = int.parse(stats['rejected']?.toString() ?? '0');
        _adminClosed = int.parse(stats['closed']?.toString() ?? '0');
        notifyListeners();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode != 401) {
        print('loadAdminStats error: ${e.message}');
      }
    } catch (_) {}
  }

  // -------- LOAD ONE REPORT --------
  Future<void> loadReportById(int id) async {
    if (!apiService.isAuthenticated) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.get('/reports/$id');

      if (response.statusCode == 200 && response.data['success'] == true) {
        _currentReport = Report.fromJson(response.data['data']['report']);
      } else {
        _error = response.data['message'] ?? 'Failed to load report';
      }
    } on DioException catch (e) {
      if (e.response?.statusCode != 401) {
        _error = 'Network error';
      }
    } catch (e) {
      _error = 'Unexpected error';
    }

    _isLoading = false;
    notifyListeners();
  }

  // -------- LOAD USER STATS --------
  // Stricter version: silently exits when not authenticated and never
  // logs 401s (which happen right after logout and are harmless).
  Future<void> loadUserStats() async {
    if (!apiService.isAuthenticated) {
      return;
    }

    try {
      final response = await apiService.get('/users/stats');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final stats = response.data['data']['stats'];
        _totalReports = stats['total_reports'] ?? 0;
        _pendingReports = stats['pending'] ?? 0;
        _underReview = stats['under_review'] ?? 0;
        _verified = stats['verified'] ?? 0;
        _resolved = stats['resolved'] ?? 0;
        notifyListeners();
      }
    } on DioException catch (e) {
      // Silent — do not log 401s after logout
      if (e.response?.statusCode != 401) {
        print('loadUserStats error: ${e.message}');
      }
    } catch (_) {
      // Ignore
    }
  }

  // -------- CREATE REPORT WITH EVIDENCE --------
  Future<Map<String, dynamic>> createReport({
    required String title,
    required String description,
    required int categoryId,
    required String severity,
    DateTime? observedAt,
    double? latitude,
    double? longitude,
    String? region,
    String? district,
    String? community,
    bool anonymous = false,
    List<XFile>? evidenceFiles,
  }) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final Map<String, dynamic> data = {
        'title': title,
        'description': description,
        'category_id': categoryId,
        'severity': severity,
        'anonymous': anonymous,
      };
      if (observedAt != null) data['observed_at'] = observedAt.toIso8601String();
      if (latitude != null) data['latitude'] = latitude;
      if (longitude != null) data['longitude'] = longitude;
      if (region != null) data['region'] = region;
      if (district != null) data['district'] = district;
      if (community != null) data['community'] = community;

      final response = await apiService.post('/reports', data: data);

      if (response.statusCode == 201 && response.data['success'] == true) {
        final newReport = Report.fromJson(response.data['data']['report']);

        // Upload evidence if any
        if (evidenceFiles != null && evidenceFiles.isNotEmpty) {
          await _uploadEvidence(newReport.id, evidenceFiles);
        }

        await loadReports();
        _isSubmitting = false;
        notifyListeners();

        return {
          'success': true,
          'message': response.data['message'] ?? 'Report submitted',
          'data': newReport,
        };
      } else {
        _isSubmitting = false;
        notifyListeners();
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to submit',
        };
      }
    } catch (e) {
      _isSubmitting = false;
      _error = 'Network error';
      notifyListeners();
      return {
        'success': false,
        'message': 'Network error',
      };
    }
  }

  // -------- UPLOAD EVIDENCE (cross-platform) --------
  Future<bool> _uploadEvidence(int reportId, List<XFile> evidenceFiles) async {
    try {
      final formData = FormData();

      for (final XFile xfile in evidenceFiles) {
        // Read bytes — works on web AND mobile
        final bytes = await xfile.readAsBytes();
        final filename = xfile.name;

        // Detect MIME type from extension
        final ext = filename.split('.').last.toLowerCase();
        String mimeType = 'application/octet-stream';
        if (['jpg', 'jpeg'].contains(ext)) mimeType = 'image/jpeg';
        else if (ext == 'png') mimeType = 'image/png';
        else if (ext == 'gif') mimeType = 'image/gif';
        else if (ext == 'webp') mimeType = 'image/webp';
        else if (ext == 'mp4') mimeType = 'video/mp4';
        else if (['mov', 'quicktime'].contains(ext)) {
          mimeType = 'video/quicktime';
        }

        formData.files.add(
          MapEntry(
            'evidence',
            MultipartFile.fromBytes(
              bytes,
              filename: filename,
              contentType: DioMediaType.parse(mimeType),
            ),
          ),
        );
      }

      final response =
          await apiService.upload('/reports/$reportId/evidence', formData);

      print('Evidence upload response: ${response.statusCode}');
      return response.statusCode == 201;
    } catch (e) {
      print('Upload evidence error: $e');
      return false;
    }
  }

  // -------- UPDATE REPORT STATUS (admin/officer) --------
  Future<Map<String, dynamic>> updateReportStatus(
    int reportId,
    String status, {
    String? comment,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final response = await apiService.patch(
        '/reports/$reportId/status',
        data: {'status': status, 'comment': comment},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        await loadReports();
        await loadUserStats();
        await loadAdminStats();
        _isSubmitting = false;
        notifyListeners();
        return {
          'success': true,
          'message': response.data['message'] ?? 'Updated',
        };
      }
      _isSubmitting = false;
      notifyListeners();
      return {
        'success': false,
        'message': response.data['message'] ?? 'Failed',
      };
    } catch (e) {
      _isSubmitting = false;
      notifyListeners();
      return {'success': false, 'message': 'Network error'};
    }
  }

  // -------- GET MAP REPORTS --------
  Future<List<Report>> getMapReports({
    String? status,
    String? region,
    String? severity,
  }) async {
    try {
      final Map<String, dynamic> qp = {};
      if (status != null) qp['status'] = status;
      if (region != null) qp['region'] = region;
      if (severity != null) qp['severity'] = severity;

      final response =
          await apiService.get('/reports/map', queryParams: qp);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data']['reports'];
        return data.map((j) => Report.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // -------- HELPERS --------
  void clearCurrentReport() {
    _currentReport = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _reports = [];
    _currentReport = null;
    _isLoading = false;
    _isSubmitting = false;
    _error = null;
    _totalReports = 0;
    _pendingReports = 0;
    _underReview = 0;
    _verified = 0;
    _resolved = 0;
    _adminTotalReports = 0;
    _adminPendingReports = 0;
    _adminUnderReview = 0;
    _adminVerified = 0;
    _adminResolved = 0;
    _adminRejected = 0;
    _adminClosed = 0;
    notifyListeners();
  }
}