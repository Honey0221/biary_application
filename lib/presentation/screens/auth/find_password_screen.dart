import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:honey/presentation/widgets/biary_button.dart';
import 'package:honey/presentation/widgets/biary_text_field.dart';
import 'package:honey/providers/auth_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:honey/core/constants/app_colors.dart';
import 'package:honey/presentation/widgets/loading_overlay.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum _Step { email, otp, newPassword, done } // 패스워드 재설정 단계

class FindPasswordScreen extends ConsumerStatefulWidget {
  const FindPasswordScreen({super.key});

  @override
  ConsumerState<FindPasswordScreen> createState() => _FindPasswordScreenState();
}

class _FindPasswordScreenState extends ConsumerState<FindPasswordScreen> {
  _Step _step = _Step.email;

  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _newPasswordConfirmCtrl = TextEditingController();

  String? _emailError;
  String? _otpError;
  String? _newPasswordError;
  String? _newPasswordConfirmError;

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  Timer? _timer;
  int _remainSeconds = 300; // 5분

  @override
  void dispose() {
    _timer?.cancel();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _newPasswordCtrl.dispose();
    _newPasswordConfirmCtrl.dispose();
    super.dispose();
  }

  // 타이머 시작
  void _startTimer() {
    _remainSeconds = 300;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_remainSeconds <= 0) {
        t.cancel();
        setState(() {});
      } else {
        setState(() => _remainSeconds--);
      }
    });
  }

  // 타이머 텍스트
  String get _timerText {
    final m = _remainSeconds ~/ 60;
    final s = _remainSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // Step 1. 인증번호 발송
  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = '이메일을 입력해주세요.');
      return;
    }
    final regex = RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$');
    if (!regex.hasMatch(email)) {
      setState(() => _emailError = '올바른 이메일 형식이 아닙니다.');
      return;
    }
    setState(() { _isLoading = true; _emailError = null; });
    try {
      await ref.read(authRepositoryProvider).sendOtp(_emailCtrl.text.trim());
      if (!mounted) return;
      _startTimer();
      setState(() => _step = _Step.otp);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message))
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오류가 발생했습니다. 다시 시도해주세요.'))
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Step 2. OTP 검증
  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      setState(() => _otpError = '인증번호 6자리를 입력해주세요.');
      return;
    }
    if (_remainSeconds <= 0) {
      setState(() => _otpError = '인증 시간이 만료되었습니다. 다시 발송해주세요.');
      return;
    }
    setState(() { _isLoading = true; _otpError = null; });
    try {
      await ref.read(authRepositoryProvider)
        .verifyOtp(_emailCtrl.text.trim(), _otpCtrl.text.trim());
      if (!mounted) return;
      _timer?.cancel();
      setState(() => _step = _Step.newPassword);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _otpError = e.message);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('인증 중 오류가 발생했습니다.'))
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Step 3. 비밀번호 재설정
  Future<void> _resetPassword() async {
    final pw = _newPasswordCtrl.text;
    final pwConfirm = _newPasswordConfirmCtrl.text;

    String? pwErr;
    String? confirmErr;

    if (pw.isEmpty) {pwErr = '비밀번호를 입력해주세요.';}
    else if (pw.length < 8) {pwErr = '비밀번호는 8자 이상이어야 합니다.';}
    else if (!RegExp(r'[a-zA-Z]').hasMatch(pw)) {pwErr = '영문자를 포함해야 합니다.';}
    else if (!RegExp(r'[0-9]').hasMatch(pw)) {pwErr = '숫자를 포함해야 합니다.';}

    if (pwConfirm.isEmpty) {confirmErr = '비밀번호 확인을 입력해주세요.';}
    else if (pwConfirm != pw) {confirmErr = '비밀번호가 일치하지 않습니다.';}

    setState(() {
      _newPasswordError = pwErr;
      _newPasswordConfirmError = confirmErr;
    });
    if (pwErr != null || confirmErr != null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider).updatePassword(_newPasswordCtrl.text);
      if (!mounted) return;
      setState(() => _step = _Step.done);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message))
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호 변경 중 오류가 발생했습니다.'))
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: AppColors.warmCream,
        appBar: AppBar(
          backgroundColor: AppColors.warmCream,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.darkGray),
            onPressed: () => context.pop()
          ),
          title: const Text(
            '비밀번호 찾기',
            style: TextStyle(
              color: AppColors.darkGray,
              fontSize: 17,
              fontWeight: FontWeight.w600
            )
          )
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: _buildStep()
          )
        )
      )
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.email:
        return _buildEmailStep();
      case _Step.otp:
        return _buildOtpStep();
      case _Step.newPassword:
        return _buildNewPasswordStep();
      case _Step.done:
        return _buildDoneStep();
    }
  }

  // Step 1 UI
  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '가입하신 이메일에 인증 번호를 보내드립니다.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMedium,
            height: 1.6
          )
        ),
        const SizedBox(height: 24),
        BiaryTextField(
          controller: _emailCtrl,
          hint: '이메일',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          errorText: _emailError,
          onChanged: (_) => setState(() => _emailError = null),
        ),
        const SizedBox(height: 20),
        BiaryButton(label: '인증번호 발송', onPressed: _sendOtp)
      ]
    );
  }

  // Step 2 UI
  Widget _buildOtpStep() {
    final isExpired = _remainSeconds <= 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '입력하신 이메일로 인증번호를 발송했습니다.',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textMedium,
            height: 1.6
          )
        ),
        const SizedBox(height: 24),
        BiaryTextField(
          controller: _otpCtrl,
          hint: '인증번호',
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          errorText: _otpError,
          onChanged: (_) => setState(() => _otpError = null),
          enabled: !isExpired
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isExpired ? '인증 시간이 만료되었습니다.' : '남은 시간: $_timerText',
              style: TextStyle(
                fontSize: 13,
                color: isExpired ? AppColors.error : AppColors.grayCaption
              )
            ),
            GestureDetector(
              onTap: _sendOtp,
              child: const Text(
                '재발송',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primaryBrown,
                  decoration: TextDecoration.underline
                )
              )
            )
          ]
        ),
        const SizedBox(height: 20),
        BiaryButton(
          label: '확인',
          onPressed: isExpired ? null : _verifyOtp
        )
      ]
    );
  }

  // Step 3 UI
  Widget _buildNewPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '새로운 비밀번호를 입력해주세요.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textMedium
          ),
        ),
        const SizedBox(height: 24),
        BiaryTextField(
          controller: _newPasswordCtrl,
          hint: '새 비밀번호 (영문+숫자 8자 이상)',
          obscureText: _obscureNew,
          textInputAction: TextInputAction.next,
          errorText: _newPasswordError,
          onChanged: (_) => setState(() => _newPasswordError = null),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureNew ? LucideIcons.eyeOff : LucideIcons.eye,
              color: AppColors.grayCaption,
              size: 20
            ),
            onPressed: () => setState(() => _obscureNew = !_obscureNew)
          )
        ),
        const SizedBox(height: 12),
        BiaryTextField(
          controller: _newPasswordConfirmCtrl,
          hint: '새 비밀번호 확인',
          obscureText: _obscureConfirm,
          textInputAction: TextInputAction.done,
          errorText: _newPasswordConfirmError,
          onChanged: (_) => setState(() => _newPasswordConfirmError = null),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye,
              color: AppColors.grayCaption,
              size: 20
            ),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)
          )
        ),
        const SizedBox(height: 20),
        BiaryButton(label: '비밀번호 재설정', onPressed: _resetPassword)
      ]
    );
  }

  // Step 4 UI
  Widget _buildDoneStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        const Icon(
          LucideIcons.circleCheck,
          size: 56,
          color: AppColors.primaryBrown
        ),
        const SizedBox(height: 24),
        const Text(
          '비밀번호가 재설정 완료!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray
          )
        ),
        const SizedBox(height: 40),
        BiaryButton(
          label: '로그인 화면 이동',
          onPressed: () => context.go('/login')
        )
      ]
    );
  }
}