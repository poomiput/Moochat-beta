import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/theming/styles.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutApp extends StatefulWidget {
  AboutApp({super.key});

  @override
  State<AboutApp> createState() => _AboutAppState();
}

class _AboutAppState extends State<AboutApp> {
  String _appName = '';
  String _version = '';
  String _buildNumber = '';
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    getAppVersion();
  }

  Future<void> getAppVersion() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appName = packageInfo.appName;
        _version = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height:
          MediaQuery.of(context).size.height *
          0.9, // Limit height to 80% of screen
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
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // App Icon
                  Container(
                    width: 80.w,
                    height: 80.h,
                    margin: EdgeInsets.only(bottom: 20.h),
                    child: Image.asset("assets/icons/logo_app_black.png"),
                  ),

                  // App Description
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16.w),
                    margin: EdgeInsets.only(bottom: 20.h),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr("about"),
                          style: CustomTextStyles.font16WhiteRegular.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          context.tr("about_text"),
                          style: CustomTextStyles.font16WhiteRegular.copyWith(
                            fontSize: 14.sp,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          context.tr("key_features"),
                          style: CustomTextStyles.font16WhiteRegular.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15.sp,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        _buildFeature('📱', context.tr("feature_1")),
                        _buildFeature('🌐', context.tr("feature_2")),
                        _buildFeature('💬', context.tr("feature_3")),
                        _buildFeature('🔒', context.tr("feature_4")),
                        _buildFeature('🤝', context.tr("feature_5")),
                      ],
                    ),
                  ),

                  // App Info
                  if (_isLoading)
                    Container(
                      padding: EdgeInsets.all(20.w),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    )
                  else if (_error != null)
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Error: $_error',
                        style: CustomTextStyles.font16WhiteRegular.copyWith(
                          color: Colors.red[300],
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr("app_info"),
                            style: CustomTextStyles.font16WhiteRegular.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16.sp,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          _buildInfoRow(context.tr("app_name"), _appName),
                          SizedBox(height: 8.h),
                          _buildInfoRow(context.tr("version"), _version),
                          SizedBox(height: 8.h),
                          _buildInfoRow(
                            context.tr("build_number"),
                            _buildNumber,
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 20.h),

                  // Footer message
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          color: Colors.red[300],
                          size: 16.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            context.tr("footer_message"),
                            style: CustomTextStyles.font16WhiteRegular.copyWith(
                              fontSize: 12.sp,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Add some bottom padding for better scrolling
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String emoji, String feature) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 14.sp)),
          SizedBox(width: 8.w),
          Text(
            feature,
            style: CustomTextStyles.font16WhiteRegular.copyWith(
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100.w,
          child: Text(
            '$label:',
            style: CustomTextStyles.font16WhiteRegular.copyWith(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: CustomTextStyles.font16WhiteRegular.copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
