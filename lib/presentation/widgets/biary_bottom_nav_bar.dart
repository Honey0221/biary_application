import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:honey/core/constants/app_colors.dart';

// 하단 탭바 위젯
class BiaryBottomNavBar extends StatelessWidget {
  const BiaryBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddTap
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onAddTap; // 중앙 FAB 전용 콜백

  static const _tabs = [
    _NavTab(icon: LucideIcons.house, label: '홈'),
    _NavTab(icon: LucideIcons.clipboardList, label: '기록'),
    _NavTab(icon: null, label: ''), // 중앙 FAB 자리
    _NavTab(icon: LucideIcons.users, label: '커뮤니티'),
    _NavTab(icon: LucideIcons.user, label: '마이')
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider))
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(_tabs.length, (index) {
              if (index == 2) return _buildFab();
              return _buildTabItem(index);
            })
          )
        )
      )
    );
  }

  Widget _buildTabItem(int index) {
    final isSelected = index == currentIndex;
    final tab = _tabs[index];

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tab.icon,
              size: 22,
              color: isSelected ? AppColors.primaryBrown : AppColors.grayCaption
            ),
            const SizedBox(height: 3),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? AppColors.primaryBrown : AppColors.grayCaption,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400
              )
            )
          ]
        )
      )
    );
  }

  Widget _buildFab() {
    return Expanded(
      child: GestureDetector(
        onTap: onAddTap,
        child: Center(
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryBrown,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 8,
                  offset: Offset(0, 3)
                )
              ]
            ),
            child: const Icon(LucideIcons.plus, color: Colors.white, size: 22),
          )
        )
      )
    );
  }
}

class _NavTab {
  const _NavTab({
    required this.icon,
    required this.label
  });

  final IconData? icon;
  final String label;
}