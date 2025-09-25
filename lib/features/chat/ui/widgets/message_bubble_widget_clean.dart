import 'dart:convert';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/theming/styles.dart';
import 'package:moochat/core/services/audio_player_service.dart';
import 'package:moochat/features/chat/data/enums/message_status.dart';
import 'package:moochat/features/chat/data/enums/message_type.dart';
import 'package:moochat/features/chat/data/models/chat_message_model.dart';
import 'package:url_launcher/url_launcher.dart';

class MessageBubble extends StatefulWidget {
  MessageBubble({super.key, required this.message, this.isConsecutive = false});

  final bool isConsecutive;
  final ChatMessage message;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  late final bool isMe = widget.message.isSentByMe;
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  bool _isPlayingThisMessage = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer.initialize();
  }

  @override
  void dispose() {
    if (_isPlayingThisMessage) {
      _audioPlayer.stopPlayback();
    }
    super.dispose();
  }

  /// 🎵 เล่น/หยุดเสียง
  void _toggleAudioPlayback() async {
    try {
      if (_isPlayingThisMessage) {
        await _audioPlayer.stopPlayback();
        setState(() {
          _isPlayingThisMessage = false;
        });
      } else {
        setState(() {
          _isPlayingThisMessage = true;
        });

        final bool success = await _audioPlayer.playFromBase64(
          widget.message.text,
        );

        if (!success) {
          setState(() {
            _isPlayingThisMessage = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('ไม่สามารถเล่นเสียงได้'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          // Auto stop after 15 seconds (can be improved with actual duration)
          Future.delayed(const Duration(seconds: 15), () {
            if (mounted && _isPlayingThisMessage) {
              setState(() {
                _isPlayingThisMessage = false;
              });
            }
          });
        }
      }
    } catch (e) {
      setState(() {
        _isPlayingThisMessage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: widget.message.text));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('คัดลอกข้อความแล้ว')));
      },
      onTap: () {
        if (widget.message.type == MessageType.location) {
          _openLocation(widget.message.text);
        } else if (widget.message.type == MessageType.image) {
          _openImageFullScreen(context, widget.message.text);
        }
      },
      child: Container(
        margin: EdgeInsets.only(
          top: widget.isConsecutive ? 2.0 : 8.0,
          bottom: 2.0,
          left: isMe ? 60.0 : 8.0,
          right: isMe ? 8.0 : 60.0,
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!widget.isConsecutive)
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  isMe ? context.tr("me") : widget.message.username2P,
                  style: CustomTextStyles.font14WhiteRegular.copyWith(
                    color: ColorsManager.grayColor,
                    fontSize: 11.0,
                  ),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: isMe
                    ? ColorsManager.customBlue
                    : ColorsManager.customGray,
                borderRadius: _getBorderRadius(),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _buildMessageContent(context),
                  ),
                  if (isMe)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0, bottom: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _formatTime(widget.message.timestamp),
                            style: CustomTextStyles.font14WhiteRegular.copyWith(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10.0,
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          _buildMessageStatus(widget.message.status),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    // 🖼️ ถ้าเป็นรูปภาพ
    if (widget.message.type == MessageType.image) {
      try {
        final Uint8List imageBytes = base64Decode(widget.message.text);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.image, color: Colors.white, size: 20.0),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    "📸 รูปภาพ",
                    style: CustomTextStyles.font16WhiteRegular.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.memory(
                imageBytes,
                fit: BoxFit.cover,
                width: 200.0,
                height: 150.0,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200.0,
                    height: 150.0,
                    color: Colors.grey[800],
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.red, size: 30.0),
                        SizedBox(height: 8.0),
                        Text(
                          "รูปภาพเสียหาย",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              "แตะเพื่อดูขนาดเต็ม",
              style: CustomTextStyles.font16WhiteRegular.copyWith(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12.0,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        );
      } catch (e) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 20.0),
                const SizedBox(width: 8.0),
                Text(
                  "❌ รูปภาพเสียหาย",
                  style: CustomTextStyles.font16WhiteRegular.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4.0),
            Text(
              "ไม่สามารถแสดงรูปนี้ได้",
              style: CustomTextStyles.font16WhiteRegular.copyWith(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12.0,
              ),
            ),
          ],
        );
      }
    }
    // 📍 ถ้าเป็นตำแหน่ง
    else if (widget.message.type == MessageType.location) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white, size: 20.0),
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
          const SizedBox(height: 8.0),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              children: [
                const Icon(Icons.map, color: Colors.white, size: 40.0),
                const SizedBox(height: 8.0),
                Text(
                  "แตะเพื่อดูตำแหน่ง",
                  style: CustomTextStyles.font16WhiteRegular.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12.0,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    // 🎙️ ถ้าเป็นเสียง
    else if (widget.message.type == MessageType.voice) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header เสียง
          Row(
            children: [
              const Icon(Icons.mic, color: Colors.white, size: 20.0),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  "🎙️ ข้อความเสียง",
                  style: CustomTextStyles.font16WhiteRegular.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Simple voice message display - no waveform
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ปุ่ม Play/Pause
                GestureDetector(
                  onTap: _toggleAudioPlayback,
                  child: Container(
                    width: 40.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      color: _isPlayingThisMessage
                          ? Colors.white.withOpacity(0.3)
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Icon(
                      _isPlayingThisMessage ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 22.0,
                    ),
                  ),
                ),

                const SizedBox(width: 12.0),

                // Voice message info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isPlayingThisMessage ? "กำลังเล่น..." : "ข้อความเสียง",
                      style: CustomTextStyles.font16WhiteRegular.copyWith(
                        color: Colors.white,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      "กดเพื่อเล่น",
                      style: CustomTextStyles.font16WhiteRegular.copyWith(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }
    // 💬 ข้อความธรรมดา
    else {
      return Text(
        widget.message.text,
        style: CustomTextStyles.font16WhiteRegular.copyWith(
          color: Colors.white,
          height: 1.4,
        ),
      );
    }
  }

  BorderRadius _getBorderRadius() {
    if (widget.isConsecutive) {
      return BorderRadius.circular(12.0);
    }

    return BorderRadius.only(
      topLeft: const Radius.circular(16.0),
      topRight: const Radius.circular(16.0),
      bottomLeft: Radius.circular(isMe ? 16.0 : 6.0),
      bottomRight: Radius.circular(isMe ? 6.0 : 16.0),
    );
  }

  String _formatTime(DateTime timestamp) {
    return DateFormat.Hm().format(timestamp);
  }

  Widget _buildMessageStatus(MessageStatus status) {
    switch (status) {
      case MessageStatus.sent:
        return const Icon(Icons.check, color: Colors.white, size: 16.0);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, color: Colors.white, size: 16.0);
      case MessageStatus.read:
        return const Icon(Icons.done_all, color: Colors.blue, size: 16.0);
      case MessageStatus.sending:
        return const Icon(Icons.access_time, color: Colors.grey, size: 16.0);
    }
  }

  void _openImageFullScreen(BuildContext context, String base64Image) {
    try {
      final Uint8List imageBytes = base64Decode(base64Image);
      showDialog(
        context: context,
        barrierColor: Colors.black87,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.zero,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
                child: Center(
                  child: InteractiveViewer(
                    child: Image.memory(
                      imageBytes,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, color: Colors.red, size: 50.0),
                              SizedBox(height: 16.0),
                              Text(
                                "ไม่สามารถแสดงรูปภาพได้",
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถเปิดรูปภาพได้: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openLocation(String locationText) async {
    try {
      final Uri url = Uri.parse(locationText);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'ไม่สามารถเปิด $locationText';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเปิดตำแหน่งได้: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
