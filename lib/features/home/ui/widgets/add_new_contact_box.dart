import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/helpers/extensions.dart';
import 'package:moochat/core/routing/routes.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/theming/styles.dart';

class AddNewContactBox extends StatelessWidget {
  const AddNewContactBox({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),

      onTap: () async {
        context.pushNamed(RoutesManager.qrScannerScreen);
      },
      child: Container(
        width: double.infinity,
        height: 50.h,
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Image.asset(
              "assets/icons/camera.png",
              width: 24.w,
              height: 24.h,
              color: ColorsManager.backgroundColor,
            ),
            Text(
              context.tr("add_new_contact"),
              style: CustomTextStyles.font20WhiteBold.copyWith(
                color: ColorsManager.backgroundColor,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

