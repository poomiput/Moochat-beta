import 'package:easy_localization/easy_localization.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gazachat/core/helpers/logger_debug.dart';
import 'package:gazachat/core/helpers/shared_prefences.dart';
import 'package:gazachat/core/theming/colors.dart';
import 'package:gazachat/core/theming/styles.dart';
import 'package:gazachat/core/widgets/feature_unavailable_dialog.dart';
import 'package:gazachat/features/chat/data/enums/message_status.dart';
import 'package:gazachat/features/chat/data/enums/message_type.dart';
import 'package:gazachat/features/chat/data/models/chat_message_model.dart';
import 'package:gazachat/features/chat/ui/widgets/attachment_options.dart';
import 'package:location/location.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomTextInputField extends ConsumerStatefulWidget {
  const CustomTextInputField({super.key, this.onSendMessage, this.uuid2P});
  final Function(ChatMessage chatMessage)? onSendMessage;
  final String? uuid2P;

  @override
  ConsumerState<CustomTextInputField> createState() =>
      _CustomTextInputFieldState();
}

class _CustomTextInputFieldState extends ConsumerState<CustomTextInputField> {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();

  bool _hasText = false;
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _textController.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _sendLocation(LocationData locationData) async {
    LoggerDebug.logger.i(
      'Location: Latitude: ${locationData.latitude}, Longitude: ${locationData.longitude}',
    );
    final myUUID = await SharedPrefHelper.getString('uuid');
    final myUsername = await SharedPrefHelper.getString('username');
    // call onSendMessage callback if provided
    final ChatMessage locationMessage = ChatMessage(
      text:
          'https://www.google.com/maps/search/?api=1&query=${locationData.latitude},${locationData.longitude}',
      isSentByMe: true,
      status: MessageStatus.delivered,
      type: MessageType.location,
      username2P: myUsername ?? 'Unknown',
      uuid2P: myUUID ?? '',
    );
    widget.onSendMessage!(locationMessage);
    // Create a message with the location data
  }

