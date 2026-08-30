import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:honey/data/repositories/auth_repository.dart';
import 'package:honey/data/repositories/supabase_auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(Supabase.instance.client);
});