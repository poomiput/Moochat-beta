import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/helpers/extensions.dart';
import 'package:moochat/core/routing/routes.dart';
import 'package:moochat/core/shared/models/user_chat_model.dart';
import 'package:moochat/core/shared/providers/bluetooth_state_provider.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/theming/styles.dart';
import 'package:moochat/features/chat/data/enums/message_status.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatRowData extends ConsumerWidget {
  final UserChat userData2P;
  final String userName;
  final String lastMessage;
  final DateTime? time;
  final bool isOnline;
  final int unreadCount;
  final MessageStatus messageStatus;

  const ChatRowData({
    super.key,
    required this.userData2P,
    required this.userName,
    required this.lastMessage,
    required this.time,
    this.isOnline = false,
    this.unreadCount = 0,
    this.messageStatus = MessageStatus.sending,
  });
  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorsManager.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return const Column(); // Assuming ChatOption is defined elsewhere
      },
    );
  }

  Widget _buildMessageStatus(MessageStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        color = Colors.white.withOpacity(0.5);
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        color = Colors.white.withOpacity(0.7);
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.white.withOpacity(0.7);
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = ColorsManager.customGreen;
        break;
    }

    return Icon(icon, size: 16.0, color: color);
  }

  String formatTime(dynamic timeValue) {
    if (timeValue == null) return "";

    // If it's already a string, return it
    if (timeValue is String) return timeValue;

    // If it's a DateTime, format it
    if (timeValue is DateTime) {
      int hour = timeValue.hour;
      int minute = timeValue.minute;

      // Convert to 12-hour format
      String period = hour >= 12 ? 'PM' : 'AM';
      int displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

      return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    }

    return timeValue.toString();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool bluetoothEnabled = ref.watch(isBluetoothOnProvider);
    return InkWell(
      onTap: () {
        context.pushNamed(
          RoutesManager.chatScreen,
          arguments: {'userData': userData2P},
        );
      },
      onLongPress: () {
        _showChatOptions(context);
      },

      splashColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.white.withOpacity(0.05),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            // Status indicator
            Icon(
              Icons.online_prediction,
              size: 30.w,
              color: userData2P.uuid2P == "loby"
                  ? bluetoothEnabled
                        ? Colors.green
                        : Colors.red
                  : isOnline
                  ? Colors.green
                  : Colors.red,
            ),

            SizedBox(width: 16.w),

            // Main content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: CustomTextStyles.font20WhiteBold.copyWith(
                      fontSize: 16.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),

                  // build row with last message and and status of message icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // check if lastMessage is not null or empty  return the status icon else return empty widget
                      time != null
                          ? _buildMessageStatus(messageStatus)
                          : SizedBox(),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          lastMessage,
                          style: CustomTextStyles.font16WhiteRegular.copyWith(
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Trailing with unread count badge
            _buildTrailingWithBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrailingWithBadge() {
    if (unreadCount > 0) {
      // Show both time and unread badge when there are unread messages
      return SizedBox(
        width: 80.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              // if time isnot null , format it to string like that "HH:mm" AM/PM
              formatTime(time),
              style: CustomTextStyles.font14GrayRegular.copyWith(
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: BoxConstraints(minWidth: 20.w, minHeight: 20.h),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    } else if (time == null) {
      return SizedBox(
        width: 80.w,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: ColorsManager.whiteColor.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              constraints: BoxConstraints(minWidth: 3.w, minHeight: 3.h),
              child: Text(''),
            ),
          ],
        ),
      );
    } else {
      // Show only time when no unread messages
      return Text(
        formatTime(time),
        style: CustomTextStyles.font14GrayRegular.copyWith(
          color: Colors.white70,
        ),
      );
    }
  }
}
