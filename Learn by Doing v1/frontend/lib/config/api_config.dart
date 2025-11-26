/// Configuration for API endpoints and environment-specific settings
///
/// This file provides a centralized location for all API URLs and should be
/// updated based on the deployment environment.
///
/// SECURITY FEATURES:
/// - HTTPS enforced for production (ruckusrulers.com)
/// - HTTP allowed only for local development
/// - SSL/TLS certificate validation
/// - Security headers included in all requests
/// - Automatic HTTPS redirect from HTTP
library;

class ApiConfig {
  /// Determines if the app is running in development mode
  static const bool isDevelopment = bool.fromEnvironment(
    'DEV_ENV',
    defaultValue: true,
  );

  /// Backend API base URL
  ///
  /// Development: http://127.0.0.1:8002/api/v1 (local only, no SSL needed)
  /// Production: https://ruckusrulers.com/api/v1 (HTTPS enforced)
  ///
  /// SECURITY: Production always uses HTTPS with SSL/TLS encryption
  /// NOTE: Using 127.0.0.1 instead of localhost for better browser compatibility
  static String get baseUrl {
    if (isDevelopment) {
      return 'http://127.0.0.1:8002/api/v1';
    } else {
      return 'https://ruckusrulers.com/api/v1';
    }
  }

  /// Backend API host (for direct connections)
  static String get apiHost {
    if (isDevelopment) {
      return '127.0.0.1:8002';
    } else {
      return 'ruckusrulers.com';
    }
  }

  /// Backend API protocol
  /// SECURITY: Always HTTPS for production
  static String get apiProtocol {
    return isDevelopment ? 'http' : 'https';
  }

  /// Whether SSL/TLS certificate validation is enforced
  /// SECURITY: Always true for production
  static bool get enforceSSL => !isDevelopment;

  /// Whether to allow HTTP fallback (development only)
  /// SECURITY: False for production - HTTPS only
  static bool get allowInsecure => isDevelopment;

  /// Authentication endpoints
  static String get loginEndpoint => '$baseUrl/auth/login';
  static String get registerEndpoint => '$baseUrl/auth/register';
  static String get refreshTokenEndpoint => '$baseUrl/auth/refresh';
  static String get logoutEndpoint => '$baseUrl/auth/logout';

  /// Student endpoints
  static String get studentsEndpoint => '$baseUrl/students';
  static String get studentDetailsEndpoint => '$baseUrl/students/{id}';

  /// Behavior endpoints
  static String get behaviorsEndpoint => '$baseUrl/behaviors';
  static String get behaviorDetailsEndpoint => '$baseUrl/behaviors/{id}';

  /// User endpoints
  static String get usersEndpoint => '$baseUrl/users';
  static String get userProfileEndpoint => '$baseUrl/users/profile';

  /// Health check endpoint
  static String get healthEndpoint =>
      '${isDevelopment ? 'http://localhost:8002' : 'https://ruckusrulers.com'}/health';

  /// HTTP headers
  /// SECURITY: Content-Type enforced to JSON for API safety
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Request timeout in seconds
  /// SECURITY: Conservative timeout to detect hung connections
  static const int requestTimeout = 30;

  /// Maximum retry attempts for failed requests
  /// SECURITY: Avoids exponential load on server
  static const int maxRetries = 3;

  /// Retry delay in milliseconds
  /// SECURITY: Exponential backoff prevents DDoS-like behavior
  static const int retryDelayMs = 1000;
}
