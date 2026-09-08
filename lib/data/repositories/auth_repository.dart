abstract class AuthRepository {
  // 기본 로그인
  Future<void> signInWithEmail(String email, String password);

  // 구글 로그인
  Future<void> signInWithGoogle();

  // 회원가입
  Future<void> signUp(String email, String password, String nickname);

  // 닉네임 중복 확인
  Future<bool> isNicknameTaken(String nickname);

  // OTP 전송
  Future<void> sendOtp(String email);

  // OTP 인증
  Future<void> verifyOtp(String email, String token);

  // 비밀번호 재설정
  Future<void> updatePassword(String newPassword);
}