import 'package:altodevmobile/services/api_client.dart';
import 'package:dio/dio.dart';

/// Singleton class to manage pairing relations between users with the API
class PairingService {
  static final PairingService instance = PairingService._init();
  final ApiClient _apiClient = ApiClient.instance;

  // private constructor
  PairingService._init();

  // POST /pairing
  void createPairingRelation({String relationCode = "ALICE123", String userPublicKey = "pk_alice_xyz"}) async {
    try {
      await _apiClient.getDio().post('/pairing', data: {
        "relationCode": relationCode,
        "userPublicKey": userPublicKey
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

  // GET /pairing/{relationCode}/status
  Future<String> getStatusRelation({String relationCode = "ALICE123"}) async {
    try {
      Response response = await _apiClient.getDio().get('/pairing/$relationCode/status');
      return response.data['status'] ?? "";
    } on DioException catch(e) {
      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Message: ${e.response?.data}');
      }
      else {
        print('Type: ${e.type}');
        print('Message: ${e.message}');
      }
      return "";
    }
  }

  // PUT /pairing
  Future<Map<String, String>> matchRelation({String relationCodeA = "ALICE123"
    , String relationCodeB = "BOB465", String publicKeyB = "pk_bob_abc"}) async {
    try {
      Response response = await _apiClient.getDio().put('/pairing', data: {
        "relationCodeA": relationCodeA,
        "relationCodeB": relationCodeB,
        "publicKeyB": publicKeyB
      });

      return {
        "relationCodeA": response.data['relationCodeA'] ?? "",
        "relationCodeB": response.data['relationCodeB'] ?? "",
        "publicKeyB": response.data['publicKeyB'] ?? ""
      };

    } on DioException catch(e) {
      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Message: ${e.response?.data}');
      }
      else {
        print('Type: ${e.type}');
        print('Message: ${e.message}');
      }

      return {};
    }
  }

  // DELETE /pairing?relationCodeA={relationCode}
  Future<Map<String, String>> finalizeRelation({String relationCode = "ALICE123"}) async {
    try {
      Response response = await _apiClient.getDio().delete('/pairing?relationCodeA=$relationCode');

      return {
        "publicKeyB": response.data['publicKeyB'] ?? "",
        "relationCodeB": response.data['relationCodeB'] ?? ""
      };

    } on DioException catch(e) {
      if (e.response != null) {
        print('Status code: ${e.response?.statusCode}');
        print('Message: ${e.response?.data}');
      }
      else {
        print('Type: ${e.type}');
        print('Message: ${e.message}');
      }

      return {};
    }
  }

}