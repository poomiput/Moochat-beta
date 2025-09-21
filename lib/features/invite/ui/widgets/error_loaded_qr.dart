import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/features/home/providrs/user_data_provider.dart';

class ErrorLoadedQr extends ConsumerWidget {
  const ErrorLoadedQr({super.key, this.error});
  final Object? error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2, size: 64.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              'Failed to load QR Code',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: ColorsManager.whiteColor,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Unable to generate your QR code',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(userDataProvider.notifier).refresh();
                  },
                  icon: Icon(Icons.refresh),
                  label: Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManager.customGreen,
                  ),
                ),
                SizedBox(width: 10.w),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(); // Go back to previous screen
                  },
                  icon: Icon(Icons.arrow_back),
                  label: Text('Go Back'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
