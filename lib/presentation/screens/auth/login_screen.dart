import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:honey/main.dart';
import 'package:honey/core/constants/app_colors.dart';
import 'package:honey/presentation/widgets/biary_button.dart';
import 'package:honey/presentation/widgets/biary_text_field.dart';
import 'package:honey/presentation/widgets/biary_text_link.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 구글 로그인
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'];
      if (webClientId == null) {
        throw Exception('Google 클라이언트 ID가 설정되지 않았습니다.');
      }
      final googleSignIn = GoogleSignIn(serverClientId: webClientId);
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('Google 인증 토큰을 가져올 수 없습니다.');
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken
      );

      if (!mounted) return;
      context.go('/home');
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message))
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구글 로그인 중 오류가 발생했습니다.'))
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 64),
              // Biary 텍스트 이미지
              Center(
                child: Image.asset(
                  'assets/images/Biary_text.png',
                  height: 36,
                  fit: BoxFit.contain
                )
              ),
              const SizedBox(height: 20),
              // 환영 문구
              const Text(
                '아이의 모든 한 끼를\n소중하게 기록해요.',
                style: TextStyle(
                  color: AppColors.darkGray,
                  fontSize: 17,
                  fontWeight: FontWeight.w300,
                  height: 1.8,
                  letterSpacing: 0.3
                ),
                textAlign: TextAlign.center
              ),
              const SizedBox(height: 48),
              // 이메일 입력
              BiaryTextField(
                controller: _emailController,
                hint: '이메일',
                keyboardType: TextInputType.emailAddress
              ),
              const SizedBox(height: 12),
              // 비밀번호 입력
              BiaryTextField(
                controller: _passwordController,
                hint: '비밀번호',
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                    color: AppColors.grayCaption,
                    size: 20
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  }
                )
              ),
              const SizedBox(height: 24),
              // 로그인 버튼
              BiaryButton(
                label: '로그인',
                onPressed: () {
                  // TODO : 로그인 로직 추가 예정
                },
              ),
              const SizedBox(height: 14),
              // 아이디 찾기 | 비밀번호 찾기
              Center(
                child: BiaryTextLink(
                  label: '비밀번호 찾기',
                  onTap: () => context.push('/find-password')
                )
              ),
              const SizedBox(height: 24),
              // 회원가입 버튼
              BiaryButton(
                label: '회원가입',
                type: BiaryButtonType.outlined,
                onPressed: () => context.push('/signup')
              ),
              const SizedBox(height: 24),
              // 구분선
              Row(
                children: [
                  const Expanded(
                    child: Divider(color: AppColors.divider, thickness: 1)
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      '또는',
                      style: TextStyle(
                        color: AppColors.grayCaption,
                        fontSize: 12
                      )
                    )
                  ),
                  const Expanded(
                    child: Divider(color: AppColors.divider, thickness: 1)
                  )
                ]
              ),
              const SizedBox(height: 24),
              // 구글 로그인
              BiaryButton(
                label: 'Google로 로그인',
                type: BiaryButtonType.outlined,
                icon: Image.asset(
                  'assets/images/google_logo.png',
                  width: 18,
                  height: 18
                ),
                onPressed: _isLoading ? null : _signInWithGoogle
              ),
              const SizedBox(height: 36),
              // 게스트로 입장하기
              Center(
                child: BiaryTextLink(
                  label: '게스트로 입장하기',
                  onTap: () {
                    // TODO : 게스트 모드 구현 예정
                  },
                  underline: true
                )
              ),
              const SizedBox(height: 24)
            ]
          )
        )
      )
    );
  }
}