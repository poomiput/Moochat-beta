import 'dart:convert'; // เพิ่มสำหรับ decode base64
import 'dart:typed_data'; // เพิ่มสำหรับ Uint8List

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/theming/styles.dart';
import 'package:moochat/core/services/audio_player_service.dart'; // เพิ่มสำหรับเล่นเสียง
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
  bool _isPlayingThisMessage = false; // สถานะการเล่นของข้อความนี้

  @override
  void initState() {
    super.initState();
    _audioPlayer.initialize(); // Initialize audio player
  }

  @override
  void dispose() {
    // หยุดการเล่นถ้ากำลังเล่นข้อความนี้อยู่
    if (_isPlayingThisMessage) {
      _audioPlayer.stopPlayback();
    }
    super.dispose();
  }

  /// 🎵 เล่น/หยุดเสียง
  void _toggleAudioPlayback() async {
    try {
      if (_isPlayingThisMessage) {
        // ถ้ากำลังเล่นข้อความนี้อยู่ ให้หยุด
        await _audioPlayer.stopPlayback();
        setState(() {
          _isPlayingThisMessage = false;
        });
      } else {
        // ถ้ายังไม่เล่น ให้เริ่มเล่น
        setState(() {
          _isPlayingThisMessage = true;
        });

        // เล่นเสียงจาก base64
        final bool success = await _audioPlayer.playFromBase64(
          widget.message.text,
        );

        if (!success) {
          // เล่นไม่สำเร็จ
          setState(() {
            _isPlayingThisMessage = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('ไม่สามารถเล่นเสียงได้'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          // เล่นสำเร็จ รอให้จบแล้วอัพเดทสถานะ
          // หลังจาก 2-3 วินาทีจะหยุดเอง (หรือใช้ callback)
          Future.delayed(const Duration(seconds: 15), () {
            if (mounted) {
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
            content: Text('เกิดข้อผิดพลาดในการเล่นเสียง: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      // hide the ink splash effect
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,

      onLongPress: () {
        // Handle long press if needed
        // copy the message text to clipboard
        Clipboard.setData(ClipboardData(text: widget.message.text));
      },
      child: Container(
        margin: EdgeInsets.only(
          top: widget.isConsecutive ? 2.0 : 8.0,
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
            if (!widget.isConsecutive)
              Padding(
                padding: EdgeInsets.only(
                  left: isMe ? 0.0 : 16.0,
                  right: isMe ? 16.0 : 0.0,
                  bottom: 4.0,
                ),
                child: Text(
                  isMe ? context.tr("me") : widget.message.username2P,
                  style: CustomTextStyles.font16WhiteRegular.copyWith(
                    color: Colors.grey[600],
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            // Message bubble
            GestureDetector(
              onTap: () {
                // จัดการการแตะตาม type ของข้อความ
                if (widget.message.type == MessageType.location) {
                  _openLocation(widget.message.text);
                } else if (widget.message.type == MessageType.image) {
                  _openImageFullScreen(context, widget.message.text);
                }
                // ถ้าเป็น text ไม่ทำอะไร
              },
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
                          _formatTime(widget.message.timestamp),
                          style: CustomTextStyles.font16WhiteRegular.copyWith(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12.0,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 4.0),
                          _buildMessageStatus(widget.message.status),
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
    // 🖼️ ถ้าเป็นรูปภาพ
    if (widget.message.type == MessageType.image) {
      try {
        // แปลง base64 string กลับเป็น bytes
        final Uint8List imageBytes = base64Decode(widget.message.text);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header รูปภาพ
            Row(
              children: [
                Icon(Icons.image, color: Colors.white, size: 20.0),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    "📸 รูปภาพ", // หรือใช้ context.tr("image")
                    style: CustomTextStyles.font16WhiteRegular.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),

            // แสดงรูปภาพจริง
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.memory(
                imageBytes,
                fit: BoxFit.cover,
                width: 200.0, // ปรับขนาดตามต้องการ
                height: 150.0, // ปรับขนาดตามต้องการ
                errorBuilder: (context, error, stackTrace) {
                  // ถ้าแสดงรูปไม่ได้ให้แสดงข้อความ error
                  return Container(
                    width: 200.0,
                    height: 150.0,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                          size: 32.0,
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          "ไม่สามารถแสดงรูปได้",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 4.0),
            Text(
              "แตะเพื่อดูขนาดเต็ม", // หรือ context.tr("tap_to_view_full")
              style: CustomTextStyles.font16WhiteRegular.copyWith(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12.0,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        );
      } catch (e) {
        // ถ้า decode base64 ไม่ได้
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error, color: Colors.red, size: 20.0),
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
    }
    // 🎙️ ถ้าเป็นเสียง
    else if (widget.message.type == MessageType.voice) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header เสียง
          Row(
            children: [
              Icon(Icons.mic, color: Colors.white, size: 20.0),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  "🎙️ ข้อความเสียง", // หรือใช้ context.tr("voice_message")
                  style: CustomTextStyles.font16WhiteRegular.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),

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
          ],          const SizedBox(height: 8.0),

          // ปุ่ม Play/Pause และ duration
          Row(
            children: [
              // ปุ่ม Play/Pause
              GestureDetector(
                onTap: _toggleAudioPlayback,
                child: Container(
                  width: 36.0,
                  height: 36.0,
                  decoration: BoxDecoration(
                    color: _isPlayingThisMessage
                        ? Colors.white.withOpacity(0.4)
                        : Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                  child: Icon(
                    _isPlayingThisMessage ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 20.0,
                  ),
                ),
              ),

              const SizedBox(width: 12.0),

              // Duration (ตอนนี้ใส่ค่าตาย)
              Text(
                "0:15", // สามารถคำนวณจากไฟล์เสียงจริงได้
                style: CustomTextStyles.font16WhiteRegular.copyWith(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14.0,
                ),
              ),

              const Spacer(),

              // ข้อความสถานะ
              Text(
                _isPlayingThisMessage ? "� กำลังเล่น..." : "🎙️ กดเล่น",
                style: CustomTextStyles.font16WhiteRegular.copyWith(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12.0,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
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

  // 🖼️ ฟังก์ชันเปิดรูปภาพแบบเต็มจอ
  void _openImageFullScreen(BuildContext context, String base64Image) {
    try {
      // แปลง base64 เป็น bytes
      final Uint8List imageBytes = base64Decode(base64Image);

      // แสดง Dialog รูปขนาดเต็ม
      showDialog(
        context: context,
        barrierColor: Colors.black87, // สีพื้นหลังรอบ Dialog
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.all(16.0),
            child: Stack(
              children: [
                // รูปภาพขนาดเต็ม
                Center(
                  child: InteractiveViewer(
                    // ให้ zoom ได้
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Image.memory(
                        imageBytes,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200.0,
                            height: 200.0,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  color: Colors.white54,
                                  size: 48.0,
                                ),
                                const SizedBox(height: 16.0),
                                Text(
                                  "ไม่สามารถแสดงรูปได้",
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // ปุ่มปิด
                Positioned(
                  top: 16.0,
                  right: 16.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.close, color: Colors.white),
                      splashRadius: 20.0,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e) {
      // ถ้า decode ไม่ได้
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถเปิดรูปนี้ได้: $e'),
          backgroundColor: Colors.red,
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
