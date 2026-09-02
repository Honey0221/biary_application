import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honey/data/repositories/auth_repository.dart';
import 'package:honey/data/repositories/impl/supabase_auth_repository.dart';
import 'package:honey/main.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(supabase);
});