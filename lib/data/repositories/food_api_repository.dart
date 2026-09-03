import 'package:honey/data/models/food_search_result.dart';

abstract class FoodApiRepository {
  Future<List<FoodSearchResult>> searchFoods(String query);
}