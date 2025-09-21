import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/helpers/extensions.dart';
import 'package:moochat/core/helpers/logger_debug.dart';
import 'package:moochat/core/helpers/shared_prefences.dart';
import 'package:moochat/core/shared/models/user_chat_model.dart';
import 'package:moochat/core/shared/providers/bluetooth_state_provider.dart';
import 'package:moochat/core/shared/providers/managing_bluetooth_state_privder.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/theming/styles.dart';
import 'package:moochat/features/chat/data/models/chat_message_model.dart';
import 'package:moochat/features/chat/ui/widgets/chat_option.dart';
import 'package:moochat/features/chat/ui/widgets/custom_text_input_field.dart';
import 'package:moochat/features/chat/ui/widgets/message_bubble_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moochat/features/chat/ui/widgets/no_message_yet.dart';
import 'package:moochat/features/home/providrs/user_data_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.userData});
  final UserChat userData;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool isEnabling = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void onSendMessage(ChatMessage message) async {
    // Add message to local chat first
    ref
        .read(userDataProvider.notifier)
        .addMessageToChat(widget.userData.uuid2P, message);

    // Auto-scroll to bottom after sending message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0, // Since reverse: true, 0.0 is the bottom
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Try to send message via Bluetooth
    await _sendBluetoothMessage(message);
  }

  Future<void> _sendBluetoothMessage(ChatMessage message) async {
    LoggerDebug.logger.t(
      'Attempting to send message: ${message.text} to user ${widget.userData.uuid2P}',
    );
    final bluetoothProvider = ref.read(nearbayStateProvider.notifier);
    // print all connected devices with id and uuid
    LoggerDebug.logger.t(
      'Connected devices: ${bluetoothProvider.state.connectedDevices.map((d) => "${d.uuid} (${d.id})").join(", ")}',
    );

    // Check if the user is connected
    final isConnected = bluetoothProvider.isUserConnected(
      widget.userData.uuid2P,
    );
    LoggerDebug.logger.t(
      'User ${widget.userData.uuid2P} is connected: $isConnected',
    );

    if (isConnected) {
      // Get the connected device
      final device = bluetoothProvider.getConnectedDeviceByUsername(
        widget.userData.uuid2P,
      );
      LoggerDebug.logger.t(
        'Connected device for ${widget.userData.uuid2P}: ${device?.uuid} (${device?.id})',
      );

      if (device != null) {
        LoggerDebug.logger.t(
          'Sending message to device ${device.uuid} (${device.id})',
        );
        // Create message payload
        // get my uuid from shared preferences or user data
        final myUUID = await SharedPrefHelper.getString("uuid");
        // Assuming you have a method to get current user's UUID
        final messagePayload = {
          'id': message.id,
          'text': message.text,
          'timestamp': message.timestamp.toIso8601String(),
          'type': message.type.toString(),
          'senderUsername': myUUID, // Current user sending to this username
        };

        final jsonMessage = jsonEncode(messagePayload);

        // Send message
        final success = await bluetoothProvider.sendMessageToDevice(
          device.id,
          jsonMessage,
        );

        // Update message status based on send result
        /*final updatedMessage = ChatMessage(
          id: message.id,
          text: message.text,
          isSentByMe: message.isSentByMe,
          timestamp: message.timestamp,
          status: success ? MessageStatus.sent : MessageStatus.read,
          type: message.type,
        );

        // Update the message status in the chat
        ref
            .read(userDataProvider.notifier)
            .updateMessageStatus(
              widget.userData.uuid2P,
              message.id,
              success ? MessageStatus.sent : MessageStatus.failed,
            );*/
      }
    } else {
      // User is not connected, mark message as failed
      /*ref
          .read(userDataProvider.notifier)
          .updateMessageStatus(
            widget.userData.uuid2P,
            message.id,
            MessageStatus.failed,
          );*/
    }
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorsManager.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return ChatOption(uuid2P: widget.userData.uuid2P);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(userDataProvider);
    final bool bluetoothEnabled = ref.watch(isBluetoothOnProvider);
    final bluetoothState = ref.watch(nearbayStateProvider);

    // Check if user is online (connected via Bluetooth)
    final bool isUserOnline = bluetoothState.connectedDevices.any(
      (device) => device.uuid == widget.userData.uuid2P,
    );

    final currentUserData = ref
        .watch(userDataProvider.notifier)
        .getChatByUuid(widget.userData.uuid2P);

    return Scaffold(
      backgroundColor: ColorsManager.backgroundColor,

      // add bacground image
      appBar: AppBar(
        backgroundColor: ColorsManager.backgroundColor,
        title: Row(
          children: [
            Text(
              currentUserData!.username2P,
              style: CustomTextStyles.font20WhiteRegular,
            ),
            SizedBox(width: 8.w),
            currentUserData.uuid2P != "loby"
                ? const Icon(Icons.lock, color: Colors.grey, size: 20)
                : SizedBox.shrink(),
            SizedBox(width: 8.w),

            currentUserData.uuid2P == "loby"
                ? const Icon(
                    Icons.public_outlined,
                    color: Colors.white,
                    size: 20,
                  )
                : Icon(
                    isUserOnline ? Icons.online_prediction : Icons.link_off,
                    color: isUserOnline ? Colors.green : Colors.red,
                    size: 25.sp,
                  ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white, size: 25.sp),
            onPressed: () {
              _showChatOptions(context);
            },
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: GestureDetector(
        onTap: () {
          // Remove focus when tapping anywhere on the screen
          FocusScope.of(context).unfocus();
        },
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/chat_background.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Column(
                  children: [
                    // Chat messages area
                    Expanded(
                      child: _buildMessagesList(currentUserData.messages),
                    ),

                    // Input field at bottom
                    !bluetoothEnabled
                        ? Container(
                            padding: EdgeInsets.all(16.w),
                            child: Text(
                              textAlign: TextAlign.center,
                              context.tr('on_bluetooth_disabled'),
                              style: CustomTextStyles.font16GrayRegular,
                            ),
                          )
                        : !currentUserData.isBlocked
                        ? CustomTextInputField(
                            onSendMessage: onSendMessage,
                            uuid2P: widget.userData.uuid2P,
                          )
                        : Container(
                            padding: EdgeInsets.all(16.w),
                            child: Text(
                              textAlign: TextAlign.center,
                              context.tr('user_blocked'),
                              style: CustomTextStyles.font16GrayRegular,
                            ),
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

  Widget _buildMessagesList(List<ChatMessage> messages) {
    return messages.isEmpty
        ? NoMessageYet()
        : ListView.builder(
            controller: _scrollController,
            reverse: true, // Start from bottom
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message =
                  messages[messages.length - 1 - index]; // Reverse order
              final isConsecutive =
                  index < messages.length - 1 &&
                  messages[messages.length - index - 2].isSentByMe ==
                      message.isSentByMe;

              return MessageBubble(
                message: message,
                isConsecutive: isConsecutive,
              );
            },
          );
  }
}
