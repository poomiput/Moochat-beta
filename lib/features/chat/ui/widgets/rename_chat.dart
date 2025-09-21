import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/features/home/providrs/user_data_provider.dart';

class RenameChatDialog extends ConsumerStatefulWidget {
  const RenameChatDialog({
    super.key,
    required this.uuid2P,
    this.initialUsername,
    this.headerText,
  });

  final String uuid2P;
  final String? initialUsername;
  final String? headerText;

  @override
  ConsumerState<RenameChatDialog> createState() => RenameChatDialogState();
}

class RenameChatDialogState extends ConsumerState<RenameChatDialog>
    with TickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Set initial username if provided
    _usernameController.text = widget.initialUsername ?? '';

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
    super.dispose();
  }

  void _handleUsernameChange() async {
    if (_usernameController.text.trim().isEmpty) {
      _showErrorSnackBar(context.tr('username_empty_error'));

      return;
    }

    final newUsername = _usernameController.text.trim();

    // Check if username is the same as current
    if (newUsername == widget.initialUsername) {
      _showErrorSnackBar(context.tr('username_same_error'));

      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Directly call the provider method
      await ref
          .read(userDataProvider.notifier)
          .renameChat(widget.uuid2P, newUsername);

      if (!mounted) return;
      _showSuccessSnackBar(context.tr('username_change_success'));

      // Close dialog after showing success message
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } catch (error) {
      if (!mounted) return;
      _showErrorSnackBar(
        '${context.tr("faild_change_username")} ${error.toString()}',
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
                            Icons.person_outline,
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
                                widget.headerText ?? context.tr("rename_chat"),
                                style: TextStyle(
                                  color: ColorsManager.whiteColor,
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                context.tr("enter_username"),
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

                    // Input field
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

                        // Change button
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
                              onPressed: _isLoading
                                  ? null
                                  : _handleUsernameChange,
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
                                      context.tr("change"),
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
