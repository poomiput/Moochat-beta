import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flip_card/controllers/flip_card_controllers.dart';
import 'package:flutter_flip_card/flipcard/gesture_flip_card.dart';
import 'package:flutter_flip_card/modal/flip_side.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/theming/styles.dart';
import 'package:moochat/core/widgets/loading_animation.dart';
import 'package:moochat/features/home/data/models/user_data_model.dart';
import 'package:moochat/features/invite/ui/widgets/qr_space.dart';
import 'package:moochat/features/invite/ui/widgets/user_data_widget.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

class ShowAllData extends StatelessWidget {
  ShowAllData({super.key, required this.data});
  final UserData data;
  final GestureFlipCardController controller = GestureFlipCardController();
  final ScreenshotController screenshotController = ScreenshotController();

  Future<void> _downloadQRCode(BuildContext context) async {
    try {
      // Request storage permission
      var status = await Permission.photos.status;
      if (!status.isGranted) {
        status = await Permission.photos.request();
        if (!status.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr("qr_code_save_permission_error")),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(child: CustomLoadingAnimation(size: 30.sp));
        },
      );

      // Capture screenshot
      Uint8List? image = await screenshotController.capture();

      if (image != null) {
        // Save to gallery using Gal
        await Gal.putImageBytes(
          image,
          name:
              "QR_Code_${data.username}_${DateTime.now().millisecondsSinceEpoch}",
        );

        // Close loading dialog
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr("qr_code_saved")),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      } else {
        // Close loading dialog
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr("qr_code_save_error")),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if it's open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header text
              Text(
                context.tr("share_your_qr_code"),
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: ColorsManager.whiteColor,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                context.tr("let_others_scan"),
                style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30.h),
              // show user can flip the card with icon 360 degrees
              Icon(Icons.flip, color: ColorsManager.whiteColor, size: 30.sp),
              SizedBox(height: 20.h),

              // QR Code Section wrapped with Screenshot widget
              Screenshot(
                controller: screenshotController,
                child: GestureFlipCard(
                  animationDuration: const Duration(milliseconds: 800),
                  axis: FlipAxis.vertical,
                  controller: controller,
                  enableController: true,
                  frontWidget: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: QrSpace(userName: data.username, uuid: data.uuid),
                  ),
                  backWidget: Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: ColorsManager.backgroundColor,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: UserDataRef(
                      userName: data.username,
                      uuid: data.uuid,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 20.h),
              // Download button with screenshot functionality
              ElevatedButton(
                onPressed: () => _downloadQRCode(context),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  backgroundColor: ColorsManager.customGray,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      "assets/icons/import.png",
                      width: 24.w,
                      height: 24.h,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      context.tr("download_qr_code"),
                      style: CustomTextStyles.font16GrayRegular,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // Additional info or instructions
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red, size: 20.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        context.tr("warning"),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
