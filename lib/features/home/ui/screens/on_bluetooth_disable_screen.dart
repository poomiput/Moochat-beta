import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/helpers/extensions.dart';
import 'package:moochat/core/routing/routes.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/theming/styles.dart';
import 'package:moochat/features/home/services/nearby_premission.dart';
import 'package:moochat/features/home/services/notifications_service.dart';
import 'package:lottie/lottie.dart';

class OnBluetoothDisableScreen extends StatefulWidget {
  const OnBluetoothDisableScreen({super.key});

  @override
  State<OnBluetoothDisableScreen> createState() =>
      _OnBluetoothDisableScreenState();
}

class _OnBluetoothDisableScreenState extends State<OnBluetoothDisableScreen> {
  bool _isEnabling = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.backgroundColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              ColorsManager.mainColor.withOpacity(0.1),
              ColorsManager.backgroundColor,
              ColorsManager.backgroundColor,
            ],
            stops: const [0.0, 0.4, 1.0],
          ),
        ),
        child: Column(
          children: [
            // add button to remove this screen
            SizedBox(height: 40.h), // Space at the top
            // Close Button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: ColorsManager.whiteColor,
                  size: 28.w,
                ),
                onPressed: () {
                  context.pushReplacementNamed(RoutesManager.homeScreen);
                },
              ),
            ),
            // Top section with lottie only
            Expanded(
              flex: 3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Lottie Animation
                  LottieBuilder.asset(
                    "assets/lottie/bluetooth_listen.json",
                    width: 300.w,
                    height: 300.h,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),

            // Bottom section with content
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Main Title
                    Text(
                      context.tr('on_bluetooth_disabled'),
                      style: CustomTextStyles.font32WhiteBold.copyWith(
                        fontSize: 28.sp,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 16.h),

                    // Description
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        context.tr('bluetooth_disabled_description'),
                        style: CustomTextStyles.font16GrayRegular.copyWith(
                          fontSize: 16.sp,
                          height: 1.5,
                          color: ColorsManager.grayColor.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Enable Button
                    Container(
                      width: double.infinity,
                      height: 56.h,
                      margin: EdgeInsets.symmetric(horizontal: 20.w),
                      child: ElevatedButton(
                        onPressed: _isEnabling ? null : _handleEnableBluetooth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: _isEnabling
                                ? LinearGradient(
                                    colors: [
                                      ColorsManager.grayColor.withOpacity(0.5),
                                      ColorsManager.grayColor.withOpacity(0.3),
                                    ],
                                  )
                                : LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      ColorsManager.customGreen,
                                      ColorsManager.customGreen.withOpacity(
                                        0.8,
                                      ),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: _isEnabling
                                ? []
                                : [
                                    BoxShadow(
                                      color: ColorsManager.mainColor
                                          .withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: _isEnabling
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20.w,
                                        height: 20.w,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                ColorsManager.whiteColor,
                                              ),
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Text(
                                        context.tr('enabling'),
                                        style: CustomTextStyles
                                            .font16WhiteRegular
                                            .copyWith(
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.bluetooth_rounded,
                                        color: ColorsManager.whiteColor,
                                        size: 24.w,
                                      ),
                                      SizedBox(width: 12.w),
                                      Text(
                                        context.tr('enable_bluetooth'),
                                        style: CustomTextStyles
                                            .font16WhiteRegular
                                            .copyWith(
                                              fontSize: 18.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleEnableBluetooth() async {
    setState(() {
      _isEnabling = true;
    });

    try {
      await CorePermissionHandler.requestPermissions();
      await NotificationService().requestPermissions();
      await CorePermissionHandler.onBluetoothEnabled();
    } catch (e) {
      // Handle error
      _showErrorSnackbar(context.tr('bluetooth_enable_error'));
    } finally {
      if (mounted) {
        setState(() {
          _isEnabling = false;
        });
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: CustomTextStyles.font14GrayRegular.copyWith(
            color: ColorsManager.whiteColor,
          ),
        ),
        backgroundColor: ColorsManager.customRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.w),
      ),
    );
  }
}
