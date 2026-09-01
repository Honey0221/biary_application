import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:honey/core/constants/app_colors.dart';
import 'package:honey/presentation/widgets/biary_dialog.dart';
import 'package:honey/presentation/widgets/empty_state_view.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  int _selectedIndex = 0;


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSignupNudge());
  }

  // 최초 기록 완료 여부 확인 함수
  Future<void> _checkSignupNudge() async {
    final flagBox = await Hive.openBox<bool>('guestFlags');
    final hasRecord = flagBox.get('hasCompletedFirstRecord', defaultValue: false)!;
    final hasShown = flagBox.get('hasShownSignupNudge', defaultValue: false)!;

    if (hasRecord && !hasShown) {
      await flagBox.put('hasShownSignupNudge', true);
      if (!mounted) return;
      await BiaryDialog.show(
        context,
        title: '첫 기록을 완료했어요!',
        content: '회원가입하면 기록이 영구 저장되고\n더 정확한 분석을 받을 수 있어요',
        confirmLabel: '가입하기',
        cancelLabel: '나중에',
        onConfirm: () => context.go('/signup'),
        onCancel: () {}
      );
    }
  }

  // 제한 기능 안내 다이얼로그
  Future<void> _showRestrictedDialog() async {
    await BiaryDialog.show(
      context,
      title: '로그인이 필요한 기능입니다',
      content: '회원가입 후 이용할 수 있습니다',
      confirmLabel: '확인',
      onConfirm: () {}
    );
  }

  // 탭 인덱스별 이벤트 함수
  void _onTabTapped(int index) {
    if (index == 2) context.go('/guest-entry'); // FAB -> 게스트 기록 화면 이동
    if (index == 1 || index == 4) { // 기록, 마이페이지 -> 제한 다이얼로그
      _showRestrictedDialog();
      return;
    }
    if (index == 3) {
      // TODO: 커뮤니티 화면 이동 구현 예정
      // context.push('/community');
      return;
    }

    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: AppColors.warmCream,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Biary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.darkGray
          )
        ),
        actions: [
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text(
              '로그인',
              style: TextStyle(
                color: AppColors.primaryBrown,
                fontWeight: FontWeight.w600,
                fontSize: 14
              )
            )
          ),
          const SizedBox(width: 8)
        ]
      ),
      body: const EmptyStateView(
        icon: Icons.restaurant_outlined,
        actionLabel: '아직 기록이 없어요',
        message: '첫 식단을 기록해보세요!'
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/guest-entry'),
        backgroundColor: AppColors.primaryBrown,
        elevation: 2,
        child: const Icon(LucideIcons.plus, color: Colors.white)
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomAppBar(
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: LucideIcons.house,
                  label: '홈',
                  selected: _selectedIndex == 0,
                  onTap: () => _onTabTapped(0)
                ),
                _NavItem(
                  icon: LucideIcons.clipboardList,
                  label: '기록',
                  selected: _selectedIndex == 1,
                  onTap: () => _onTabTapped(1)
                ),
                const SizedBox(width: 56),
                _NavItem(
                  icon: LucideIcons.users,
                  label: '커뮤니티',
                  selected: _selectedIndex == 3,
                  onTap: () => _onTabTapped(3)
                ),
                _NavItem(
                  icon: LucideIcons.user,
                  label: 'MY',
                  selected: _selectedIndex == 4,
                  onTap: () => _onTabTapped(4)
                )
              ]
            )
          )
          // TODO Phase 11: 광고 배너 구현 예정(미구독 전용)
        ]
      )
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryBrown : AppColors.grayCaption;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal
              )
            )
          ]
        )
      )
    );
  }
}