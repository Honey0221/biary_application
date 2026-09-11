import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:honey/core/constants/app_colors.dart';
import 'package:honey/core/utils/age_calculator.dart';
import 'package:honey/data/models/meal_item.dart';
import 'package:honey/data/models/meal_record.dart';
import 'package:honey/data/models/meal_record_photo.dart';
import 'package:honey/data/services/analysis_service.dart';
import 'package:honey/main.dart';
import 'package:honey/presentation/screens/child/widgets/child_switch_sheet.dart';
import 'package:honey/presentation/screens/meal/widgets/child_selector.dart';
import 'package:honey/presentation/screens/meal/widgets/food_entry.dart';
import 'package:honey/presentation/screens/meal/widgets/food_item_card.dart';
import 'package:honey/presentation/screens/meal/widgets/meal_date_picker.dart';
import 'package:honey/presentation/screens/meal/widgets/photo_thumbnail.dart';
import 'package:honey/presentation/widgets/biary_button.dart';
import 'package:honey/presentation/widgets/biary_dialog.dart';
import 'package:honey/presentation/widgets/biary_select_button.dart';
import 'package:honey/presentation/widgets/biary_text_field.dart';
import 'package:honey/presentation/widgets/loading_overlay.dart';
import 'package:honey/providers/ui_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../core/utils/analysis_flow_helper.dart';
import '../../../core/utils/nutrient_calculator.dart';
import '../../../data/models/analysis_result.dart';
import '../../../data/models/child_profile.dart';
import '../../../providers/analysis_provider.dart';
import '../../../providers/child_profile_provider.dart';
import '../../../providers/meal_record_provider.dart';
import '../analysis/widgets/analysis_loading_overlay.dart';

class MealRecordFormScreen extends ConsumerStatefulWidget {
  // null -> 신규 / non-null -> 수정(S-08)
  final MealRecord? initialRecord;

  const MealRecordFormScreen({super.key, this.initialRecord});

  @override
  ConsumerState<MealRecordFormScreen> createState() => _MealRecordFormScreenState();
}

class _MealRecordFormScreenState extends ConsumerState<MealRecordFormScreen> {
  static const _mealTypeLabels = ['아침', '점심', '저녁', '간식'];
  static const _mealTypeValues = ['breakfast', 'lunch', 'dinner', 'snack'];

  late DateTime _selectedDate;
  late String _selectedMealType;
  late List<FoodEntry> _foodEntries;

  late List<MealRecordPhoto> _existingPhotos;
  final List<String> _deletedPhotoIds = [];
  final List<String> _localPhotoPaths = [];

  final _memoCtrl = TextEditingController();
  final _picker = ImagePicker();

  bool _isLoading = false;
  String? _foodListError;

