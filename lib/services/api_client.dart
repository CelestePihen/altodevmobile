import 'package:dio/dio.dart';

/// Singleton class to manage the API client
class ApiClient {
  static final ApiClient instance = ApiClient._init();
  final Dio _dio = Dio();

  // private constructor
  ApiClient._init() {
    _dio.options.baseUrl = "https://alto.samyn.ovh";
    _dio.options.connectTimeout = Duration(seconds: 5);
    _dio.options.receiveTimeout = Duration(seconds: 3);
  }

  Dio getDio() { return _dio; }
}