  void _sendMessage() async {
    if (_hasText) {
      final myUUID = await SharedPrefHelper.getString('uuid');
      final myUsername = await SharedPrefHelper.getString('username');
      final message = _textController.text.trim();
      // TODO: Add your send message logic here
      print('Sending message: $message');
      final ChatMessage chatMessage = ChatMessage(
        text: message,
        isSentByMe: true,
        status: MessageStatus.delivered,
        type: MessageType.text,
        username2P: myUsername ?? 'Unknown',
        uuid2P: myUUID ?? '',
      );
      // call function to handle sending message
      widget.onSendMessage?.call(chatMessage);

      // Clear the input field
      _textController.clear();

      // Remove focus and hide emoji picker
      //      _focusNode.unfocus();
      if (_showEmojiPicker) {
        setState(() {
          _showEmojiPicker = false;
        });
      }
    }
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
    });

    if (_showEmojiPicker) {
      // Hide keyboard when showing emoji picker
      _focusNode.unfocus();
    } else {
      // Show keyboard when hiding emoji picker
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Input field
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: ColorsManager.customGray.withOpacity(1),
            borderRadius: BorderRadius.circular(32.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: Row(
            children: [
              // Attachment button
              Container(
                margin: EdgeInsets.only(left: 4.w, right: 8.w),
                child: IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: Colors.white.withOpacity(0.7),
                    size: 24.sp,
                  ),
                  onPressed: () {
                    _showAttachmentOptions();
                  },
                  splashRadius: 24.r,
                ),
              ),
              // Text input field
              Expanded(
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: 20.h,
                    maxHeight: 120.h,
                  ),
                  child: TextField(
                    controller: _textController,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    cursorWidth: 2.5.w,
                    cursorColor: ColorsManager.whiteColor,
                    cursorRadius: Radius.circular(2.r),
                    cursorOpacityAnimates: true,
                    focusNode: _focusNode,
                    style: CustomTextStyles.font16WhiteRegular.copyWith(
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      hintText: context.tr("write_message"),
                      hintStyle: CustomTextStyles.font16WhiteRegular.copyWith(
                        color: Colors.white.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    onTap: () {
                      // Hide emoji picker when tapping on text field
                      if (_showEmojiPicker) {
                        setState(() {
                          _showEmojiPicker = false;
                        });
                      }
                    },
                  ),
                ),
              ),
              // Emoji button
              Container(
                margin: EdgeInsets.only(right: 4.w),
                child: IconButton(
                  icon: Icon(
                    _showEmojiPicker
                        ? Icons.keyboard
                        : Icons.emoji_emotions_outlined,
                    color: _showEmojiPicker
                        ? ColorsManager.customGreen
                        : Colors.white.withOpacity(0.7),
                    size: 24.sp,
                  ),
                  onPressed: _toggleEmojiPicker,
                  splashRadius: 24.r,
                ),
              ),
              // Voice/Send button with animation
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(left: 4.w, right: 4.w),
                decoration: BoxDecoration(
                  color: _hasText
                      ? ColorsManager.customGreen
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: _hasText
                      ? [
                          BoxShadow(
                            color: ColorsManager.customGreen.withOpacity(0.3),
                            blurRadius: 8.r,
                            offset: Offset(0, 2.h),
                          ),
                        ]
                      : [],
                ),
                child: IconButton(
                  icon: Icon(
                    _hasText ? Icons.send_rounded : Icons.mic,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                  onPressed: _hasText ? _sendMessage : _recordVoice,
                  splashRadius: 24.r,
                ),
              ),
            ],
          ),
        ),
        // Emoji Picker (Official API)
        if (_showEmojiPicker)
          SizedBox(
            height: 250.h,
            child: EmojiPicker(
              textEditingController: _textController,
              onBackspacePressed: () {
                // Handle backspace button press
                _textController
                  ..text = _textController.text.characters
                      .skipLast(1)
                      .toString()
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: _textController.text.length),
                  );
              },
              config: Config(
                height: 250.h,
                checkPlatformCompatibility: true,
                emojiViewConfig: EmojiViewConfig(
                  emojiSizeMax:
                      28.sp *
                      (foundation.defaultTargetPlatform ==
                              TargetPlatform.android
                          ? 1.20
                          : 1.0),
                  backgroundColor: ColorsManager.backgroundColor,
                  columns: 7,
                  verticalSpacing: 0,
                  horizontalSpacing: 0,
                  recentsLimit: 28,
                  replaceEmojiOnLimitExceed: false,
                  noRecents: Text(
                    'No Recents',
                    style: CustomTextStyles.font16WhiteRegular.copyWith(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 20.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  loadingIndicator: const SizedBox.shrink(),
                  buttonMode: ButtonMode.MATERIAL,
                ),
                viewOrderConfig: const ViewOrderConfig(
                  top: EmojiPickerItem.categoryBar,
                  middle: EmojiPickerItem.emojiView,
                  bottom: EmojiPickerItem.searchBar,
                ),
                skinToneConfig: SkinToneConfig(
                  dialogBackgroundColor: ColorsManager.backgroundColor,
                  indicatorColor: Colors.white.withOpacity(0.5),
                ),
                categoryViewConfig: CategoryViewConfig(
                  tabBarHeight: 46.h,
                  tabIndicatorAnimDuration: const Duration(milliseconds: 300),
                  initCategory: Category.RECENT,
                  backgroundColor: ColorsManager.backgroundColor,
                  indicatorColor: ColorsManager.customGreen,
                  iconColor: Colors.white.withOpacity(0.7),
                  iconColorSelected: ColorsManager.customGreen,
                  backspaceColor: ColorsManager.customGreen,
                  categoryIcons: const CategoryIcons(),
                  extraTab: CategoryExtraTab.NONE,
                ),
                bottomActionBarConfig: BottomActionBarConfig(
                  showBackspaceButton: true,
                  showSearchViewButton: true,
                  backgroundColor: ColorsManager.backgroundColor,
                  buttonColor: Colors.white.withOpacity(0.1),
                  buttonIconColor: Colors.white.withOpacity(0.7),
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor: ColorsManager.backgroundColor,
                  buttonIconColor: Colors.white.withOpacity(0.7),
                  hintText: 'Search emoji',
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showAttachmentOptions() {
    // Hide emoji picker when showing attachments
    if (_showEmojiPicker) {
      setState(() {
        _showEmojiPicker = false;
      });
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: ColorsManager.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) =>
          AttachmentOptions(onLocationSelected: _sendLocation),
    );
  }

  void _recordVoice() {
    // TODO: Implement voice recording
    FeatureUnavailableDialog.show(
      context,
      title: context.tr("feature_unavailable_send_voice_message_title"),
      description: context.tr(
        "feature_unavailable_send_voice_message_description",
      ),
    );
  }
}
