import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honey/data/repositories/impl/supabase_meal_record_repository.dart';
import 'package:honey/data/repositories/meal_record_repository.dart';
import 'package:honey/main.dart';

final mealRecordRepositoryProvider = Provider<MealRecordRepository>((ref) {
  return SupabaseMealRecordRepository(supabase);
});