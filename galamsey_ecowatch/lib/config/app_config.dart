class AppConfig {
  // Development API URL
  static const String apiUrl = 'http://localhost:5000/api';
  
  // For production, change this to your deployed API URL
  // static const String apiUrl = 'https://your-api-domain.com/api';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}