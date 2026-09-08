import 'package:honey/data/models/food_search_result.dart';

abstract class FoodApiRepository {
  // 식품 검색
  Future<List<FoodSearchResult>> searchFoods(String query);
}