  bool get _isEditMode => widget.initialRecord != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tabBarVisibleProvider.notifier).state = false;
    });

    if (_isEditMode) {
      final r = widget.initialRecord!;
      _selectedDate = r.mealDate;
      _selectedMealType = r.mealType;
      _memoCtrl.text = r.memo ?? '';
      _existingPhotos = List.of(r.photos);
      _foodEntries = r.items.map((item) =>
          FoodEntry(
              name: item.customFoodName,
              amount: item.intakeAmountG?.toStringAsFixed(0) ?? '',
              reactionType: item.reactionType
          )).toList();
      if (_foodEntries.isEmpty) _foodEntries.add(FoodEntry());
    } else {
      _selectedDate = DateTime.now();
      _selectedMealType = 'breakfast';
      _existingPhotos = [];
      _foodEntries = [FoodEntry()];
    }
  }

  @override
  void dispose() {
    for (final e in _foodEntries) {
      e.dispose();
    }
    _memoCtrl.dispose();
    ref.read(tabBarVisibleProvider.notifier).state = true;
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      helpText: '날짜 선택'
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  int get _totalPhotoCount =>
    (_existingPhotos.length - _deletedPhotoIds.length) + _localPhotoPaths.length;

  Future<void> _pickPhoto() async {
    if (_totalPhotoCount >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('사진은 최대 3장까지 첨부할 수 있어요'))
      );
      return;
    }
    final source = await _showPhotoSourceDialog();
    if (source == null) return;
    final xFile = await _picker.pickImage(source: source, imageQuality: 80);
    if (xFile != null) setState(() => _localPhotoPaths.add(xFile.path));
  }

  Future<ImageSource?> _showPhotoSourceDialog() {
    return showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('사진 첨부'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(LucideIcons.camera),
              title: const Text('카메라로 촬영'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera)
            ),
            ListTile(
              leading: const Icon(LucideIcons.image),
              title: const Text('갤러리에서 선택'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery)
            )
          ]
        )
      )
    );
  }

  bool _validate() {
    final child = ref.read(selectedChildProvider);
    if (child == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이를 선택해주세요'))
      );
      return false;
    }
    final hasFood = _foodEntries.any((e) => e.nameCtrl.text.trim().isNotEmpty);
    if (!hasFood) {
      setState(() => _foodListError = '음식을 최소 1개 입력해주세요');
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (!_validate()) return;

    final child = ref.read(selectedChildProvider);
    final userId = ref.read(currentUserIdProvider);

    final items = _foodEntries
      .where((e) => e.nameCtrl.text.trim().isNotEmpty)
      .map((e) => MealItem(
        customFoodName: e.nameCtrl.text.trim(),
        intakeAmountG: double.tryParse(e.amountCtrl.text.trim()),
        reactionType: e.reactionType
      )).toList();

    final remainingPhotos = _existingPhotos
      .where((p) => !_deletedPhotoIds.contains(p.id)).toList();

    final record = MealRecord(
      id: widget.initialRecord?.id,
      childId: child!.id,
      mealDate: _selectedDate,
      mealType: _selectedMealType,
      items: items,
      photos: remainingPhotos,
      memo: _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
      createdBy: userId
    );

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(mealRecordRepositoryProvider);
      if (_isEditMode) {
        // 수정 저장 : 삭제 요청된 기존 사진 처리 -> 이전 화면 복귀
        for (final id in _deletedPhotoIds) {
          await repo.deletePhoto(id);
        }
        await repo.updateRecord(
          record: record,
          localPhotosPaths: _localPhotoPaths
        );
        if (mounted) context.pop();
      } else {
        // 신규 저장 : 분석 여부 확인
        final saved = await repo.createRecord(
          record: record,
          localPhotoPaths: _localPhotoPaths
        );
        if (!mounted) return;
        _showAnalysisDialog(saved, child);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 중 오류가 발생했습니다: $e'))
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onClose() {
    final hasContent = _foodEntries.any((e) => e.nameCtrl.text.isNotEmpty)
      || _memoCtrl.text.isNotEmpty || _localPhotoPaths.isNotEmpty;

    if (!hasContent) {
      context.pop();
      return;
    }
    BiaryDialog.show(
      context,
      title: '작성 중인 내용이 있어요',
      content: '지금 나가면 입력한 내용이 사라져요.\n그래도 나가시겠어요?',
      confirmLabel: '나가기',
      cancelLabel: '계속 작성',
      onConfirm: () => context.pop()
    );
  }

  // 신규 저장 후 분석 시작 확인 다이얼로그
  Future<void> _showAnalysisDialog(MealRecord saved, ChildProfile child) async {
    await BiaryDialog.show(
      context,
      title: '식단 기록이 저장되었어요',
      content: '지금 바로 영양 분석을 하실래요?',
      confirmLabel: '분석하기',
      cancelLabel: '나중에',
      onConfirm: () => _startAnalysis(saved, child),
      onCancel: () {
        context.pop();
        context.go('/home');
      }
    );
  }

  // 분석 오버레이 실행 -> 캐시 확인 -> Edge Function 호출 -> 화면 이동
  Future<void> _startAnalysis(MealRecord saved, ChildProfile child) async {
    final analysisRepo = ref.read(analysisRepositoryProvider);
    final cached = await analysisRepo.getAnalysis(saved.id!);

    if (!mounted) return;
    if (!AnalysisFlowHelper.needsNewAnalysis(cached, saved.updatedAt)) {
      // 캐시 HIT -> 바로 이동
      _navigateToResult(cached!, child);
      return;
    }

    // 캐시 MISS -> 오버레이 + Edge function
    final entries = _foodEntries
      .where((e) => e.selectedFood != null)
      .map((e) => FoodIntakeEntry(
        food: e.selectedFood!,
        intakeAmountG: double.tryParse(e.amountCtrl.text.trim()) ?? 100
      ))
      .toList();

    final isSubscriber = false; // TODO: 구독 여부 provider 연결

    final response = await AnalysisLoadingOverlay.show<AnalysisResponse>(
      context, ref,
      childName: child.name,
      taskBuilder: (onProgress) => AnalysisService.analyze(
        isSubscriber: isSubscriber,
        entries: entries,
        childId: child.id,
        childAgeMonths: AgeCalculator.toMonths(child.birthDate),
        childGender: child.gender,
        onProgress: onProgress
      )
    );

    if (response == null || !mounted) return;

    // 분석 결과 저장
    final analysisResult = await AnalysisFlowHelper.buildAndSave(
      response: response,
      mealRecordId: saved.id!,
      childId: child.id,
      targetDate: saved.mealDate,
      mealType: saved.mealType,
      repo: analysisRepo
    );

    if (mounted) _navigateToResult(analysisResult, child);
  }

  void _navigateToResult(AnalysisResult result, ChildProfile child) {
    final isGuest = supabase.auth.currentUser == null;
    context.go('/analysis/result', extra: {
      'result': result,
      'childName': child.name,
      'isGuest': isGuest,
      'isModified': false // 신규 저장 시 항상 false
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedChild = ref.watch(selectedChildProvider);

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: AppColors.warmCream,
        appBar: AppBar(
          backgroundColor: AppColors.warmCream,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.x, color: AppColors.darkGray),
            onPressed: _onClose
          ),
          title: Text(
            _isEditMode ? '식단 기록 수정': '식단 기록 작성',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.darkGray
            )
          ),
          centerTitle: true
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('아이 선택'),
              const SizedBox(height: 8),
              ChildSelector(
                child: selectedChild,
                onTap: () => ChildSwitchSheet.show(context)
              ),
              const SizedBox(height: 20),

              _sectionLabel('날짜'),
              const SizedBox(height: 8),
              MealDatePicker(date: _selectedDate, onTap: _pickDate),
              const SizedBox(height: 20),

              _sectionLabel('식사 구분'),
              const SizedBox(height: 8),
              Row(
                children: List.generate(_mealTypeLabels.length, (i) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i < _mealTypeLabels.length - 1 ? 8 : 0
                      ),
                      child: BiarySelectButton(
                        label: _mealTypeLabels[i],
                        selected: _selectedMealType == _mealTypeValues[i],
                        onTap: () => setState(() => _selectedMealType = _mealTypeValues[i]),
                        verticalPadding: 10,
                        borderRadius: 8
                      )
                    )
                  );
                })
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionLabel('음식 목록'),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _foodEntries.add(FoodEntry());
                      _foodListError = null;
                    }),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('음식 추가'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryBrown,
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero
                    )
                  )
                ]
              ),
              if (_foodListError != null) ...[
                const SizedBox(height: 4),
                Text(
                  _foodListError!,
                  style: const TextStyle(
                    color: AppColors.error, fontSize: 12
                  )
                )
              ],
              const SizedBox(height: 8),
              ...List.generate(_foodEntries.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FoodItemCard(
                    foodEntry: _foodEntries[i],
                    canDelete: _foodEntries.length > 1,
                    onRemove: () => setState(() {
                      _foodEntries[i].dispose();
                      _foodEntries.removeAt(i);
                    }),
                    onFoodChanged: () => setState(() => _foodListError = null),
                    onReactionChanged: (r) =>
                      setState(() => _foodEntries[i].reactionType = r)
                  )
                );
              }),
              const SizedBox(height: 20),

              _sectionLabel('사진 첨부 (최대 3장)'),
              const SizedBox(height: 8),
              _buildPhotoSection(),
              const SizedBox(height: 20),

              _sectionLabel('메모 (선택)'),
              const SizedBox(height: 8),
              BiaryTextField(
                controller: _memoCtrl,
                hint: '특이사항, 아이 반응 등을 기록해보세요',
                maxLines: 3
              ),
              const SizedBox(height: 32),

              BiaryButton(
                label: _isEditMode ? '수정' : '저장',
                onPressed: _save
              )
            ]
          )
        )
      )
    );
  }

  // 사진 섹션
  Widget _buildPhotoSection() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // 기존 사진 (수정 모드)
        ..._existingPhotos
          .where((p) => !_deletedPhotoIds.contains(p.id))
          .map((p) => PhotoThumbnail.network(
            url: p.photoUrl,
            onRemove: () => setState(() => _deletedPhotoIds.add(p.id))
          )
        ),
        // 새로 추가한 로컬 사진
        ..._localPhotoPaths.asMap().entries.map((e) =>
          PhotoThumbnail.local(
            path: e.value,
            onRemove: () => setState(() => _localPhotoPaths.removeAt(e.key))
          )
        ),
        // 추가 버튼
        if (_totalPhotoCount < 3)
          GestureDetector(
            onTap: _pickPhoto,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.inputBorder),
                borderRadius: BorderRadius.circular(10),
                color: Colors.white
              ),
              child: const Center(
                child: Icon(LucideIcons.plus, color: AppColors.grayCaption)
              )
            )
          )
      ]
    );
  }

  Widget _sectionLabel(String label) => Text(
    label,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.darkGray
    )
  );
}