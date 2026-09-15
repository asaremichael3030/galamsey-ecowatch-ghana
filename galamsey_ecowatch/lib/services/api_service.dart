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
    // Configure Dio
    dio.options.baseUrl = baseUrl ?? 'http://localhost:5000/api';
    dio.options.connectTimeout = const Duration(seconds: 90);
    dio.options.receiveTimeout = const Duration(seconds: 90);
    dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Interceptors for logging and auth
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          print('🚀 Request: ${options.method} ${options.uri}');
          if (options.data != null) {
            print('📦 Data: ${options.data}');
          }

          // Load token if not already in memory
          if (_token == null) {
            _token = await secureStorage.read(key: 'token');
          }

          if (_token != null && _token!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_token';
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
              '✅ Response: ${response.statusCode} ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          print('❌ Error: ${error.message}');
          print(
              '❌ Response: ${error.response?.statusCode} ${error.response?.data}');

          // Clear token only when the server explicitly says the token is
          // invalid or expired — NOT when "no token provided" (which just
          // means the user isn't logged in yet).
          final serverMsg = error.response?.data?['message']?.toString() ?? '';
          final isExpiredOrInvalid = serverMsg.toLowerCase().contains('invalid') ||
              serverMsg.toLowerCase().contains('expired');

          if (error.response?.statusCode == 401 && isExpiredOrInvalid) {
            await clearToken();
          }

          return handler.next(error);
        },
      ),
    );
  }

  // -------- TOKEN MANAGEMENT --------
  Future<void> setToken(String token) async {
    _token = token;
    await secureStorage.write(key: 'token', value: token);
  }

  Future<void> clearToken() async {
    _token = null;
    await secureStorage.delete(key: 'token');
  }

  String? get token => _token;

  /// Returns true if a token is currently held in memory.
  /// Useful for guarding API calls when the user isn't logged in.
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  // -------- HTTP METHODS --------
  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) async {
    try {
      return await dio.get(path, queryParameters: queryParams);
    } on DioException catch (e) {
      print('GET Error: ${e.response?.data}');
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await dio.post(path, data: data);
    } on DioException catch (e) {
      print('POST Error: ${e.response?.data}');
      rethrow;
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await dio.put(path, data: data);
    } on DioException catch (e) {
      print('PUT Error: ${e.response?.data}');
      rethrow;
    }
  }

  Future<Response> patch(String path, {dynamic data}) async {
    try {
      return await dio.patch(path, data: data);
    } on DioException catch (e) {
      print('PATCH Error: ${e.response?.data}');
      rethrow;
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await dio.delete(path);
    } on DioException catch (e) {
      print('DELETE Error: ${e.response?.data}');
      rethrow;
    }
  }

  Future<Response> upload(String path, FormData formData) async {
    try {
      return await dio.post(
        path,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
    } on DioException catch (e) {
      print('Upload Error: ${e.response?.data}');
      rethrow;
    }
  }
}