import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:honey/core/constants/app_colors.dart';
import 'package:honey/core/utils/age_calculator.dart';
import 'package:honey/data/models/child_profile.dart';
import 'package:honey/presentation/widgets/biary_button.dart';
import 'package:honey/presentation/widgets/biary_dialog.dart';
import 'package:honey/presentation/widgets/biary_labeled_field.dart';
import 'package:honey/presentation/widgets/biary_select_button.dart';
import 'package:honey/presentation/widgets/loading_overlay.dart';
import 'package:honey/providers/child_profile_provider.dart';

class ChildFormScreen extends ConsumerStatefulWidget {
  // null -> S-11 등록 모드 || ChildProfile -> S-12 수정모드
  final ChildProfile? initialProfile;

  const ChildFormScreen({super.key, this.initialProfile});

  @override
  ConsumerState<ChildFormScreen> createState() => _ChildFormScreenState();
}

class _ChildFormScreenState extends ConsumerState<ChildFormScreen> {
  final _nameCtrl = TextEditingController();
  final _allergyCtrl = TextEditingController();
  DateTime? _birthDate;
  String _gender = 'unspecified';
  bool _isLoading = false;

  bool get _isEditMode => widget.initialProfile != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final p = widget.initialProfile!;
      _nameCtrl.text = p.name;
      _birthDate = p.birthDate;
      _gender = p.gender;
      _allergyCtrl.text = p.allergyNotes ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _allergyCtrl.dispose();
    super.dispose();
  }

  String? get _ageLabel =>
    _birthDate != null ? AgeCalculator.toLabel(_birthDate!) : null;

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? now,
      firstDate: DateTime(now.year - 8),
      lastDate: now,
      helpText: '생년월일 선택'
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('아이 이름을 입력해주세요.')));
      return;
    }
    if (_birthDate == null) {
      ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('생년월일을 선택해주세요.')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(childProfileRepositoryProvider);
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) {
        ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
        return;
      }
      final allergy =
        _allergyCtrl.text.trim().isEmpty ? null : _allergyCtrl.text.trim();

      if (_isEditMode) {
        await repo.updateProfile(widget.initialProfile!.copyWith(
          name: _nameCtrl.text.trim(),
          birthDate: _birthDate,
          gender: _gender,
          allergyNotes: allergy
        ));
      } else {
        await repo.createProfile(ChildProfile(
          id: '',
          userId: userId,
          name: _nameCtrl.text.trim(),
          birthDate: _birthDate!,
          gender: _gender,
          allergyNotes: allergy,
          createdAt: DateTime.now()
        ));
      }
      if (mounted) context.go('/home');
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _confirmDelete() {
    BiaryDialog.show(
      context,
      title: '프로필 삭제',
      content: '${widget.initialProfile!.name} 프로필을 삭제하시겠어요?\n'
        '이 작업은 되돌릴 수 없습니다.',
      confirmLabel: '삭제',
      cancelLabel: '취소',
      isDangerous: true,
      onConfirm: _performDelete
    );
  }

  Future<void> _performDelete() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(childProfileRepositoryProvider)
        .deleteProfile(widget.initialProfile!.id);
      if (mounted) context.go('/home');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제 중 오류가 발생했습니다.'))
        );
      }
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
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.darkGray),
            onPressed: () => context.canPop() ? context.pop() : context.go('/home')
          ),
          title: Text(
            _isEditMode ? '아이 프로필 수정' : '아이 프로필 등록',
            style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.darkGray
            )
          ),
          actions: [
            if (!_isEditMode)
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text(
                  '건너뛰기',
                  style: TextStyle(color: AppColors.textMedium, fontSize: 14)
                )
              ),
            const SizedBox(width: 4)
          ]
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: () {}, // TODO: Phase 8 프로필 이미지 image_picker 연동 예정
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.surfaceMuted,
                    child: const Icon(
                      Icons.camera_alt_outlined,
                      size: 28,
                      color: AppColors.grayCaption
                    )
                  )
                )
              ),
              const SizedBox(height: 28),
              BiaryLabeledField(
                label: '아이 이름',
                controller: _nameCtrl,
                hint: '이름을 입력해주세요',
                textInputAction: TextInputAction.done
              ),
              const SizedBox(height: 20),
              const Text(
                '생년월일',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkGray
                )
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickBirthDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.inputBorder),
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _birthDate != null ?
                            '${_birthDate!.year}.'
                            '${_birthDate!.month.toString().padLeft(2, '0')}.'
                            '${_birthDate!.day.toString().padLeft(2, '0')}'
                          : '날짜를 선택해주세요',
                          style: TextStyle(
                            fontSize: 14,
                            color: _birthDate != null ?
                              AppColors.darkGray : AppColors.grayCaption
                          )
                        )
                      ),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 18, color: AppColors.grayCaption
                      )
                    ]
                  )
                )
              ),
              if (_ageLabel != null) ...[
                const SizedBox(height: 6),
                Text(_ageLabel!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primaryBrown
                  )
                )
              ],
              const SizedBox(height: 20),
              const Text(
                '성별',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkGray
                )
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: BiarySelectButton(
                      label: '남아',
                      selected: _gender == 'male',
                      onTap: () => setState(() => _gender = 'male')
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: BiarySelectButton(
                      label: '여아',
                      selected: _gender == 'female',
                      onTap: () => setState(() => _gender = 'female')
                    )
                  )
                ]
              ),
              const SizedBox(height: 20),
              BiaryLabeledField(
                label: '알레르기 메모 (선택)',
                controller: _allergyCtrl,
                hint: '예: 땅콩, 계란, 우유',
                maxLines: 3
              ),
              const SizedBox(height: 32),
              BiaryButton(
                label: _isEditMode ? '수정' : '저장',
                onPressed: _submit,
              ),
              if (_isEditMode) ...[
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _confirmDelete,
                    child: const Text(
                      '삭제',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 14,
                        fontWeight: FontWeight.w500
                      )
                    )
                  )
                )
              ]
            ]
          )
        )
      )
    );
  }
}