import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _foodFocusNodes.last.requestFocus()
    );
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

    if (!mounted) return;
    context.go('/home'); // Phase 5 완료 후 /guest-result로 교체할 때 아래 extra 사용
    // context.go('/home', extra: {
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
    if (_step == 2) {
      setState(() { _step = 1; _goingForward = false; });
    } else {
      context.pop();
    }
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
                IconButton(
                  onPressed: _onPrev,
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: AppColors.darkGray
                  ),
                  padding: EdgeInsets.zero
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
        const _FieldLabel('음식 목록'),
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
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceMuted,
                                borderRadius: BorderRadius.circular(6)
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: AppColors.textMedium
                              )
                            )
                          )
                        ]
                      ]
                    ),
                  );
                }),
                GestureDetector(
                  onTap: onAddFood,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Icon(
                      Icons.add_circle_outline,
                      size: 28,
                      color: AppColors.primaryBrown
                    )
                  )
                ),
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
        BiaryButton(label: '분석 결과 보기', onPressed: onAnalyze)
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
      children: [
        _Dot(label: '아이 정보', active: currentStep == 1, done: currentStep > 1),
        Expanded(child: Container(height: 1, color: AppColors.inputBorder)),
        _Dot(label: '식단 입력', active: currentStep == 2, done: false)
      ]
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.label, required this.active, required this.done});
  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final highlighted = active || done;
    return Column(
      children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: highlighted ? AppColors.primaryBrown : AppColors.inputBorder
          ),
          alignment: Alignment.center,
          child: done ? const Icon(Icons.check, size: 14, color: Colors.white)
            : Text(
              active ? '1' : '2',
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
            color: highlighted ? AppColors.darkGray : AppColors.grayCaption
          )
        )
      ]
    );
  }
}

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