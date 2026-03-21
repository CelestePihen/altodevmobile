import 'package:altodevmobile/services/api_client.dart';
import 'package:dio/dio.dart';

class ElementService {
  static final ElementService instance = ElementService._init();
  final ApiClient _apiClient = ApiClient.instance;

  // private constructor
  ElementService._init();

  // POST /element
  /// [key] MESSAGE, COULEUR, ICONE, GPS LOCALISATION
  Future<void> sendElement({String relationCode = "ALICE123", String type = "MESSAGE", String value = "Hello, World!"}) async {
    try {
      await _apiClient.getDio().post('/element', data: {
        "relationCode": relationCode,
        "key": type,
        "value": value
      });
    } on DioException catch(e) {
      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Message: ${e.response?.data}');
      }
      else {
        print('Type: ${e.type}');
        print('Message: ${e.message}');
      }
    }
  }

  // GET element?relationCode={relationCode}
  Future<Map<String, String>> getElement({String relationCode = "ALICE123"}) async {
    try {
      final Response response = await _apiClient.getDio().get(
        '/element?relationCode=$relationCode',
      );

      final List elements = response.data['elements'] ?? [];
      if (elements.isEmpty) return {};

      final Map<String, dynamic> latest = Map<String, dynamic>.from(elements.last);

      return {
        "creationDate": (latest['creationDate'] ?? "").toString(),
        "key": (latest['key'] ?? "").toString(),
        "value": (latest['value'] ?? "").toString(),
      };
    } on DioException catch (e) {
      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Message: ${e.response?.data}');
      } else {
        print('Type: ${e.type}');
        print('Message: ${e.message}');
      }
      return {};
    }
  }

}