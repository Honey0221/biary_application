abstract class AuthRepository {
  Future<void> signInWithEmail(String email, String password);
  Future<void> signInWithGoogle();
  Future<void> signUp(String email, String password, String nickname);
  Future<bool> isNicknameTaken(String nickname);
  Future<void> sendOtp(String email);
  Future<void> verifyOtp(String email, String token);
  Future<void> updatePassword(String newPassword);
}