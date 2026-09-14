import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:honey/core/constants/app_colors.dart';
import 'package:honey/presentation/widgets/biary_bottom_nav_bar.dart';
import 'package:honey/presentation/widgets/biary_dialog.dart';
import 'package:honey/presentation/widgets/empty_state_view.dart';
import 'package:honey/providers/ui_provider.dart';

class GuestHomeScreen extends ConsumerStatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  ConsumerState<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends ConsumerState<GuestHomeScreen> {
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
    if (index == 1 || index == 4) { // 기록, 마이페이지 -> 제한 다이얼로그
      _showRestrictedDialog();
      return;
    }
    if (index == 3) {
      // context.push('/community');
      return;
    }

    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isTabBarVisible = ref.watch(tabBarVisibleProvider);

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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: isTabBarVisible ? 60 + MediaQuery.of(context).padding.bottom : 0,
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(),
        child: BiaryBottomNavBar(
          currentIndex: _selectedIndex,
          onTap: _onTabTapped,
          onAddTap: () => context.go('/guest-entry')
        )
      ),
      // TODO Phase 11: 광고 배너 구현 예정(미구독 전용)
    );
  }
}