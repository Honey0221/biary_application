import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honey/data/models/food_search_result.dart';
import 'package:honey/data/repositories/food_api_repository.dart';
import 'package:honey/data/services/food_api_service.dart';

final foodApiRepositoryProvider = Provider<FoodApiRepository>(
  (_) => FoodApiService()
);

// 음식명 검색
final foodSearchProvider = FutureProvider.autoDispose
    .family<List<FoodSearchResult>, String>((ref, query) async {
  if (query.trim().length < 2) return [];
  final repo = ref.read(foodApiRepositoryProvider);
  return repo.searchFoods(query);
});