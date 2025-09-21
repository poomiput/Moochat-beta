import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/helpers/extensions.dart';
import 'package:moochat/core/routing/routes.dart';
import 'package:moochat/core/theming/styles.dart';
import 'package:moochat/core/widgets/feature_unavailable_dialog.dart';
import 'package:moochat/core/widgets/loading_animation.dart';
import 'package:moochat/features/home/providrs/user_data_provider.dart';
import 'package:moochat/features/home/ui/widgets/change_lang_dialog.dart';
import 'package:moochat/features/home/ui/widgets/change_username_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserSetting extends ConsumerWidget {
  const UserSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current user data to pass as initial username
    final userData = ref.watch(userDataProvider);

    return userData.when(
      data: (userData) => Container(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            // Options
            
            ListTile(
              leading: Image.asset(
                'assets/icons/language-square.png',
                width: 24.w,
                height: 24.h,
              ),
              title: Text(
                context.tr('change_language'),
                style: CustomTextStyles.font16WhiteRegular,
              ),
              onTap: () {
                showLanguageChangeDialog(
                  context: context,
                  currentLanguage: context.locale.toString(),
                  onLanguageChanged: (String lang) {
                    context.setLocale(Locale(lang));
                  },
                );
              },
            ),
            ListTile(
              leading: Image.asset(
                'assets/icons/brush.png',
                width: 24.w,
                height: 24.h,
              ),
              title: Text(
                context.tr('change_username'),
                style: CustomTextStyles.font16WhiteRegular,
              ),
              onTap: () {
                context.pop();
                showDialog(
                  context: context,
                  barrierDismissible: false, // Prevent dismissing while loading
                  builder: (_) {
                    return ChangeUsernameDialog(
                      initialUsername:
                          userData.username, // Pass current username
                    );
                  },
                );
              },
            ),
            ListTile(
              leading: Image.asset(
                'assets/icons/flash.png',
                color: Colors.red,
                width: 24.w,
                height: 24.h,
              ),

              title: Text(
                context.tr("notify_all_areas"),
                style: CustomTextStyles.font16WhiteRegular,
              ),
              onTap: () {
                // Handle notification logic
                FeatureUnavailableDialog.show(
                  context,
                  title: context.tr(
                    "feature_unavailable_notify_all_areas_title",
                  ),
                  description: context.tr(
                    "feature_unavailable_notify_all_areas_description",
                  ),
                );
              },
            ),
          ],
        ),
      ),
      error: (error, stackTrace) =>
          Center(child: Text('Error loading user data: $error')),
      loading: () => Center(child: CustomLoadingAnimation(size: 30.sp)),
    );
  }
}

