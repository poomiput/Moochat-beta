import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/theming/colors.dart';

/// Sticky section header for grouping chats by time
class StickySectionHeader extends SliverPersistentHeaderDelegate {
  final String title;

  const StickySectionHeader({required this.title});

  @override
  double get minExtent => 44.h;

  @override
  double get maxExtent => 44.h;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: 44.h,
      decoration: BoxDecoration(
        color: ColorsManager.backgroundColor.withOpacity(0.9),
        border: Border(
          bottom: BorderSide(
            color: ColorsManager.strokeColor.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  color: ColorsManager.subtitleText,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant StickySectionHeader oldDelegate) {
    return title != oldDelegate.title;
  }
}
