import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/theming/styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moochat/features/home/ui/widgets/bluetooth_status_indicator.dart';
import 'package:moochat/features/home/ui/widgets/connections_section_widget.dart';

class Header extends ConsumerStatefulWidget {
  const Header({super.key, required this.userName, this.connectionCount = 0});

  final String userName;
  final int connectionCount;

  @override
  ConsumerState<Header> createState() => _HeaderState();
}

class _HeaderState extends ConsumerState<Header> {
  @override
  Widget build(BuildContext context) {
    // Remove the isBluetoothOn watch from here since it's now in the Consumer
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorsManager.backgroundColor,
            ColorsManager.customGray.withOpacity(0.3),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.mainColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Welcome Section with Avatar
          Row(
            children: [
              // User Avatar
              Container(
                width: 45.w,
                height: 45.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      ColorsManager.mainColor,
                      ColorsManager.mainColor.withOpacity(0.7),
                    ],
                  ),
                  border: Border.all(
                    color: ColorsManager.whiteColor.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.userName.isNotEmpty
                        ? widget.userName[0].toUpperCase()
                        : 'U',
                    style: CustomTextStyles.font20WhiteBold.copyWith(
                      fontSize: 18.sp,
                    ),
                  ),
                ),
              ),

              SizedBox(width: 16.w),

              // Welcome Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr("welcome").replaceAll('@', '').trim(),
                      style: CustomTextStyles.font14GrayRegular.copyWith(
                        color: ColorsManager.grayColor,
                        fontSize: 12.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      widget.userName,
                      style: CustomTextStyles.font20WhiteBold.copyWith(
                        fontSize: 18.sp,
                      ),
                    ),
                  ],
                ),
              ),

              // Replace the bluetooth status section with the Consumer widget
              const BluetoothStatusIndicator(),
            ],
          ),

          SizedBox(height: 16.h),

          // Connections Section - this also uses bluetooth status
          ConnectionsSectionWidget(),
        ],
      ),
    );
  }
}
