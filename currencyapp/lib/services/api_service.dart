import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "https://open.er-api.com/v6/latest/";

  static Future<Map<String, dynamic>> fetchRates(String baseCurrency) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$baseCurrency'));
      if (response.statusCode == 200) {
    
        return jsonDecode(response.body)['rates'] ?? jsonDecode(response.body)['conversion_rates'];
      } else {
        return {}; 
      }
    } catch (e) {
      return {}; 
    }
  }
}

