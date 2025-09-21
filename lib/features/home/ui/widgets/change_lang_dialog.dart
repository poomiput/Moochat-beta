import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/helpers/extensions.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/theming/styles.dart';
import 'package:moochat/features/home/data/models/lang_model.dart';

class LanguageChangeDialog extends StatefulWidget {
  final String currentLanguage;
  final Function(String) onLanguageChanged;

  const LanguageChangeDialog({
    Key? key,
    required this.currentLanguage,
    required this.onLanguageChanged,
  }) : super(key: key);

  @override
  State<LanguageChangeDialog> createState() => _LanguageChangeDialogState();
}

class _LanguageChangeDialogState extends State<LanguageChangeDialog> {
  late String selectedLanguage;

  final List<LanguageOption> languages = [
    LanguageOption(
      code: 'th',
      name: 'Thai',
      nativeName: 'ภาษาไทย',
      flag: '��',
    ),
    LanguageOption(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flag: '🇬🇧',
    ),
  ];

  @override
  void initState() {
    super.initState();
    selectedLanguage = widget.currentLanguage;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ColorsManager.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: ColorsManager.backgroundColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: ColorsManager.customGray, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.language,
                  color: ColorsManager.mainColor,
                  size: 24.w,
                ),
                SizedBox(width: 12.w),
                Text(
                  context.tr('change_language'),
                  style: CustomTextStyles.font20WhiteBold,
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Language Options
            ...languages.map((language) => _buildLanguageOption(language)),

            SizedBox(height: 24.h),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Cancel Button
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 12.h,
                    ),
                  ),
                  child: Text(
                    context.tr('cancel'),
                    style: CustomTextStyles.font16GrayRegular,
                  ),
                ),
                SizedBox(width: 12.w),

                // Save Button
                ElevatedButton(
                  onPressed: selectedLanguage != widget.currentLanguage
                      ? () {
                          CustomTextStyles.updateLocale(
                            context.locale.toString(),
                          );
                          widget.onLanguageChanged(selectedLanguage);
                          context.pop();
                          context.pop();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManager.mainColor,
                    disabledBackgroundColor: ColorsManager.customGray,
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 12.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text(
                    context.tr('save'),
                    style: CustomTextStyles.font16WhiteRegular,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(LanguageOption language) {
    final isSelected = selectedLanguage == language.code;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedLanguage = language.code;
          });
        },
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isSelected
                ? ColorsManager.mainColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected
                  ? ColorsManager.mainColor
                  : ColorsManager.customGray,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Flag
              Text(language.flag, style: TextStyle(fontSize: 24.sp)),
              SizedBox(width: 16.w),

              // Language Names
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language.name,
                      style: CustomTextStyles.font16WhiteRegular,
                    ),
                    if (language.name != language.nativeName) ...[
                      SizedBox(height: 2.h),
                      Text(
                        language.nativeName,
                        style: CustomTextStyles.font14GrayRegular,
                      ),
                    ],
                  ],
                ),
              ),

              // Selection Indicator
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: ColorsManager.mainColor,
                  size: 20.w,
                )
              else
                Icon(
                  Icons.radio_button_unchecked,
                  color: ColorsManager.grayColor,
                  size: 20.w,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showLanguageChangeDialog({
  required BuildContext context,
  required String currentLanguage,
  required Function(String) onLanguageChanged,
}) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => LanguageChangeDialog(
      currentLanguage: currentLanguage,
      onLanguageChanged: onLanguageChanged,
    ),
  );
}
