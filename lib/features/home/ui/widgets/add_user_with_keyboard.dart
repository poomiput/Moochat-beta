import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/helpers/extensions.dart';
import 'package:moochat/core/routing/routes.dart';
import 'package:moochat/core/shared/models/user_chat_model.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/features/home/providrs/user_data_provider.dart';

class AddUserDialog extends ConsumerStatefulWidget {
  const AddUserDialog({super.key, this.headerText});

  final String? headerText;

  @override
  ConsumerState<AddUserDialog> createState() => AddUserDialogState();
}

class AddUserDialogState extends ConsumerState<AddUserDialog>
    with TickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _uuidController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _uuidController.dispose();
    super.dispose();
  }

  void _handleAddUser() async {
    final username = _usernameController.text.trim();
    final uuid = _uuidController.text.trim();

    // Validate username
    if (username.isEmpty) {
      _showErrorSnackBar(context.tr('username_empty_error'));
      return;
    }

    // Validate UUID
    if (uuid.isEmpty) {
      _showErrorSnackBar(context.tr('uuid_empty_error'));
      return;
    }

    // Basic UUID format validation (you can make this more strict)
    if (uuid.length < 10) {
      _showErrorSnackBar(context.tr('uuid_invalid_error'));
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Call your provider method to add user
      // Replace this with your actual method
      ref
          .read(userDataProvider.notifier)
          .addChat(UserChat(username2P: username, uuid2P: uuid));
      final chatData = ref.read(userDataProvider.notifier).getChatByUuid(uuid);
      context.pop();
      context.pushNamed(
        RoutesManager.chatScreen,
        arguments: {'userData': chatData},
      );

      if (!mounted) return;
      _showSuccessSnackBar(context.tr('user_added_success'));

      // Close dialog after showing success message
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.of(context).pop({'username': username, 'uuid': uuid});
        }
      });
    } catch (error) {
      if (!mounted) return;
      _showErrorSnackBar(
        '${context.tr("failed_add_user")} ${error.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ColorsManager.customRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: ColorsManager.backgroundColor,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: ColorsManager.customGray.withOpacity(0.3),
                    width: 1.w,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20.r,
                      offset: Offset(0, 10.h),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icon and title
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: ColorsManager.mainColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.person_add_outlined,
                            color: ColorsManager.mainColor,
                            size: 24.sp,
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.headerText ?? context.tr("add_user"),
                                style: TextStyle(
                                  color: ColorsManager.whiteColor,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                context.tr("enter_user_details"),
                                style: TextStyle(
                                  color: ColorsManager.grayColor,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24.h),

                    // Username input field
                    Container(
                      decoration: BoxDecoration(
                        color: ColorsManager.customGray.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: ColorsManager.customGray.withOpacity(0.5),
                          width: 1.w,
                        ),
                      ),
                      child: TextField(
                        controller: _usernameController,
                        enabled: !_isLoading,
                        style: TextStyle(
                          color: ColorsManager.whiteColor,
                          fontSize: 16.sp,
                        ),
                        decoration: InputDecoration(
                          hintText: context.tr("username_hint"),
                          hintStyle: TextStyle(
                            color: ColorsManager.grayColor.withOpacity(0.7),
                            fontSize: 16.sp,
                          ),
                          prefixIcon: Icon(
                            Icons.alternate_email,
                            color: ColorsManager.grayColor,
                            size: 20.sp,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                        ),
                        maxLength: 30,
                        buildCounter:
                            (
                              context, {
                              required currentLength,
                              required isFocused,
                              maxLength,
                            }) {
                              return Text(
                                '$currentLength/${maxLength ?? 30}',
                                style: TextStyle(
                                  color: ColorsManager.grayColor.withOpacity(
                                    0.7,
                                  ),
                                  fontSize: 12.sp,
                                ),
                              );
                            },
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // UUID input field
                    Container(
                      decoration: BoxDecoration(
                        color: ColorsManager.customGray.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: ColorsManager.customGray.withOpacity(0.5),
                          width: 1.w,
                        ),
                      ),
                      child: TextField(
                        controller: _uuidController,
                        enabled: !_isLoading,
                        style: TextStyle(
                          color: ColorsManager.whiteColor,
                          fontSize: 16.sp,
                        ),
                        decoration: InputDecoration(
                          hintText: context.tr("uuid_hint"),
                          hintStyle: TextStyle(
                            color: ColorsManager.grayColor.withOpacity(0.7),
                            fontSize: 16.sp,
                          ),
                          prefixIcon: Icon(
                            Icons.fingerprint,
                            color: ColorsManager.grayColor,
                            size: 20.sp,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                        ),
                        maxLength: 50,
                        buildCounter:
                            (
                              context, {
                              required currentLength,
                              required isFocused,
                              maxLength,
                            }) {
                              return Text(
                                '$currentLength/${maxLength ?? 50}',
                                style: TextStyle(
                                  color: ColorsManager.grayColor.withOpacity(
                                    0.7,
                                  ),
                                  fontSize: 12.sp,
                                ),
                              );
                            },
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Action buttons
                    Row(
                      children: [
                        // Cancel button
                        Expanded(
                          child: Container(
                            height: 48.h,
                            decoration: BoxDecoration(
                              color: ColorsManager.customGray.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: ColorsManager.customGray.withOpacity(
                                  0.5,
                                ),
                                width: 1.w,
                              ),
                            ),
                            child: TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      if (!mounted) return;
                                      Navigator.of(context).pop();
                                    },
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: Text(
                                context.tr("cancel"),
                                style: TextStyle(
                                  color: _isLoading
                                      ? ColorsManager.whiteColor.withOpacity(
                                          0.5,
                                        )
                                      : ColorsManager.whiteColor,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: 12.w),

                        // Add button
                        Expanded(
                          child: Container(
                            height: 48.h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  ColorsManager.mainColor,
                                  ColorsManager.mainColor.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12.r),
                              boxShadow: [
                                BoxShadow(
                                  color: ColorsManager.mainColor.withOpacity(
                                    0.3,
                                  ),
                                  blurRadius: 8.r,
                                  offset: Offset(0, 4.h),
                                ),
                              ],
                            ),
                            child: TextButton(
                              onPressed: _isLoading ? null : _handleAddUser,
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 20.w,
                                      height: 20.h,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              ColorsManager.whiteColor,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      context.tr("add"),
                                      style: TextStyle(
                                        color: ColorsManager.whiteColor,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
