import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/theming/styles.dart';

class NoMessageYet extends StatelessWidget {
  const NoMessageYet({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64.sp, color: Colors.grey),
          SizedBox(height: 16.h),
          Text(
            textAlign: TextAlign.center,
            context.tr('no_messages'),
            style: CustomTextStyles.font16GrayRegular.copyWith(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
          textAlign: TextAlign.center,
            context.tr("no_message_desciption"),
            style: CustomTextStyles.font16GrayRegular,
          ),
        ],
      ),
    );
  }
}
