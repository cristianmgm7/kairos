class AppConstants {
  AppConstants._();

  // API
  static const int apiTimeoutSeconds = 30;
  static const int apiRetryAttempts = 3;

  // Pagination
  static const int defaultPageSize = 20;

  // Cache
  static const int cacheExpirationMinutes = 30;

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
}
