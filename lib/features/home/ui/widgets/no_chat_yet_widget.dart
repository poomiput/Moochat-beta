import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:lottie/lottie.dart';

class NoChatYet extends StatelessWidget {
  const NoChatYet({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(height: 50.h),
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              ColorsManager.whiteColor,
              BlendMode.srcATop,
            ),
            child: Lottie.asset(
              'assets/lottie/palestine_map.json',
              width: 200.w,
              height: 200.h,
              fit: BoxFit.cover,
              backgroundLoading: true,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            context.tr("no_chat"),
            style: TextStyle(
              fontSize: 18.sp,
              color: Colors.white, // Changed to white for dark background
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
          context.tr("no_chat_description"),
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white70, // Slightly transparent white
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
