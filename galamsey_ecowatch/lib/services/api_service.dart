import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final Dio dio;
  final SharedPreferences sharedPreferences;
  final FlutterSecureStorage secureStorage;
  String? _token;

  ApiService(
    this.dio,
    this.sharedPreferences,
    this.secureStorage, {
    String? baseUrl,
  }) {
    // Configure Dio with the correct base URL
    dio.options.baseUrl = baseUrl ?? 'http://localhost:5000/api';
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.receiveTimeout = const Duration(seconds: 30);
    dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    // Add logging interceptor for debugging
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          print('🚀 Request: ${options.method} ${options.uri}');
          if (options.data != null) {
            print('📦 Data: ${options.data}');
          }
          // Try to get token if not already set
          if (_token == null) {
            _token = await secureStorage.read(key: 'token');
          }
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ Response: ${response.statusCode} ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          print('❌ Error: ${error.message}');
          print('❌ Response: ${error.response?.statusCode} ${error.response?.data}');
          if (error.response?.statusCode == 401) {
            await clearToken();
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Set token
  Future<void> setToken(String token) async {
    _token = token;
    await secureStorage.write(key: 'token', value: token);
  }

  // Clear token
  Future<void> clearToken() async {
    _token = null;
    await secureStorage.delete(key: 'token');
  }

  // Get token
  String? get token => _token;

  // GET request
  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) async {
    try {
      return await dio.get(path, queryParameters: queryParams);
    } on DioException catch (e) {
      print('GET Error: ${e.response?.data}');
      rethrow;
    }
  }

  // POST request
  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await dio.post(path, data: data);
    } on DioException catch (e) {
      print('POST Error: ${e.response?.data}');
      rethrow;
    }
  }

  // PUT request
  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await dio.put(path, data: data);
    } on DioException catch (e) {
      print('PUT Error: ${e.response?.data}');
      rethrow;
    }
  }

  // PATCH request
  Future<Response> patch(String path, {dynamic data}) async {
    try {
      return await dio.patch(path, data: data);
    } on DioException catch (e) {
      print('PATCH Error: ${e.response?.data}');
      rethrow;
    }
  }

  // DELETE request
  Future<Response> delete(String path) async {
    try {
      return await dio.delete(path);
    } on DioException catch (e) {
      print('DELETE Error: ${e.response?.data}');
      rethrow;
    }
  }

  // Upload file with multipart
  Future<Response> upload(String path, FormData formData) async {
    try {
      // For upload, we need to set multipart header
      final response = await dio.post(
        path,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      print('Upload Error: ${e.response?.data}');
      rethrow;
    }
  }
}