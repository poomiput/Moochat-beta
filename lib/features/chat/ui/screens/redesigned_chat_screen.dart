import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/widgets/floating_composer.dart';
import 'package:moochat/core/shared/models/user_chat_model.dart';
import 'package:easy_localization/easy_localization.dart';

/// Redesigned chat screen demonstrating the floating composer
class RedesignedChatScreen extends ConsumerStatefulWidget {
  final UserChat userData;

  const RedesignedChatScreen({super.key, required this.userData});

  @override
  ConsumerState<RedesignedChatScreen> createState() =>
      _RedesignedChatScreenState();
}

class _RedesignedChatScreenState extends ConsumerState<RedesignedChatScreen> {
  bool _isRecording = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsManager.backgroundColor,
      appBar: AppBar(
        backgroundColor: ColorsManager.backgroundColor,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ColorsManager.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ColorsManager.strokeColor, width: 0.5),
            ),
            child: Icon(
              Icons.arrow_back,
              color: ColorsManager.bodyText,
              size: 20,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: ColorsManager.avatarBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ColorsManager.strokeColor.withOpacity(0.5),
                  width: 0.5,
                ),
              ),
              child: Icon(
                Icons.person,
                color: ColorsManager.captionText,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userData.username2P,
                    style: TextStyle(
                      color: ColorsManager.titleText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    context.tr('online'),
                    style: TextStyle(
                      color: ColorsManager.captionText,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ColorsManager.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ColorsManager.strokeColor, width: 0.5),
            ),
            child: IconButton(
              onPressed: () => _showChatOptions(),
              icon: Icon(
                Icons.more_vert,
                color: ColorsManager.bodyText,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Chat messages area
          Positioned.fill(
            bottom: 120, // Leave space for floating composer
            child: _buildMessagesArea(),
          ),

          // Floating composer
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    ColorsManager.backgroundColor.withOpacity(0.0),
                    ColorsManager.backgroundColor.withOpacity(0.8),
                    ColorsManager.backgroundColor,
                  ],
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
              child: FloatingComposer(
                isRecording: _isRecording,
                onCameraPressed: () => _handleCameraPressed(),
                onMicPressed: () => _handleMicPressed(),
                onAttachPressed: () => _handleAttachPressed(),
                onMessageSent: (message) => _handleMessageSent(message),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: widget.userData.messages.isEmpty
          ? _buildEmptyState()
          : _buildMessagesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: ColorsManager.cardColor,
              borderRadius: BorderRadius.circular(60),
              border: Border.all(color: ColorsManager.strokeColor, width: 1),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              color: ColorsManager.captionText,
              size: 48,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'No messages yet',
            style: TextStyle(
              color: ColorsManager.subtitleText,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Start the conversation with ${widget.userData.username2P}',
            style: TextStyle(
              color: ColorsManager.captionText,
              fontSize: 14,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: widget.userData.messages.length,
      itemBuilder: (context, index) {
        final message = widget.userData.messages.reversed.toList()[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: message.isSentByMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: message.isSentByMe
                      ? ColorsManager.primaryColor
                      : ColorsManager.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: !message.isSentByMe
                      ? Border.all(color: ColorsManager.strokeColor, width: 0.5)
                      : null,
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: message.isSentByMe
                        ? Colors.white
                        : ColorsManager.titleText,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showChatOptions() {
    // Show chat options sheet
  }

  void _handleCameraPressed() {
    // Handle camera button press
  }

  void _handleMicPressed() {
    setState(() => _isRecording = !_isRecording);

    // Simulate recording for demo
    if (_isRecording) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _isRecording = false);
        }
      });
    }
  }

  void _handleAttachPressed() {
    // Handle attachment button press
  }

  void _handleMessageSent(String message) {
    // Handle message sending
    print('Message sent: $message');
  }
}
