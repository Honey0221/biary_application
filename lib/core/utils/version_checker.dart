import 'package:package_info_plus/package_info_plus.dart';

class VersionChecker {
  VersionChecker._();

  static Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  static bool isUpdateRequired(String currentVersion, String minRequiredVersion) {
    // TODO: Phase 2에서 구현
    throw UnimplementedError('Phase 2에서 구현 예정');
  }
}