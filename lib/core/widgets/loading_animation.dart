import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:moochat/core/theming/colors.dart';

class CustomLoadingAnimation extends StatelessWidget {
  const CustomLoadingAnimation({super.key, required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SpinKitDancingSquare(color: ColorsManager.whiteColor, size: size);
  }
}
