import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:honey/core/constants/app_colors.dart';
import 'package:honey/core/utils/date_formatter.dart';
import 'package:honey/data/models/food_search_result.dart';
import 'package:honey/data/models/meal_item.dart';
import 'package:honey/data/models/meal_record.dart';
import 'package:honey/data/models/meal_record_photo.dart';
import 'package:honey/presentation/screens/child/child_switch_sheet.dart';
import 'package:honey/presentation/widgets/biary_button.dart';
import 'package:honey/presentation/widgets/biary_dialog.dart';
import 'package:honey/presentation/widgets/biary_select_button.dart';
import 'package:honey/presentation/widgets/biary_text_field.dart';
import 'package:honey/presentation/widgets/food_search_field.dart';
import 'package:honey/presentation/widgets/loading_overlay.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../providers/child_profile_provider.dart';
import '../../../providers/meal_record_provider.dart';

// 음식 항목 로컬 상태 클래스
class _FoodEntry {
  FoodSearchResult? selectedFood;
  final TextEditingController nameCtrl;
  final TextEditingController amountCtrl;
  String? reactionType; // 'good' | 'normal' | 'bad' | null

  _FoodEntry({String name = '', String amount = '', this.reactionType})
    : nameCtrl = TextEditingController(text: name),
      amountCtrl = TextEditingController(text: amount);

  void dispose() {
    nameCtrl.dispose();
    amountCtrl.dispose();
  }
}

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
  late List<_FoodEntry> _foodEntries;

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
    if (_isEditMode) {
      final r = widget.initialRecord!;
      _selectedDate = r.mealDate;
      _selectedMealType = r.mealType;
      _memoCtrl.text = r.memo ?? '';
      _existingPhotos = List.of(r.photos);
      _foodEntries = r.items.map((item) =>
          _FoodEntry(
              name: item.customFoodName,
              amount: item.intakeAmountG?.toStringAsFixed(0) ?? '',
              reactionType: item.reactionType
          )).toList();
      if (_foodEntries.isEmpty) _foodEntries.add(_FoodEntry());
    } else {
      _selectedDate = DateTime.now();
      _selectedMealType = 'breakfast';
      _existingPhotos = [];
      _foodEntries = [_FoodEntry()];
    }
  }

  @override
  void dispose() {
    for (final e in _foodEntries) {
      e.dispose();
    }
    _memoCtrl.dispose();
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
        // 삭제 요청된 기존 사진 처리
        for (final id in _deletedPhotoIds) {
          await repo.deletePhoto(id);
        }
        await repo.updateRecord(
          record: record,
          localPhotosPaths: _localPhotoPaths
        );
      } else {
        await repo.createRecord(
          record: record,
          localPhotoPaths: _localPhotoPaths
        );
      }
      if (mounted) context.pop();
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
              _ChildSelector(
                child: selectedChild,
                onTap: () => ChildSwitchSheet.show(context)
              ),
              const SizedBox(height: 20),

              _sectionLabel('날짜'),
              const SizedBox(height: 8),
              _DatePicker(date: _selectedDate, onTap: _pickDate),
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
                      _foodEntries.add(_FoodEntry());
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
                  child: _FoodItemCard(
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
          .map((p) => _PhotoThumbnail.network(
            url: p.photoUrl,
            onRemove: () => setState(() => _deletedPhotoIds.add(p.id))
          )
        ),
        // 새로 추가한 로컬 사진
        ..._localPhotoPaths.asMap().entries.map((e) =>
          _PhotoThumbnail.local(
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

// 아이 선택 위젯
class _ChildSelector extends StatelessWidget {
  final dynamic child;
  final VoidCallback onTap;

  const _ChildSelector({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasChild = child != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: hasChild ? AppColors.primaryBrown : AppColors.inputBorder
          ),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white
        ),
        child: Row(
          children: [
            Icon(
              LucideIcons.baby,
              size: 18,
              color: hasChild ? AppColors.primaryBrown : AppColors.grayCaption
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                hasChild ? child.name : '아이를 선택해주세요',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: hasChild ? FontWeight.w600 : FontWeight.normal,
                  color: hasChild ? AppColors.darkGray : AppColors.grayCaption
                )
              )
            ),
            const Icon(
              LucideIcons.chevronDown,
              size: 16,
              color: AppColors.grayCaption
            )
          ]
        )
      )
    );
  }
}

