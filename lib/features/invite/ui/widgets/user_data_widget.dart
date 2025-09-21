import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/theming/styles.dart';

class UserDataRef extends StatelessWidget {
  const UserDataRef({super.key, required this.userName, required this.uuid});
  final String userName;
  final String uuid;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Text(
            userName,
            style: CustomTextStyles.font20WhiteBold,
            textAlign: TextAlign.center,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Text(
            uuid,
            style: CustomTextStyles.font20WhiteBold,
            textAlign: TextAlign.center,
          ),
        ),
        // add button to copy uuid
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: ElevatedButton(
            onPressed: () {
              // Logic to copy UUID to clipboard
              Clipboard.setData(ClipboardData(text: uuid));
            },
            child: Icon(
              Icons.copy,
              size: 24.sp,
            ),
          ),
        ),
             ],
    );
  }
}
