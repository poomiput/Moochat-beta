import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/helpers/extensions.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/theming/styles.dart';
import 'package:moochat/core/widgets/loading_animation.dart';
import 'package:moochat/features/home/providrs/user_data_provider.dart';
import 'package:moochat/features/invite/ui/widgets/error_loaded_qr.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moochat/features/invite/ui/widgets/show_all_data.dart';

class MyQrScreen extends ConsumerStatefulWidget {
  const MyQrScreen({super.key});

  @override
  ConsumerState<MyQrScreen> createState() => _MyQrScreenState();
}

class _MyQrScreenState extends ConsumerState<MyQrScreen> {
  @override
  Widget build(BuildContext context) {
    final userDataAsync = ref.watch(userDataProvider);
    return Scaffold(
      backgroundColor: ColorsManager.backgroundColor,
      appBar: AppBar(
        backgroundColor: ColorsManager.backgroundColor,
        title: Text(
          context.tr("my_qrcode"),
          style: CustomTextStyles.font20WhiteBold,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: ColorsManager.whiteColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: userDataAsync.when(
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [CustomLoadingAnimation(size: 48.sp)],
          ),
        ),
        error: (error, stackTrace) => ErrorLoadedQr(error: error),
        data: (userData) => ShowAllData(data: userData),
      ),
    );
  }
}
