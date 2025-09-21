import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrSpace extends StatelessWidget {
  const QrSpace({super.key, required this.userName, required this.uuid});
  final String userName;
  final String uuid;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(12.w),
      child: QrImageView(
        embeddedImageEmitsError: true,
        eyeStyle: QrEyeStyle(
          eyeShape: QrEyeShape.circle,
          color: ColorsManager.backgroundColor,
        ),
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: ColorsManager.backgroundColor,
        ),
        backgroundColor: Colors.white,
        // Convert Map to JSON string instead of using toString()
        data: jsonEncode({'username': userName, 'isme': true, 'uuid': uuid}),
        version: QrVersions.auto,
        size: 250.sp,
        errorStateBuilder: (cxt, err) {
          return Container(
            child: Center(
              child: Text(
                'Uh oh! Something went wrong...',
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
        constrainErrorBounds: true,
        semanticsLabel: 'My QR Code',
      ),
    );
  }
}
