import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:honey/presentation/widgets/biary_button.dart';
import 'package:honey/presentation/widgets/biary_checkbox_tile.dart';
import 'package:honey/presentation/widgets/biary_dialog.dart';
import 'package:honey/presentation/widgets/biary_text_field.dart';
import 'package:honey/providers/auth_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:honey/core/constants/app_colors.dart';
import 'package:honey/presentation/widgets/loading_overlay.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailPrefixCtrl = TextEditingController();
  final _customDomainCtrl = TextEditingController();
  String? _selectedDomain;

  final _passwordCtrl = TextEditingController();
  final _passwordConfirmCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();

  final _emailPrefixFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _passwordConfirmFocus = FocusNode();
  final _nicknameFocus = FocusNode();

  String? _emailError;
  String? _passwordError;
  String? _passwordConfirmError;
  String? _nicknameError;

  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  bool _nicknameChecked = false; // 중복 확인 완료 여부
  bool _nicknameAvailable = false; // 사용 가능 여부
  bool _termsAgreed = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailPrefixCtrl.dispose();
    _customDomainCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordConfirmCtrl.dispose();
    _nicknameCtrl.dispose();
    _emailPrefixFocus.dispose();
    _passwordFocus.dispose();
    _passwordConfirmFocus.dispose();
    _nicknameFocus.dispose();
    super.dispose();
  }

  // 조합된 이메일 주소
  String get _fullEmail {
    final prefix = _emailPrefixCtrl.text.trim();
    final domain = _selectedDomain == '직접 입력' ?
      _customDomainCtrl.text.trim() : (_selectedDomain ?? '');
    if (prefix.isEmpty || domain.isEmpty) return '';
    return '$prefix@$domain';
  }

  // 유효성 검사
  String? _validateEmail(String value) {
    if (value.trim().isEmpty) return '이메일을 입력해주세요.';
    final regex = RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$');
    if (!regex.hasMatch(value.trim())) return '올바른 이메일 형식이 아닙니다.';
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return '비밀번호를 입력해주세요.';
    if (value.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
    if (!RegExp(r'[a-zA-Z]').hasMatch(value)) return '영문자를 포함해야 합니다.';
    if (!RegExp(r'[0-9]').hasMatch(value)) return '숫자를 포함해야 합니다.';
    return null;
  }

  String? _validatePasswordConfirm(String value) {
    if (value.isEmpty) return '비밀번호 확인을 입력해주세요.';
    if (value != _passwordCtrl.text) return '비밀번호가 일치하지 않습니다.';
    return null;
  }

  String? _validateNickname(String value) {
    if (value.trim().isEmpty) return '닉네임을 입력해주세요.';
    if (value.trim().length < 2 || value.trim().length > 20) {
      return '닉네임은 2자 이상 20자 이하여야 합니다.';
    }
    return null;
  }

  bool _validateAll() {
    final emailErr = _validateEmail(_fullEmail);
    final pwErr = _validatePassword(_passwordCtrl.text);
    final pwConfirmErr = _validatePasswordConfirm(_passwordConfirmCtrl.text);
    final nicknameErr = _validateNickname(_nicknameCtrl.text);

    setState(() {
      _emailError = emailErr;
      _passwordError = pwErr;
      _passwordConfirmError = pwConfirmErr;
      _nicknameError = nicknameErr;
    });

    return emailErr == null && pwErr == null &&
      pwConfirmErr == null && nicknameErr == null;
  }

  // 닉네임 중복 확인
  Future<void> _checkNickname() async {
    final err = _validateNickname(_nicknameCtrl.text);
    if (err != null) {
      setState(() => _nicknameError = err);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final isTaken = await ref.read(authRepositoryProvider)
        .isNicknameTaken(_nicknameCtrl.text.trim());
      setState(() {
        _nicknameChecked = true;
        _nicknameAvailable = !isTaken;
        _nicknameError = isTaken ? '이미 사용 중인 닉네임입니다.' : null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임 확인 중 오류가 발생했습니다.'))
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 약관 화면 이동
  Future<void> _openTerms() async {
    final agreed = await context.push<bool>('/terms');
    if (agreed == true && mounted) {
      setState(() => _termsAgreed = true);
    }
  }
  
  // 회원가입 처리
  Future<void> _submit() async {
    if (!_validateAll()) {
      if (_emailError != null) {
        _emailPrefixFocus.requestFocus();
      } else if (_passwordError != null) {
        _passwordFocus.requestFocus();
      } else if (_passwordConfirmError != null) {
        _passwordConfirmFocus.requestFocus();
      } else if (_nicknameError != null) {
        _nicknameFocus.requestFocus();
      }
      return;
    }
    if (!_termsAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('개인정보처리방침에 동의해주세요.'))
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await ref.read(authRepositoryProvider)
        .signUp(_fullEmail, _passwordCtrl.text, _nicknameCtrl.text.trim());
      if (!mounted) return;
      await BiaryDialog.show(
        context,
        title: '회원가입 완료',
        content: '바이어리에 오신 것을 환영해요!\n아이 프로필을 등록하시겠어요?',
        cancelLabel: '다음에',
        confirmLabel: '이동',
        onCancel: () => context.go('/home'),
        onConfirm: () => context.go('/child/new')
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()))
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
          title: const Text(
            '회원가입',
            style: TextStyle(
              color: AppColors.darkGray,
              fontSize: 17,
              fontWeight: FontWeight.w600
            )
          ),
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.darkGray),
            onPressed: () => context.pop()
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: BiaryTextField(
                        controller: _emailPrefixCtrl,
                        hint: '아이디',
                        keyboardType: TextInputType.emailAddress,
                        focusNode: _emailPrefixFocus,
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                        errorText: _emailError,
                        onChanged: (_) => setState(() => _emailError = null)
                      )
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 15, left: 8, right: 6),
                      child: const Text(
                        '@',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.darkGray,
                          fontWeight: FontWeight.w500
                        )
                      )
                    ),
                    Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.inputBorder)
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDomain,
                          hint: const Text(
                            '이메일 선택',
                            style: TextStyle(fontSize: 13, color: AppColors.grayCaption),
                          ),
                          style: const TextStyle(fontSize: 13, color: AppColors.darkGray),
                          items: ['gmail.com', 'naver.com', '직접 입력'].map(
                            (d) => DropdownMenuItem(value: d, child: Text(d))
                          ).toList(),
                          onChanged: (v) => setState(() {
                            _selectedDomain = v!;
                            _emailError = null;
                          })
                        )
                      )
                    )
                  ]
                ),
                if (_selectedDomain == '직접 입력') ...[
                  const SizedBox(height: 8),
                  BiaryTextField(
                    controller: _customDomainCtrl,
                    hint: '이메일',
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                    onChanged: (_) => setState(() => _emailError = null)
                  )
                ],
                const SizedBox(height: 12),
                BiaryTextField(
                  controller: _passwordCtrl,
                  hint: '비밀번호 (영문+숫자 8자 이상)',
                  obscureText: _obscurePassword,
                  focusNode: _passwordFocus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _passwordConfirmFocus.requestFocus(),
                  errorText: _passwordError,
                  onChanged: (_) => setState(() => _passwordError = null),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                      color: AppColors.grayCaption,
                      size: 20
                    ),
                    onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  )
                ),
                const SizedBox(height: 12),
                BiaryTextField(
                  controller: _passwordConfirmCtrl,
                  hint: '비밀번호 확인',
                  obscureText: _obscurePasswordConfirm,
                  focusNode: _passwordConfirmFocus,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _nicknameFocus.requestFocus(),
                  errorText: _passwordConfirmError,
                  onChanged: (_) => setState(() => _passwordConfirmError = null),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePasswordConfirm ? LucideIcons.eyeOff : LucideIcons.eye,
                      color: AppColors.grayCaption,
                      size: 20
                    ),
                    onPressed: () =>
                        setState(() => _obscurePasswordConfirm = !_obscurePasswordConfirm)
                  )
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: BiaryTextField(
                        controller: _nicknameCtrl,
                        hint: '닉네임 (2~20자)',
                        focusNode: _nicknameFocus,
                        textInputAction: TextInputAction.done,
                        errorText: _nicknameError,
                        onChanged: (_) => setState(() {
                          _nicknameError = null;
                          _nicknameChecked = false;
                          _nicknameAvailable = false;
                        })
                      )
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 96,
                      child: BiaryButton(
                        label: '중복확인',
                        type: BiaryButtonType.outlined,
                        onPressed: _checkNickname,
                        height: 52
                      )
                    )
                  ]
                ),
                if (_nicknameChecked && _nicknameAvailable)
                  const Padding(
                    padding: EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      '사용 가능한 닉네임입니다.',
                      style: TextStyle(color: Colors.green, fontSize: 12)
                    )
                  ),
                const SizedBox(height: 28),
                BiaryCheckboxTile(
                  label: '개인정보처리방침 동의 (필수)',
                  value: _termsAgreed,
                  onChanged: (v) async {
                    if (v == true) {
                      await _openTerms();
                    } else {
                      setState(() => _termsAgreed = false);
                    }
                  },
                  linkText: '보기',
                  onLinkTap: _openTerms
                ),
                const SizedBox(height: 32),
                BiaryButton(
                  label: '가입하기',
                  onPressed:
                    (_nicknameChecked && _nicknameAvailable) ? _submit : null
                ),
                const SizedBox(height: 24)
              ]
            )
          )
        )
      )
    );
  }
}