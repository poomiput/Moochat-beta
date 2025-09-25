import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/theming/colors.dart';

/// Modern navigation system with responsive bottom bar / navigation rail
class ModernNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onIndexChanged;
  final List<NavigationItem> items;
  final bool isTablet;

  const ModernNavigation({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.items,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isTablet) {
      return _buildNavigationRail();
    } else {
      return _buildBottomNavigationBar();
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: ColorsManager.surfaceColor,
        border: Border(
          top: BorderSide(color: ColorsManager.strokeColor, width: 0.5),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onIndexChanged,
        type: BottomNavigationBarType.fixed,
        backgroundColor: ColorsManager.surfaceColor,
        selectedItemColor: ColorsManager.titleText,
        unselectedItemColor: ColorsManager.captionText,
        selectedFontSize: 12.sp,
        unselectedFontSize: 11.sp,
        elevation: 0,
        items: items
            .map(
              (item) => BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Icon(item.icon, size: 22.sp),
                ),
                activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: ColorsManager.interactiveNormal,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(item.icon, size: 22.sp),
                  ),
                ),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildNavigationRail() {
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onIndexChanged,
      backgroundColor: ColorsManager.surfaceColor,
      selectedIconTheme: IconThemeData(
        color: ColorsManager.titleText,
        size: 24.sp,
      ),
      unselectedIconTheme: IconThemeData(
        color: ColorsManager.captionText,
        size: 22.sp,
      ),
      selectedLabelTextStyle: TextStyle(
        color: ColorsManager.titleText,
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: ColorsManager.captionText,
        fontSize: 11.sp,
      ),
      destinations: items
          .map(
            (item) => NavigationRailDestination(
              icon: Icon(item.icon),
              selectedIcon: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: ColorsManager.interactiveNormal,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(item.icon),
              ),
              label: Text(item.label),
            ),
          )
          .toList(),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;

  const NavigationItem({required this.icon, required this.label});
}
