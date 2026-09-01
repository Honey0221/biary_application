import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:honey/core/constants/app_colors.dart';
import 'package:honey/data/local/local_child_profile.dart';
import 'package:honey/presentation/widgets/biary_button.dart';
import 'package:honey/presentation/widgets/biary_dialog.dart';
import 'package:uuid/uuid.dart';

class GuestEntryScreen extends StatefulWidget {
  const GuestEntryScreen({super.key});

  @override
  State<GuestEntryScreen> createState() => _GuestEntryScreenState();
}

class _GuestEntryScreenState extends State<GuestEntryScreen> {
  int _step = 1;
  bool _goingForward = true;

  // step 1
  DateTime? _birthDate;
  String? _gender;
  String? _step1Error;

  // step 2
  String? _mealType;
  String? _step2Error;
  final _foodControllers = <TextEditingController>[TextEditingController()];
  final _foodFocusNodes = <FocusNode>[FocusNode()];

  bool get _hasAnyInput =>
    _birthDate != null || _gender != null || _mealType != null ||
    _foodControllers.any((c) => c.text.trim().isNotEmpty);

  @override
  void dispose() {
    for (final c in _foodControllers) {
      c.dispose();
    }
    for (final f in _foodFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // 날짜 선택
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 1),
      firstDate: DateTime(now.year - 7),
      lastDate: now,
      helpText: '아이 생년월일 선택',
      locale: const Locale('ko')
    );
    if (picked != null) setState(() {_birthDate = picked; _step1Error = null; });
  }

  // 스텝 자유 이동
  void _onNext() {
    setState(() { _step = 2; _goingForward = true; });
  }

  // 음식 필드 추가
  void _addFoodField() {
    setState(() {
      _foodControllers.add(TextEditingController());
      _foodFocusNodes.add(FocusNode());
      _step2Error = null;
    });
  }

  // 음식 필드 삭제
  void _removeFoodField(int index) {
    if (_foodControllers.length <= 1) return;
    setState(() {
      _foodControllers[index].dispose();
      _foodFocusNodes[index].dispose();
      _foodControllers.removeAt(index);
      _foodFocusNodes.removeAt(index);
    });
  }

  // 분석하기: 전체 유효성 검증
  Future<void> _onAnalyze() async {
    final step1Errors = <String>[];
    if (_birthDate == null) step1Errors.add('생년월일');
    if (_gender == null) step1Errors.add('성별');

    final step2Errors = <String>[];
    if (_mealType == null) step2Errors.add('식사 구분');

    final hasAnyFood = _foodControllers.any((c) => c.text.trim().isNotEmpty);
    if (!hasAnyFood) step2Errors.add('음식 목록');

    final allErrors = [...step1Errors, ...step2Errors];

    if (allErrors.isNotEmpty) {
      setState(() {
        _step1Error = step1Errors.isNotEmpty ?
          '${step1Errors.join(', ')}을(를) 입력해주세요.' : null;
        _step2Error = step2Errors.isNotEmpty ?
          '${step2Errors.join(', ')}을(를) 선택/입력해주세요.' : null;
      });
      
      if (!mounted) return;
      await BiaryDialog.show(
        context, 
        title: '입력하지 않은 항목이 있어요', 
        content: allErrors.map((e) => '• $e').join('\n'),
        confirmLabel: '확인',
        onConfirm: () {}
      );
      if (!mounted) return;

      if (step1Errors.isNotEmpty) {
        if (_step == 2) setState(() { _step = 1; _goingForward = false; });
        return;
      }
      if (step2Errors.contains('음식 목록')) {
        _foodFocusNodes.first.requestFocus();
      }
      return;
    }

    // 기존 게스트 프로필 초기화 후 저장
    setState(() { _step1Error = null; _step2Error = null; });
    final box = Hive.box<LocalChildProfile>('local_child_profiles');
    await box.clear();
    final profile = LocalChildProfile()
      ..id = const Uuid().v4()
      ..name = '게스트 아이'
      ..birthDate =
        '${_birthDate!.year}-'
        '${_birthDate!.month.toString().padLeft(2, '0')}-'
        '${_birthDate!.day.toString().padLeft(2, '0')}'
      ..gender = _gender!;
    await box.add(profile);

    final flagBox = await Hive.openBox<bool>('guestFlags');
    await flagBox.put('hasCompletedFirstRecord', true);

    if (!mounted) return;
    context.go('/guest-home'); // Phase 5 완료 후 /guest-result로 교체할 때 아래 extra 사용
    // context.go('/home', extra: {
    //   'isGuest': true,
    //   'mealType': _mealType,
    //   'foods': _foodControllers
    //     .map((c) => c.text.trim())
    //     .where((s) => s.isNotEmpty)
    //     .toList(),
    //   'profileId': profile.id
    // });
  }

  // 뒤로 가기
  void _onPrev() {
    if (!_hasAnyInput) {
      context.go('/login');
      return;
    }

    BiaryDialog.show(
      context,
      title: '작성 중인 내용이 있어요',
      content: '지금 나가면 입력한 내용이 사라집니다.\n그래도 나가시겠어요?',
      confirmLabel: '나가기',
      cancelLabel: '계속 작성',
      isDangerous: true,
      onConfirm: () => context.go('/login'),
      onCancel: () {}
    );
  }

  // Step 1 이동
  void _onGoToStep1() {
    setState(() { _step = 1; _goingForward = false; });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onPrev();
      },
      child: Scaffold(
        backgroundColor: AppColors.warmCream,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _onPrev,
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 20,
                        color: AppColors.darkGray
                      ),
                      padding: EdgeInsets.zero
                    ),
                    TextButton(
                      onPressed: () => context.go('/guest-home'),
                      child: const Text(
                        '건너뛰기',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMedium
                        )
                      )
                    )
                  ]
                ),
                const SizedBox(height: 16),
                _StepIndicator(currentStep: _step),
                const SizedBox(height: 32),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      final begin = _goingForward ?
                        const Offset(0.25, 0.0) : const Offset(-0.25, 0.0);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: begin,
                            end: Offset.zero
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOut
                          )),
                          child: child
                        ),
                      );
                    },
                    child: _step == 1 ? _GuestStep1(
                      key: const ValueKey(1),
                      birthDate: _birthDate,
                      gender: _gender,
                      errorText: _step1Error,
                      onPickDate: _pickDate,
                      onSelectGender: (g) => setState(() {
                        _gender = g;
                        _step1Error = null;
                      }),
                      onNext: _onNext,
                    ) : _GuestStep2(
                      key: const ValueKey(2),
                      mealType: _mealType, 
                      foodControllers: _foodControllers,
                      foodFocusNodes: _foodFocusNodes,
                      errorText: _step2Error, 
                      onSelectMealType: (m) => setState(() {
                        _mealType = m;
                        _step2Error = null;
                      }), 
                      onFoodChanged: () => setState(() => _step2Error = null),
                      onAddFood: _addFoodField,
                      onRemoveFood: _removeFoodField,
                      onPrev: _onGoToStep1,
                      onAnalyze: _onAnalyze
                    )
                  )
                )
              ]
            )
          )
        )
      )
    );
  }
}

