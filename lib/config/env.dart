import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://91.99.130.85:8084/api';
  static bool get useMockData => dotenv.env['USE_MOCK_DATA']?.toLowerCase() == 'true';
}
