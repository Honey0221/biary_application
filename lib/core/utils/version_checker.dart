import 'package:honey/main.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionChecker {
  VersionChecker._();

  // 현재 앱 버전 조회
  static Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  // 최소 요구 앱 버전 조회(app_config - min_required_version)
  static Future<String?> getMinRequiredVersion() async {
    try {
      final res = await supabase.from('app_config')
        .select('value')
        .eq('key', 'min_required_version')
        .maybeSingle();
      return res?['value'] as String?;
    } catch (_) {
      return null; // 네트워크 오류 시 업데이트 강제 안 함
    }
  }

  // 업데이트 필요 여부 확인
  static bool isUpdateRequired(String current, String minRequired) {
    final c = _parse(current);
    final m = _parse(minRequired);

    for (int i = 0; i < 3; i++) {
      if (c[i] < m[i]) return true;
      if (c[i] > m[i]) return false;
    }
    return false;
  }

  // 버전 값 파싱 함수
  static List<int> _parse(String version) {
    final parts = version.split('.')
      .map((e) => int.tryParse(e) ?? 0).toList();

    while (parts.length < 3) {
      parts.add(0);
    }
    return parts;
  }
}