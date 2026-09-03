import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:honey/data/models/food_search_result.dart';
import 'package:honey/data/repositories/food_api_repository.dart';

class FoodApiService implements FoodApiRepository {
  final String _baseUrl = dotenv.env['FOOD_BASE_URL'] ?? '';
  final String _apiKey = dotenv.env['FOOD_API_KEY'] ?? '';

  @override
  Future<List<FoodSearchResult>> searchFoods(String query) async {
    if (query.trim().isEmpty || _baseUrl == '' || _apiKey == '') return [];

    try {
      final response = await http.get(Uri.parse(_baseUrl).replace(queryParameters: {
        'serviceKey': _apiKey,
        'pageNo': '1',
        'numOfRows': '10',
        'type': 'json',
        'FOOD_NM_KR': query.trim()
      })).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return [];

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      final resultCode = body['header']?['resultCode'];
      if (resultCode != '00' && resultCode != '0000') return [];

      final rawItems = body['body']?['items'];
      if (rawItems == null || rawItems is! List) return [];

      final List<dynamic> items = rawItems;

      return items
        .whereType<Map<String, dynamic>>()
        .map(FoodSearchResult.fromJson)
        .toList();
    } catch (_) {
      return [];
    }
  }
}