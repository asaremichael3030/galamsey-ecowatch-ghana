// Import Flutter core
import 'package:flutter/material.dart';
// Import local storage
import 'package:shared_preferences/shared_preferences.dart';
// Import secure storage
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// Import API service
import '../services/api_service.dart';
// Import models
import '../models/user_model.dart';
// Import Dio for exception handling
import 'package:dio/dio.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService apiService;
  final SharedPreferences sharedPreferences;
  final FlutterSecureStorage secureStorage;

  User? _user;
  String? _token;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;

  // Getters
  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;

  AuthProvider(this.apiService, this.sharedPreferences, this.secureStorage) {
    checkAuthStatus();
  }

  // Check authentication status on app start
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      _token = await secureStorage.read(key: 'token');
      
      if (_token != null && _token!.isNotEmpty) {
        await getCurrentUser();
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
      }
    } catch (e) {
      print('Auth check error: $e');
      _isAuthenticated = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Get current user data from API
  Future<void> getCurrentUser() async {
    try {
      final response = await apiService.get('/users/me');
      if (response.statusCode == 200 && response.data['success'] == true) {
        _user = User.fromJson(response.data['data']['user']);
        _isAuthenticated = true;
      } else {
        _isAuthenticated = false;
      }
    } catch (e) {
      print('Get user error: $e');
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiService.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      print('Login response: ${response.statusCode}');
      print('Login data: ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Save token
        _token = response.data['data']['token'];
        await apiService.setToken(_token!);
        await secureStorage.write(key: 'token', value: _token);
        
        // Save user data
        _user = User.fromJson(response.data['data']['user']);
        _isAuthenticated = true;
        
        _isLoading = false;
        notifyListeners();
        
        return {
          'success': true,
          'message': response.data['message'] ?? 'Login successful',
        };
      } else {
        // Get the actual error message from the response
        final errorMsg = response.data['message'] ?? 'Login failed';
        _errorMessage = errorMsg;
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } on DioException catch (e) {
      // Handle Dio errors specifically
      String errorMsg = 'Network error. Please check your connection.';
      
      if (e.response != null && e.response!.data != null) {
        // Try to get the error message from the response
        try {
          final data = e.response!.data;
          if (data is Map && data['message'] != null) {
            errorMsg = data['message'];
          } else if (data is String) {
            errorMsg = data;
          }
        } catch (parseError) {
          // If we can't parse the response, use a generic message
        }
      }
      
      _errorMessage = errorMsg;
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': errorMsg,
      };
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  // Register a new user
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
    String? region,
    String? district,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiService.post('/auth/register', data: {
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'confirm_password': confirmPassword,
        'region': region,
        'district': district,
      });

      print('Register response: ${response.statusCode}');
      print('Register data: ${response.data}');

      if (response.statusCode == 201 && response.data['success'] == true) {
        // Save token
        _token = response.data['data']['token'];
        await apiService.setToken(_token!);
        await secureStorage.write(key: 'token', value: _token);
        
        // Save user data
        _user = User.fromJson(response.data['data']['user']);
        _isAuthenticated = true;
        
        _isLoading = false;
        notifyListeners();
        
        return {
          'success': true,
          'message': response.data['message'] ?? 'Registration successful',
        };
      } else {
        final errorMsg = response.data['message'] ?? 'Registration failed';
        _errorMessage = errorMsg;
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } on DioException catch (e) {
      String errorMsg = 'Network error. Please check your connection.';
      
      if (e.response != null && e.response!.data != null) {
        try {
          final data = e.response!.data;
          if (data is Map && data['message'] != null) {
            errorMsg = data['message'];
          }
        } catch (parseError) {
          // Ignore
        }
      }
      
      _errorMessage = errorMsg;
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': errorMsg,
      };
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      await apiService.post('/auth/logout');
    } catch (e) {
      // Ignore errors on logout
    }

    // Clear local storage
    await secureStorage.delete(key: 'token');
    await apiService.clearToken();
    
    _token = null;
    _user = null;
    _isAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }

  // Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? fullName,
    String? phone,
    String? region,
    String? district,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, dynamic> data = {};
      if (fullName != null) data['full_name'] = fullName;
      if (phone != null) data['phone'] = phone;
      if (region != null) data['region'] = region;
      if (district != null) data['district'] = district;

      final response = await apiService.put('/users/me', data: data);

      if (response.statusCode == 200 && response.data['success'] == true) {
        _user = User.fromJson(response.data['data']['user']);
        _isLoading = false;
        notifyListeners();
        return {
          'success': true,
          'message': response.data['message'] ?? 'Profile updated',
        };
      } else {
        final errorMsg = response.data['message'] ?? 'Update failed';
        _errorMessage = errorMsg;
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } on DioException catch (e) {
      String errorMsg = 'Network error. Please check your connection.';
      if (e.response != null && e.response!.data != null) {
        try {
          final data = e.response!.data;
          if (data is Map && data['message'] != null) {
            errorMsg = data['message'];
          }
        } catch (parseError) {
          // Ignore
        }
      }
      _errorMessage = errorMsg;
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': errorMsg,
      };
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  // Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiService.post('/users/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'confirm_password': confirmPassword,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return {
          'success': true,
          'message': response.data['message'] ?? 'Password changed',
        };
      } else {
        final errorMsg = response.data['message'] ?? 'Password change failed';
        _errorMessage = errorMsg;
        _isLoading = false;
        notifyListeners();
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } on DioException catch (e) {
      String errorMsg = 'Network error. Please check your connection.';
      if (e.response != null && e.response!.data != null) {
        try {
          final data = e.response!.data;
          if (data is Map && data['message'] != null) {
            errorMsg = data['message'];
          }
        } catch (parseError) {
          // Ignore
        }
      }
      _errorMessage = errorMsg;
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': errorMsg,
      };
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}