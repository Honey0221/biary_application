import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:honey/providers/auth_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:honey/core/constants/app_colors.dart';
import 'package:honey/presentation/widgets/biary_button.dart';
import 'package:honey/presentation/widgets/biary_text_field.dart';
import 'package:honey/presentation/widgets/biary_text_link.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // 일반 로그인
  Future<void> _signInWithEmail() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일을 입력해주세요.'))
      );
      _emailFocus.requestFocus();
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호를 입력해주세요.'))
      );
      _passwordFocus.requestFocus();
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithEmail(email, password);
      if (!mounted) return;
      context.go('/home');
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message))
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 중 오류가 발생했습니다.'))
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 구글 로그인
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
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
                controller: _emailCtrl,
                hint: '이메일',
                keyboardType: TextInputType.emailAddress,
                focusNode: _emailFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _passwordFocus.requestFocus()
              ),
              const SizedBox(height: 12),
              // 비밀번호 입력
              BiaryTextField(
                controller: _passwordCtrl,
                hint: '비밀번호',
                obscureText: _obscurePassword,
                focusNode: _passwordFocus,
                textInputAction: TextInputAction.done,
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
                onPressed: _isLoading ? null : _signInWithEmail,
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
                  onTap: () => context.push('/guest-entry'),
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