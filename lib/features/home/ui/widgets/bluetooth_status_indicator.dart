import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/shared/providers/bluetooth_state_provider.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/theming/styles.dart';

class BluetoothStatusIndicator extends StatelessWidget {
  const BluetoothStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final bool isBluetoothOn = ref.watch(isBluetoothOnProvider);

        // You can also listen for side effects here if needed
        ref.listen(isBluetoothOnProvider, (previous, next) {
          // Example: Show a snackbar when bluetooth status changes
          if (previous != null && previous != next) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  next
                      ? context.tr("bluetooth_connected")
                      : context.tr("bluetooth_disconnected"),
                ),
                backgroundColor: next
                    ? Colors.green
                    : ColorsManager.customOrange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        });

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isBluetoothOn
                ? Colors.green.withOpacity(0.2)
                : ColorsManager.customOrange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isBluetoothOn ? Colors.green : ColorsManager.customOrange,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6.w,
                height: 6.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isBluetoothOn
                      ? Colors.green
                      : ColorsManager.customOrange,
                ),
              ),
              SizedBox(width: 4.w),
              Text(
                isBluetoothOn ? context.tr("online") : context.tr("offline"),
                style: CustomTextStyles.font12WhiteRegular.copyWith(
                  color: isBluetoothOn
                      ? Colors.green
                      : ColorsManager.customOrange,
                  fontWeight: FontWeight.w500,
                  fontSize: 10.sp,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
