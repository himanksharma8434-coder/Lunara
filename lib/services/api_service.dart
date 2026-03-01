import 'package:dio/dio.dart';
import 'storage_service.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, or your local IP for physical devices
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));

  ApiService() {
    // This "Interceptor" automatically adds the Token to every request
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await StorageService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  // Auth Endpoints
  Future<Response> login(String email, String password) async {
    return await _dio
        .post('/auth/login', data: {'email': email, 'password': password});
  }

  // Cycle Endpoints
  Future<Response> logPeriodStart(DateTime date) async {
    return await _dio.post('/cycles/start', data: {
      'startDate': date.toIso8601String().split('T')[0],
    });
  }

  // Assessment Endpoints
  Future<Response> syncDailyAssessment(Map<String, dynamic> data) async {
    return await _dio.post('/assessments', data: data);
  }

  Future<Response> getAssessmentHistory() async {
    return await _dio.get('/assessments/history');
  }
}
