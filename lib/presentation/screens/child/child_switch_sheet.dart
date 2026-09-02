import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:honey/core/constants/app_colors.dart';
import 'package:honey/core/utils/age_calculator.dart';
import 'package:honey/data/models/child_profile.dart';
import 'package:honey/providers/child_profile_provider.dart';

class ChildSwitchSheet extends ConsumerWidget {
  const ChildSwitchSheet({super.key});

  // 시트를 표시하고 선택된 아이를 selectedChildProvider에 반영
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (_) => const ChildSwitchSheet()
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(childProfilesProvider);
    final selected = ref.watch(selectedChildProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.inputBorder,
                borderRadius: BorderRadius.circular(2)
              )
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '아이 선택',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkGray
                  )
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.grayCaption),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints()
                )
              ]
            ),
            const SizedBox(height: 8),
            profilesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator()
              ),
              error: (_, _) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('불러오기 실패', style: TextStyle(color: AppColors.error))
              ),
              data: (profiles) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...profiles.map((profile) => _ProfileTile(
                    profile: profile,
                    isSelected: selected?.id == profile.id,
                    onTap: () {
                      ref.read(selectedChildProvider.notifier).state = profile;
                      Navigator.of(context).pop();
                    }
                  )),
                  const SizedBox(height: 4),
                  ListTile(
                    leading: Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(22)
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.primaryBrown,
                        size: 20
                      )
                    ),
                    title: const Text(
                      '아이 추가',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.primaryBrown,
                        fontWeight: FontWeight.w500
                      )
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      context.push('/child/new');
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4)
                  )
                ]
              )
            ),
            const SizedBox(height: 8)
          ]
        )
      )
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.isSelected,
    required this.onTap
  });

  final ChildProfile profile;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.surfaceMuted,
        backgroundImage: profile.avatarUrl != null ?
          NetworkImage(profile.avatarUrl!) : null,
        child: profile.avatarUrl != null ? const Icon(
          Icons.child_care,
          color: AppColors.primaryLight,
          size: 22
        ) : null
      ),
      title: Text(
        profile.name,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.darkGray
        )
      ),
      subtitle: Text(
        AgeCalculator.toLabel(profile.birthDate),
        style: const TextStyle(fontSize: 13, color: AppColors.grayCaption),
      ),
      trailing: isSelected ? const Icon(
        Icons.check_circle,
        color: AppColors.primaryBrown,
        size: 22
      ) : null
    );
  }
}