import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/theming/styles.dart';

class FeatureUnavailableDialog extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onClose;

  const FeatureUnavailableDialog({
    super.key,
    required this.title,
    required this.description,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxWidth: 350.w, minHeight: 280.h),
        decoration: BoxDecoration(
          color: ColorsManager.backgroundColor,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: ColorsManager.mainColor.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: ColorsManager.mainColor.withOpacity(0.2),
              blurRadius: 20.r,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15.r,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon container
              Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorsManager.mainColor.withOpacity(0.1),
                  border: Border.all(
                    color: ColorsManager.mainColor.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.construction_rounded,
                  size: 40.sp,
                  color: ColorsManager.mainColor,
                ),
              ),

              SizedBox(height: 20.h),

              // Title
              Text(
                title,
                style: CustomTextStyles.font20WhiteBoldDynamic,
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 16.h),

              // Description
              Text(
                description,
                style: CustomTextStyles.font14GrayRegularDynamic,
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 24.h),

              // Close button
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (onClose != null) {
                      onClose!();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManager.mainColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    context.tr("i_understand"),
                    style: CustomTextStyles.font16WhiteRegularDynamic.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Static method to show the dialog
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String description,
    VoidCallback? onClose,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (BuildContext context) {
        return FeatureUnavailableDialog(
          title: title,
          description: description,
          onClose: onClose,
        );
      },
    );
  }
}
