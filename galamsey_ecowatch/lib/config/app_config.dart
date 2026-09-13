class AppConfig {
  // Development (local) – comment out when deploying
  // static const String apiUrl = 'http://localhost:5000/api';
  
  // Production (Render)
  static const String apiUrl = 'https://galamsey-ecowatch-ghana.onrender.com/api';
  
  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 60);
}