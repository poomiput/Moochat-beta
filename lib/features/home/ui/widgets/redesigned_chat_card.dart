import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/shared/models/user_chat_model.dart';
import 'package:moochat/features/chat/data/enums/message_type.dart';
import 'package:easy_localization/easy_localization.dart';

/// Redesigned chat card with avatar on right, modern layout
class RedesignedChatCard extends StatefulWidget {
  final UserChat userChat;
  final VoidCallback onTap;

  const RedesignedChatCard({
    super.key,
    required this.userChat,
    required this.onTap,
  });

  @override
  State<RedesignedChatCard> createState() => _RedesignedChatCardState();
}

class _RedesignedChatCardState extends State<RedesignedChatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) => _handleTapDown(),
            onTapUp: (_) => _handleTapUp(),
            onTapCancel: () => _handleTapCancel(),
            onTap: widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                color: ColorsManager.cardColor,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: ColorsManager.strokeColor,
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    offset: Offset(0, 2.h),
                    blurRadius: 8.r,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  children: [
                    // Content section (left)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name and time row
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.userChat.username2P,
                                  style: TextStyle(
                                    color: ColorsManager.titleText,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                _getFormattedTime(),
                                style: TextStyle(
                                  color: ColorsManager.captionText,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 4.h),

                          // Last message
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _getLastMessagePreview(),
                                  style: TextStyle(
                                    color: ColorsManager.subtitleText,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w400,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              // Unread count badge
                              if (_getUnreadCount() > 0)
                                Container(
                                  constraints: BoxConstraints(minWidth: 20.w),
                                  height: 20.h,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ColorsManager.primaryColor,
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getUnreadCount().toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(width: 12.w),

                    // Avatar section (right)
                    Container(
                      width: 48.w,
                      height: 48.w,
                      decoration: BoxDecoration(
                        color: ColorsManager.avatarBackground,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: ColorsManager.strokeColor.withOpacity(0.5),
                          width: 0.5,
                        ),
                      ),
                      child: _buildDefaultAvatar(),
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

  Widget _buildDefaultAvatar() {
    return Icon(Icons.person, color: ColorsManager.captionText, size: 24.sp);
  }

  void _handleTapDown() {
    _animationController.forward();
  }

  void _handleTapUp() {
    _animationController.reverse();
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }

  String _getFormattedTime() {
    if (widget.userChat.messages.isEmpty) {
      return '';
    }

    final lastMessage = widget.userChat.messages.last;
    final now = DateTime.now();
    final messageTime = lastMessage.timestamp;

    final difference = now.difference(messageTime);

    if (difference.inMinutes < 1) {
      return context.tr('now');
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(messageTime);
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(messageTime);
    } else {
      return DateFormat('dd/MM').format(messageTime);
    }
  }

  String _getLastMessagePreview() {
    if (widget.userChat.messages.isEmpty) {
      return 'No messages';
    }

    final lastMessage = widget.userChat.messages.last;

    // Handle different message types
    switch (lastMessage.type) {
      case MessageType.text:
        return lastMessage.text;
      case MessageType.image:
        return '📷 Photo';
      case MessageType.voice:
        return '🎵 Audio Message';
      case MessageType.file:
        return '📄 File';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.location:
        return '📍 Location';
    }
  }

  int _getUnreadCount() {
    // This would typically come from your state management
    // For now, return 0 as placeholder
    return 0;
  }
}
