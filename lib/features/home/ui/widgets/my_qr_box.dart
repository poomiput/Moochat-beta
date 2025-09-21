import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/helpers/extensions.dart';
import 'package:moochat/core/routing/routes.dart';
import 'package:moochat/core/theming/colors.dart';

class MyQrBox extends StatelessWidget {
  const MyQrBox({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),

      onTap: () {
        context.pushNamed(RoutesManager.myQrScreen);
      },
      child: Container(
        width: 100.w,
        height: 45.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4), // changes position of shadow
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: null,
              icon: Icon(
                Icons.qr_code_scanner,
                color: ColorsManager.backgroundColor,
                size: 35.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