// 날짜 선택 위젯
class _DatePicker extends StatelessWidget {
  final DateTime date;
  final VoidCallback onTap;

  const _DatePicker({required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormatter.toDateLabel(date);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.inputBorder),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.calendar, size: 18, color: AppColors.grayCaption),
            const SizedBox(width: 8),
            Text(formatted,
              style: const TextStyle(fontSize: 15, color: AppColors.darkGray)
            )
          ]
        )
      )
    );
  }
}

// 음식 항목 카드
class _FoodItemCard extends ConsumerWidget {
  final _FoodEntry foodEntry;
  final bool canDelete;
  final VoidCallback onRemove;
  final VoidCallback onFoodChanged;
  final ValueChanged<String?> onReactionChanged;

  const _FoodItemCard({
    required this.foodEntry,
    required this.canDelete,
    required this.onRemove,
    required this.onFoodChanged,
    required this.onReactionChanged
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: FoodSearchField(
                  controller: foodEntry.nameCtrl,
                  selectedFood: foodEntry.selectedFood,
                  hintText: '음식명 검색 또는 직접 입력',
                  onSelected: (result) {
                    foodEntry.nameCtrl.text = result.foodName;
                    foodEntry.selectedFood = result;
                    onFoodChanged();
                  },
                  onChanged: onFoodChanged,
                )
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: foodEntry.amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: '섭취량(g)',
                    hintStyle: TextStyle(color: AppColors.grayCaption),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true
                  ),
                  style: const TextStyle(fontSize: 15)
                )
              ),
              if (canDelete) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      LucideIcons.trash2,
                      size: 18,
                      color: AppColors.grayCaption
                    )
                  )
                )
              ]
            ]
          ),
          const Divider(height: 16, color: AppColors.divider),
          Row(
            children: [
              const Text('반응', style: TextStyle(
                fontSize: 12, color: AppColors.grayCaption
              )),
              const SizedBox(width: 12),
              ..._buildReactionChips()
            ]
          )
        ]
      )
    );
  }

  List<Widget> _buildReactionChips() {
    const types = ['good', 'normal', 'bad'];
    const labels = {'good': '좋아요', 'normal': '보통', 'bad': '거부'};
    const icons = {
      'good': LucideIcons.smile,
      'normal': LucideIcons.meh,
      'bad': LucideIcons.frown
    };

    return types.map((type) {
      final selected = foodEntry.reactionType == type;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: GestureDetector(
          onTap: () => onReactionChanged(selected ? null : type),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryBrown : Colors.transparent,
              border: Border.all(
                color: selected ? AppColors.primaryBrown : AppColors.inputBorder
              ),
              borderRadius: BorderRadius.circular(20)
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icons[type]!, size: 13,
                  color: selected ? Colors.white : AppColors.grayCaption),
                const SizedBox(width: 4),
                Text(labels[type]!, style: TextStyle(
                  fontSize: 12,
                  color: selected ? Colors.white : AppColors.grayCaption)
                )
              ]
            )
          )
        )
      );
    }).toList();
  }
}

// 사진 썸네일
class _PhotoThumbnail extends StatelessWidget {
  final Widget image;
  final VoidCallback onRemove;

  const _PhotoThumbnail._({
    required this.image, required this.onRemove
  });

  factory _PhotoThumbnail.local({
    required String path,
    required VoidCallback onRemove
  }) => _PhotoThumbnail._(
    image: Image.file(File(path),
        width: 80, height: 80, fit: BoxFit.cover
    ), onRemove: onRemove
  );

  factory _PhotoThumbnail.network({
    required String url,
    required VoidCallback onRemove
  }) => _PhotoThumbnail._(
    image: Image.network(url,
      width: 80, height: 80, fit: BoxFit.cover
    ), onRemove: onRemove
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: image
        ),
        Positioned(
          top: 2, right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20, height: 20,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle
              ),
              child: const Icon(LucideIcons.x, size: 12, color: Colors.white)
            )
          )
        )
      ]
    );
  }
}