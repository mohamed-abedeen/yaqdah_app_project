/// Centralized app configuration.
/// API keys are read from `--dart-define` environment variables at compile time.
///
/// Usage:
/// ```
/// flutter run --dart-define=GEMINI_API_KEY=xxx --dart-define=MAPBOX_TOKEN=xxx
/// ```
class AppConfig {
  AppConfig._();

  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const String mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_TOKEN',
  );
}
