import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:easy_localization/easy_localization.dart';

/// Redesigned settings screen with modern card layout
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.backgroundColor,
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Header section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),

                  // Profile section
                  Container(
                    decoration: BoxDecoration(
                      color: ColorsManager.cardColor,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: ColorsManager.strokeColor,
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          offset: Offset(0, 2.h),
                          blurRadius: 8.r,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20.w),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: 64.w,
                            height: 64.w,
                            decoration: BoxDecoration(
                              color: ColorsManager.accentColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: ColorsManager.accentColor.withOpacity(
                                  0.3,
                                ),
                                width: 0.5,
                              ),
                            ),
                            child: Icon(
                              Icons.person,
                              color: ColorsManager.accentColor,
                              size: 28.sp,
                            ),
                          ),

                          SizedBox(width: 16.w),

                          // User info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'John Doe', // Replace with actual user name
                                  style: TextStyle(
                                    color: ColorsManager.titleText,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'john.doe@example.com', // Replace with actual email
                                  style: TextStyle(
                                    color: ColorsManager.subtitleText,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Edit button
                          GestureDetector(
                            onTap: () => _editProfile(),
                            child: Container(
                              width: 36.w,
                              height: 36.w,
                              decoration: BoxDecoration(
                                color: ColorsManager.backgroundColor,
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(
                                  color: ColorsManager.strokeColor,
                                  width: 0.5,
                                ),
                              ),
                              child: Icon(
                                Icons.edit,
                                color: ColorsManager.bodyText,
                                size: 16.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // Settings title
                  Text(
                    context.tr('settings'),
                    style: TextStyle(
                      color: ColorsManager.titleText,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),

                  SizedBox(height: 16.h),
                ],
              ),
            ),
          ),

          // Settings sections
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSettingsSection(
                  title: context.tr('preferences'),
                  items: [
                    SettingsItem(
                      icon: Icons.palette,
                      title: context.tr('theme'),
                      subtitle: context.tr('dark_light_mode'),
                      onTap: () => _showThemeSelector(),
                    ),
                    SettingsItem(
                      icon: Icons.language,
                      title: context.tr('language'),
                      subtitle: context.tr('app_language'),
                      onTap: () => _showLanguageSelector(),
                    ),
                    SettingsItem(
                      icon: Icons.notifications,
                      title: context.tr('notifications'),
                      subtitle: context.tr('manage_notifications'),
                      onTap: () => _openNotificationSettings(),
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                _buildSettingsSection(
                  title: context.tr('chat'),
                  items: [
                    SettingsItem(
                      icon: Icons.chat_bubble,
                      title: context.tr('chat_settings'),
                      subtitle: context.tr('message_preferences'),
                      onTap: () => _openChatSettings(),
                    ),
                    SettingsItem(
                      icon: Icons.backup,
                      title: context.tr('backup'),
                      subtitle: context.tr('backup_restore_chats'),
                      onTap: () => _openBackupSettings(),
                    ),
                    SettingsItem(
                      icon: Icons.security,
                      title: context.tr('privacy_security'),
                      subtitle: context.tr('privacy_settings'),
                      onTap: () => _openPrivacySettings(),
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                _buildSettingsSection(
                  title: context.tr('about'),
                  items: [
                    SettingsItem(
                      icon: Icons.help,
                      title: context.tr('help_support'),
                      subtitle: context.tr('get_help'),
                      onTap: () => _openHelpSupport(),
                    ),
                    SettingsItem(
                      icon: Icons.info,
                      title: context.tr('about_app'),
                      subtitle: 'Version 1.0.0',
                      onTap: () => _showAboutDialog(),
                    ),
                    SettingsItem(
                      icon: Icons.star,
                      title: context.tr('rate_app'),
                      subtitle: context.tr('rate_on_store'),
                      onTap: () => _rateApp(),
                    ),
                  ],
                ),

                SizedBox(height: 100.h),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<SettingsItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: ColorsManager.subtitleText,
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),

        SizedBox(height: 12.h),

        Container(
          decoration: BoxDecoration(
            color: ColorsManager.cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: ColorsManager.strokeColor, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                offset: Offset(0, 2.h),
                blurRadius: 8.r,
              ),
            ],
          ),
          child: Column(
            children: items.map((item) => _buildSettingsItem(item)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsItem(SettingsItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          border: item != _getLastItem()
              ? Border(
                  bottom: BorderSide(
                    color: ColorsManager.strokeColor.withOpacity(0.3),
                    width: 0.5,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: ColorsManager.backgroundColor,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: ColorsManager.strokeColor,
                  width: 0.5,
                ),
              ),
              child: Icon(
                item.icon,
                color: ColorsManager.bodyText,
                size: 16.sp,
              ),
            ),

            SizedBox(width: 12.w),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: ColorsManager.titleText,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      item.subtitle!,
                      style: TextStyle(
                        color: ColorsManager.subtitleText,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Chevron
            Icon(
              Icons.chevron_right,
              color: ColorsManager.captionText,
              size: 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  SettingsItem _getLastItem() {
    // Helper to avoid border on last item - placeholder
    return SettingsItem(icon: Icons.star, title: '', onTap: () {});
  }

  // Action handlers
  void _editProfile() {
    // Navigate to profile edit screen
  }

  void _showThemeSelector() {
    // Show theme selection dialog
  }

  void _showLanguageSelector() {
    // Show language selection dialog
  }

  void _openNotificationSettings() {
    // Navigate to notification settings
  }

  void _openChatSettings() {
    // Navigate to chat settings
  }

  void _openBackupSettings() {
    // Navigate to backup settings
  }

  void _openPrivacySettings() {
    // Navigate to privacy settings
  }

  void _openHelpSupport() {
    // Navigate to help & support
  }

  void _showAboutDialog() {
    // Show about dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: ColorsManager.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          context.tr('about_app'),
          style: TextStyle(
            color: ColorsManager.titleText,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'MooChat v1.0.0\n\n${context.tr('app_description')}',
          style: TextStyle(
            color: ColorsManager.subtitleText,
            fontSize: 14.sp,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              context.tr('ok'),
              style: TextStyle(
                color: ColorsManager.accentColor,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _rateApp() {
    // Open app store rating
  }
}

/// Settings item model
class SettingsItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}
