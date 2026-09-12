import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../models/report_model.dart';

class ReportProvider extends ChangeNotifier {
  final ApiService apiService;

  List<Report> _reports = [];
  Report? _currentReport;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  // User statistics
  int _totalReports = 0;
  int _pendingReports = 0;
  int _underReview = 0;
  int _verified = 0;
  int _resolved = 0;
  
  // Admin statistics (all reports)
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
  
  // Admin getters
  int get adminTotalReports => _adminTotalReports;
  int get adminPendingReports => _adminPendingReports;
  int get adminUnderReview => _adminUnderReview;
  int get adminVerified => _adminVerified;
  int get adminResolved => _adminResolved;
  int get adminRejected => _adminRejected;
  int get adminClosed => _adminClosed;

  ReportProvider(this.apiService);

  // Load all reports for the current user
  Future<void> loadReports({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final Map<String, dynamic> queryParams = {};
      if (status != null) queryParams['status'] = status;

      final response = await apiService.get('/reports', queryParams: queryParams);
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> reportsData = response.data['data']['reports'];
        _reports = reportsData.map((json) => Report.fromJson(json)).toList();
      } else {
        _error = response.data['message'] ?? 'Failed to load reports';
      }
    } catch (e) {
      _error = 'Network error. Please check your connection.';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load ALL reports for admin (no user filtering)
  Future<void> loadAdminReports({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final Map<String, dynamic> queryParams = {};
      if (status != null) queryParams['status'] = status;

      final response = await apiService.get('/reports/admin/all', queryParams: queryParams);
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> reportsData = response.data['data']['reports'];
        _reports = reportsData.map((json) => Report.fromJson(json)).toList();
        
        // Update admin statistics
        await loadAdminStats();
      } else {
        _error = response.data['message'] ?? 'Failed to load reports';
      }
    } catch (e) {
      _error = 'Network error. Please check your connection.';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load admin dashboard statistics (all reports)
  Future<void> loadAdminStats() async {
    try {
      final response = await apiService.get('/reports/stats/dashboard');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final stats = response.data['data']['stats'];
        _adminTotalReports = int.parse(stats['total']?.toString() ?? '0');
        _adminPendingReports = int.parse(stats['pending']?.toString() ?? '0');
        _adminUnderReview = int.parse(stats['under_review']?.toString() ?? '0');
        _adminVerified = int.parse(stats['verified']?.toString() ?? '0');
        _adminResolved = int.parse(stats['resolved']?.toString() ?? '0');
        _adminRejected = int.parse(stats['rejected']?.toString() ?? '0');
        _adminClosed = int.parse(stats['closed']?.toString() ?? '0');
        notifyListeners();
      }
    } catch (e) {
      print('Error loading admin stats: $e');
    }
  }

  // Load a specific report by ID
  Future<void> loadReportById(int id) async {
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
    } catch (e) {
      _error = 'Network error. Please check your connection.';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Load user report statistics
  Future<void> loadUserStats() async {
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
    } catch (e) {
      // Silent fail for stats
    }
  }

  // Create a new report
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
    List<String>? evidencePaths,
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
        
        // Upload evidence if provided
        if (evidencePaths != null && evidencePaths.isNotEmpty) {
          await _uploadEvidence(newReport.id, evidencePaths);
        }

        // Refresh reports list
        await loadReports();
        
        _isSubmitting = false;
        notifyListeners();
        
        return {
          'success': true,
          'message': response.data['message'] ?? 'Report submitted successfully',
          'data': newReport,
        };
      } else {
        _isSubmitting = false;
        notifyListeners();
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to submit report',
        };
      }
    } catch (e) {
      _isSubmitting = false;
      _error = 'Network error. Please check your connection.';
      notifyListeners();
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Upload evidence for a report
  Future<bool> _uploadEvidence(int reportId, List<String> evidencePaths) async {
    try {
      final formData = FormData();
      for (String path in evidencePaths) {
        final file = await MultipartFile.fromFile(path, filename: path.split('/').last);
        formData.files.add(
          MapEntry('evidence', file),
        );
      }

      final response = await apiService.upload(
        '/reports/$reportId/evidence',
        formData,
      );

      return response.statusCode == 201 && response.data['success'] == true;
    } catch (e) {
      print('Upload evidence error: $e');
      return false;
    }
  }

  // Update report status (admin/officer only)
  Future<Map<String, dynamic>> updateReportStatus(int reportId, String status, {String? comment}) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.patch(
        '/reports/$reportId/status',
        data: {
          'status': status,
          'comment': comment,
        },
      );
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        // Refresh reports list
        await loadReports();
        await loadUserStats();
        await loadAdminStats();
        
        _isSubmitting = false;
        notifyListeners();
        
        return {
          'success': true,
          'message': response.data['message'] ?? 'Status updated successfully',
        };
      } else {
        _isSubmitting = false;
        notifyListeners();
        return {
          'success': false,
          'message': response.data['message'] ?? 'Failed to update status',
        };
      }
    } catch (e) {
      _isSubmitting = false;
      _error = 'Network error. Please check your connection.';
      notifyListeners();
      return {
        'success': false,
        'message': 'Network error. Please check your connection.',
      };
    }
  }

  // Get reports for map view
  Future<List<Report>> getMapReports({String? status, String? region, String? severity}) async {
    try {
      final Map<String, dynamic> queryParams = {};
      if (status != null) queryParams['status'] = status;
      if (region != null) queryParams['region'] = region;
      if (severity != null) queryParams['severity'] = severity;

      final response = await apiService.get('/reports/map', queryParams: queryParams);
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> reportsData = response.data['data']['reports'];
        return reportsData.map((json) => Report.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Clear current report
  void clearCurrentReport() {
    _currentReport = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset provider
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