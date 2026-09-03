import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:honey/core/constants/nutrient_codes.dart';
import 'package:honey/data/models/food_search_result.dart';
import 'package:honey/data/services/food_api_service.dart';
import 'package:http/http.dart' as http;

void main() {
  group('FoodApiService 실제 API 연동', () {
    late FoodApiService service;

    setUpAll(() async {
      await dotenv.load(fileName: '.env');
    });

    setUp(() => service = FoodApiService());

    test('[진단] 원본 응답 출력', () async {
      final response = await http.get(
        Uri.parse(dotenv.env['FOOD_BASE_URL']!).replace(queryParameters: {
          'serviceKey': dotenv.env['FOOD_API_KEY']!,
          'pageNo': '1',
          'numOfRows': '3',
          'type': 'json',
          'FOOD_NM_KR': '밥'
        })
      );

      print('=== STATUS: ${response.statusCode}');
      print('=== BODY: ${response.body}');
      expect(response.statusCode, 200);
    });

    test('검색어로 음식 목록을 반환한다', () async {
      final results = await service.searchFoods('밥');

      expect(results, isNotEmpty);
      expect(results.first.foodName, isNotEmpty);
      expect(results.first.calories, isNotNull);
    });

    test('결과에 13개 영양소 매핑이 포함된다', () async {
      final results = await service.searchFoods('닭가슴살');

      expect(results, isNotEmpty);
      final item = results.first;
      expect(item.nutrients.containsKey(NutrientCodes.energy), isTrue);
      expect(item.nutrients.containsKey(NutrientCodes.protein), isTrue);
    });

    test('결과 항목이 FoodSearchResult로 파싱된다', () async {
      final results = await service.searchFoods('사과');

      expect(results, isA<List<FoodSearchResult>>());
    });
  });
}