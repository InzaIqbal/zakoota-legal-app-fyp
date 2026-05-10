/// Zing AI configuration.
///
/// For local/dev without committing secrets, prefer passing values via:
/// `--dart-define=ZING_API_BASE_URL=https://...`
/// `--dart-define=ZING_API_KEY=...` (optional)
class ZingAIConfig {
  /// Example default points to the existing Zakoota backend.
  static const String baseUrl = String.fromEnvironment(
    'ZING_API_BASE_URL',
    defaultValue: 'https://zing-fix-final-new-1.onrender.com',
  );

  /// If your Zing backend requires an API key, pass it via --dart-define.
  static const String apiKey = String.fromEnvironment('ZING_API_KEY');

  /// Chat endpoint path on the backend.
  static const String chatPath = String.fromEnvironment(
    'ZING_CHAT_PATH',
    defaultValue: '/api/chat',
  );
}