// Step 1
class _GuestStep1 extends StatelessWidget {
  const _GuestStep1({
    super.key,
    required this.birthDate,
    required this.gender,
    required this.errorText,
    required this.onPickDate,
    required this.onSelectGender,
    required this.onNext
  });

  final DateTime? birthDate;
  final String? gender;
  final String? errorText;
  final VoidCallback onPickDate;
  final void Function(String) onSelectGender;
  final VoidCallback onNext;

  String _formatDate(DateTime d) => '${d.year}년 ${d.month}월 ${d.day}일';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '아이 정보를 입력해주세요',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.darkGray
          )
        ),
        const SizedBox(height: 6),
        const Text(
          '정확한 영양 분석에 사용됩니다.',
          style: TextStyle(fontSize: 13, color: AppColors.textMedium)
        ),
        const SizedBox(height: 32),
        const _FieldLabel('생년월일'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onPickDate,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: (errorText != null && birthDate == null) ?
                AppColors.error : AppColors.inputBorder
              )
            ),
            child: Text(
              birthDate != null ? _formatDate(birthDate!) : '생년월일을 선택해주세요.',
              style: TextStyle(
                fontSize: 14,
                color: birthDate != null ? AppColors.darkGray : AppColors.grayCaption
              )
            )
          )
        ),
        const SizedBox(height: 20),
        const _FieldLabel('성별'),
        const SizedBox(height: 8),
        Row(
          children: [
            _GenderButton(
              label: '남아',
              selected: gender == 'male',
              hasError: errorText != null && gender == null,
              onTap: () => onSelectGender('male')
            ),
            const SizedBox(width: 12),
            _GenderButton(
              label: '여아',
              selected: gender == 'female',
              hasError: errorText != null && gender == null,
              onTap: () => onSelectGender('female')
            )
          ]
        ),
        if (errorText != null) ...[
          const SizedBox(height: 10),
          Text(
            errorText!,
            style: const TextStyle(fontSize: 12, color: AppColors.error)
          )
        ],
        const Spacer(),
        BiaryButton(
          label: '다음',
          onPressed: onNext
        )
      ],
    );
  }
}

// Step 2
class _GuestStep2 extends StatelessWidget {
  const _GuestStep2({
    super.key,
    required this.mealType,
    required this.foodControllers,
    required this.foodFocusNodes,
    required this.errorText,
    required this.onSelectMealType,
    required this.onFoodChanged,
    required this.onAddFood,
    required this.onRemoveFood,
    required this.onPrev,
    required this.onAnalyze
  });

