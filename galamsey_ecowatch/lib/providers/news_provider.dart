import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NewsProvider extends ChangeNotifier {
  final ApiService apiService;
  List<Map<String, dynamic>> _news = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get news => _news;
  bool get isLoading => _isLoading;

  NewsProvider(this.apiService);

  Future<void> loadNews() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiService.get('/news');
      if (response.statusCode == 200 && response.data['success'] == true) {
        _news = List<Map<String, dynamic>>.from(response.data['data']['news'] ?? []);
      }
    } catch (e) {
      print('Error loading news: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}