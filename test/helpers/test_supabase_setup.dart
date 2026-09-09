import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 통합 테스트용 Supabase 초기화
Future<SupabaseClient> setupSupabase() async {
  SharedPreferencesStorePlatform.instance =
    InMemorySharedPreferencesStore.empty();

  await dotenv.load(fileName: '.env');

  // 이미 초기화된 경우 기존 인스턴스 반환
  try {
    return Supabase.instance.client;
  } catch (_) {}

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!
  );
  return Supabase.instance.client;
}