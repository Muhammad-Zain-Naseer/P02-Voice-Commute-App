/// Application Configuration
/// Centralized constants for API endpoints, socket URLs, and app settings

class AppConfig {
  // API Configuration - LOCAL DEVELOPMENT
  static const String apiBaseUrl = 'http://localhost:3000';

  // Socket.IO Configuration - LOCAL DEVELOPMENT
  static const String socketUrl = 'http://localhost:3000';

  // For production deployment, uncomment these:
  // static const String apiBaseUrl = String.fromEnvironment(
  //   'API_BASE_URL',
  //   defaultValue: 'https://fyp-backend-3oxm.onrender.com',
  // );
  // static const String socketUrl = String.fromEnvironment(
  //   'SOCKET_URL',
  //   defaultValue: 'https://fyp-backend-3oxm.onrender.com',
  // );

  // Socket options
  static const Duration socketReconnectionDelay = Duration(seconds: 2);
  static const int socketReconnectionAttempts = 5;
  static const Duration socketTimeout = Duration(seconds: 10);

  // App Settings
  static const String appName = 'HerSafar';
  static const String appVersion = '1.0.0';

  // Location Settings
  static const Duration locationCacheDuration = Duration(minutes: 2);

  // Audio Recording Settings
  static const int audioSampleRate = 16000;
  static const Duration audioMaxDuration = Duration(minutes: 1);
}
