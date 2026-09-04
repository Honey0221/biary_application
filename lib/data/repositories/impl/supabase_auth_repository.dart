import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:honey/data/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signInWithGoogle() async {
    final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
    if (webClientId == null) throw Exception('Google 클라이언트 ID가 설정되지 않았습니다.');

    final googleSignIn = GoogleSignIn(serverClientId: webClientId);
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return;

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null || idToken == null) {
      throw Exception('Google 인증 토큰을 가져올 수 없습니다.');
    }

    await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken
    );
  }

  @override
  Future<void> signUp(String email, String password, String nickname) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {'display_name': nickname}
    );
  }

  @override
  Future<bool> isNicknameTaken(String nickname) async {
    final response = await _client
      .from('users')
      .select()
      .eq('display_name', nickname)
      .limit(1)
      .maybeSingle();
    return response != null;
  }

  @override
  Future<void> sendOtp(String email) async {
    await _client.auth.signInWithOtp(email: email);
  }

  @override
  Future<void> verifyOtp(String email, String token) async {
    await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email
    );
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }
}