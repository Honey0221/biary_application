import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:honey/core/router/app_router.dart';
import 'package:honey/data/local/guest_session.dart';
import 'package:honey/data/local/local_child_profile.dart';
import 'package:honey/core/constants/app_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // env 파일 로드
  await dotenv.load(fileName: ".env");

  // Supabase 초기화
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!
  );

  // Hive 초기화 (게스트 모드 로컬 저장소)
  await Hive.initFlutter();

  // Hive 어댑터 등록
  Hive.registerAdapter(GuestSessionAdapter());
  Hive.registerAdapter(LocalChildProfileAdapter());

  // Hive 박스 열기
  await Hive.openBox<GuestSession>('guest_session');
  await Hive.openBox<LocalChildProfile>('local_child_profiles');

  runApp(
    const ProviderScope(
      child: BiaryApp()
    )
  );
}

// Supabase 전역 클라이언트 접근 헬퍼
final supabase = Supabase.instance.client;

class BiaryApp extends StatelessWidget {
  const BiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadcnApp.router(
      title: 'Biary',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorSchemes.zinc(ThemeMode.light),
        radius: 0.5,
        typography: const Typography.geist(
          sans: TextStyle(fontFamily: AppFonts.pretendard)
        )
      ),
      routerConfig: appRouter
    );
  }
}