  final String? mealType;
  final List<TextEditingController> foodControllers;
  final List<FocusNode> foodFocusNodes;
  final String? errorText;
  final void Function(String) onSelectMealType;
  final VoidCallback onFoodChanged;
  final VoidCallback onAddFood;
  final void Function(int) onRemoveFood;
  final VoidCallback onPrev;
  final VoidCallback onAnalyze;

  static const _mealTypes = ['아침', '점심', '저녁', '간식'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '오늘 먹인 식단을 알려주세요',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.darkGray
          )
        ),
        const SizedBox(height: 6),
        const Text(
          '음식을 입력하면 영양소를 분석해드려요.',
          style: TextStyle(fontSize: 13, color: AppColors.textMedium)
        ),
        const SizedBox(height: 28),
        const _FieldLabel('식사 구분'),
        const SizedBox(height: 8),
        Row(
          children: _mealTypes.asMap().entries.map((entry) {
            final idx = entry.key;
            final type = entry.value;
            final isLast = idx == _mealTypes.length - 1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 8),
                child: _MealTypeButton(
                  label: type,
                  selected: mealType == type,
                  hasError: errorText != null && mealType == null,
                  onTap: () => onSelectMealType(type)
                )
              )
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const _FieldLabel('음식 목록'),
            GestureDetector(
              onTap: onAddFood,
              child: const Icon(
                Icons.add_circle_outline,
                size: 22,
                color: AppColors.primaryBrown
              )
            )
          ]
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...foodControllers.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final controller = entry.value;
                  final focusNode = foodFocusNodes[idx];
                  final isEmpty = controller.text.trim().isEmpty;
                  final showError = errorText != null && isEmpty;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            focusNode: focusNode,
                            onChanged: (_) => onFoodChanged(),
                            textInputAction: TextInputAction.next,
                            onSubmitted: (_) => onAddFood(),
                            decoration: InputDecoration(
                              hintText: '음식 이름 (예: 쌀죽)',
                              hintStyle: const TextStyle(
                                color: AppColors.grayCaption,
                                fontSize: 13
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: showError ?
                                    AppColors.error : AppColors.inputBorder
                                )
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: showError ?
                                    AppColors.error : AppColors.inputBorder
                                )
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryBrown
                                )
                              )
                            )
                          )
                        ),
                        if (foodControllers.length > 1) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => onRemoveFood(idx),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(6)
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                LucideIcons.trash2,
                                size: 15,
                                color: AppColors.textMedium
                              )
                            )
                          )
                        ]
                      ]
                    )
                  );
                }),
                if (errorText != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    errorText!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.error
                    )
                  )
                ],
                const SizedBox(height: 16)
              ]
            )
          )
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onPrev,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.primaryBrown),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)
                  )
                ),
                child: const Text(
                  '이전',
                  style: TextStyle(
                    color: AppColors.primaryBrown,
                    fontWeight: FontWeight.w600,
                    fontSize: 15
                  )
                )
              )
            ),
            const SizedBox(width: 12),
            Expanded(
              child: BiaryButton(
                label: '분석 결과 보기',
                onPressed: onAnalyze
              )
            )
          ]
        )
      ]
    );
  }
}

// 서브 위젯
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Dot(label: '아이 정보', step: 1, active: currentStep == 1),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 13.5),
            child: Container(height: 1, color: AppColors.inputBorder)
          )
        ),
        _Dot(label: '식단 입력', step: 2, active: currentStep == 2)
      ]
    );
  }
}

// 스텝 인디케이터
class _Dot extends StatelessWidget {
  const _Dot({required this.label, required this.step, required this.active});

  final String label;
  final int step;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.primaryBrown : AppColors.inputBorder
          ),
          alignment: Alignment.center,
          child: Text(
            '$step',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : AppColors.grayCaption
            )
          )
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: active ? AppColors.darkGray : AppColors.grayCaption
          )
        )
      ]
    );
  }
}

// 필드 라벨
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.darkGray
    )
  );
}

// 성별 버튼
class _GenderButton extends StatelessWidget {
  const _GenderButton({
    required this.label,
    required this.selected,
    required this.hasError,
    required this.onTap
  });

  final String label;
  final bool selected;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryBrown : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.primaryBrown :
                hasError ? AppColors.error : AppColors.inputBorder
            )
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.textMedium
            )
          )
        )
      )
    );
  }
}

// 식사 구분 버튼
class _MealTypeButton extends StatelessWidget {
  const _MealTypeButton({
    required this.label,
    required this.selected,
    required this.hasError,
    required this.onTap
  });

  final String label;
  final bool selected;
  final bool hasError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBrown : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.primaryBrown :
              hasError ? AppColors.error : AppColors.inputBorder
          )
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AppColors.textMedium
          )
        )
      )
    );
  }
}