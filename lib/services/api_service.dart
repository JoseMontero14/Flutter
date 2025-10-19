import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  static const String _mobileUrl = "https://api.apis.net.pe/v1/dni";
  static const String _backendWebUrl = "http://localhost:3000/dni"; // tu backend

  static const String _apiKey = "f218e2052f77477c4131347ad1a17eea1c939c3bd9714d6075989d2d1bdf3fe3";

  static Future<Map<String, dynamic>> getDniInfo(String dni) async {
    final url = kIsWeb
        ? Uri.parse("$_backendWebUrl/$dni")
        : Uri.parse("$_mobileUrl?numero=$dni");

    print("URL a llamar: $url");

    try {
      final response = await http.get(
        url,
        headers: kIsWeb
            ? {} // No necesita Authorization porque tu backend ya la maneja
            : {
                "Authorization": "Bearer $_apiKey",
                "Accept": "application/json",
              },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      throw Exception("Fallo al conectar con la API: $e");
    }
  }
}
