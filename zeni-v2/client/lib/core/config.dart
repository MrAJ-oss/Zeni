class ZeniConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'ZENI_API_URL',
    defaultValue: 'http://localhost:3000',
  );
}
