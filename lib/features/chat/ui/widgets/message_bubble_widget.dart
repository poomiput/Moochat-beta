import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gazachat/core/theming/colors.dart';
import 'package:gazachat/core/theming/styles.dart';
import 'package:gazachat/features/chat/data/enums/message_status.dart';
import 'package:gazachat/features/chat/data/enums/message_type.dart';
import 'package:gazachat/features/chat/data/models/chat_message_model.dart';
import 'package:url_launcher/url_launcher.dart';

class MessageBubble extends StatelessWidget {
  MessageBubble({super.key, required this.message, this.isConsecutive = false});

  final bool isConsecutive;
  final ChatMessage message;
  late final bool isMe = message.isSentByMe;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // hide the ink splash effect
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,

      onLongPress: () {
        // Handle long press if needed
        // copy the message text to clipboard
        Clipboard.setData(ClipboardData(text: message.text));
      },
      child: Container(
        margin: EdgeInsets.only(
          top: isConsecutive ? 2.0 : 8.0,
          bottom: 2.0,
          left: isMe ? 64.0 : 0.0,
          right: isMe ? 0.0 : 64.0,
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Sender name (only show if not consecutive or if it's the first message in a group)
            if (!isConsecutive)
              Padding(
                padding: EdgeInsets.only(
                  left: isMe ? 0.0 : 16.0,
                  right: isMe ? 16.0 : 0.0,
                  bottom: 4.0,
                ),
                child: Text(
                  isMe ? context.tr("me") : message.username2P,
                  style: CustomTextStyles.font16WhiteRegular.copyWith(
                    color: Colors.grey[600],
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            // Message bubble
            GestureDetector(
              onTap: message.type == MessageType.location
                  ? () => _openLocation(message.text)
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  color: isMe
                      ? ColorsManager.customGreen.withOpacity(0.9)
                      : ColorsManager.customGray.withOpacity(0.9),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20.0),
                    topRight: const Radius.circular(20.0),
                    bottomLeft: Radius.circular(isMe ? 20.0 : 4.0),
                    bottomRight: Radius.circular(isMe ? 4.0 : 20.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4.0,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message content
                    _buildMessageContent(context),
                    const SizedBox(height: 4.0),
                    // Timestamp and status row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.timestamp),
                          style: CustomTextStyles.font16WhiteRegular.copyWith(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12.0,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4.0),
                          _buildMessageStatus(message.status),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    if (message.type == MessageType.location) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.white, size: 20.0),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  context.tr("location"),
                  style: CustomTextStyles.font16WhiteRegular.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            context.tr("tap_to_review_location"),
            style: CustomTextStyles.font16WhiteRegular.copyWith(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14.0,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    } else {
      return Text(
        message.text,
        style: CustomTextStyles.font16WhiteRegular.copyWith(
          color: Colors.white,
          height: 1.4,
        ),
      );
    }
  }

  Future<void> _openLocation(String locationUrl) async {
    try {
      final Uri url = Uri.parse(locationUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode
              .externalApplication, // Opens in external app (Google Maps)
        );
      } else {
        // Fallback: try to open in browser
        await launchUrl(url, mode: LaunchMode.inAppWebView);
      }
    } catch (e) {
      // Handle error - you might want to show a snackbar or toast
      debugPrint('Error opening location: $e');
    }
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

  String _formatTime(DateTime dateTime) {
    // show the time sendit like 12:30 PM or 1:45 AM like whatsApp does just show the hour and minute send it the message without extra logic
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} ${dateTime.hour >= 12 ? 'PM' : 'AM'}';

    /* final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${dateTime.day}/${dateTime.month}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }*/
  }
}

