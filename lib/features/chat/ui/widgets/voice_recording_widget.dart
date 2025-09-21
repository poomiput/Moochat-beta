import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:moochat/core/theming/styles.dart';
import 'dart:async';

/// 🎙️ Voice Recording Widget
/// แสดง UI ขณะกำลังบันทึกเสียง รวมถึง timer, animation และปุ่ม cancel/send
class VoiceRecordingWidget extends StatefulWidget {
  const VoiceRecordingWidget({
    super.key,
    required this.onCancel,
    required this.onSend,
    this.maxDuration = const Duration(minutes: 5), // ความยาวสูงสุด 5 นาที
  });

  final VoidCallback onCancel; // เมื่อยกเลิกการบันทึก
  final VoidCallback onSend; // เมื่อต้องการส่งเสียง
  final Duration maxDuration; // ความยาวสูงสุดของการบันทึก

  @override
  State<VoiceRecordingWidget> createState() => _VoiceRecordingWidgetState();
}

class _VoiceRecordingWidgetState extends State<VoiceRecordingWidget>
    with TickerProviderStateMixin {
  // ⏱️ Timer สำหรับนับเวลาการบันทึก
  Timer? _timer;
  Duration _recordingDuration = Duration.zero;

  // 🎨 Animation controllers
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  // 🎯 สถานะการบันทึก
  // bool _isRecording = true; // ตอนนี้ยังไม่ได้ใช้ เก็บไว้สำหรับอนาคต

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startRecordingTimer();
  }

  /// 🎨 Initialize animations for recording UI
  void _initializeAnimations() {
    // Animation สำหรับ pulse effect ของไมค์
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animation สำหรับ wave effect
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    // เริ่ม animations
    _pulseController.repeat(reverse: true);
    _waveController.repeat(reverse: true);
  }

  /// ⏱️ เริ่มนับเวลาการบันทึก
  void _startRecordingTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _recordingDuration = Duration(seconds: timer.tick);

          // ตรวจสอบว่าเกินเวลาสูงสุดหรือไม่
          if (_recordingDuration >= widget.maxDuration) {
            _stopRecordingDueToMaxDuration();
          }
        });
      }
    });
  }

  /// ⏹️ หยุดการบันทึกเพราะเกินเวลาสูงสุด
  void _stopRecordingDueToMaxDuration() {
    if (mounted) {
      _timer?.cancel();
      // _isRecording = false; // ตอนนี้ยังไม่ได้ใช้
      // Auto send เมื่อเกินเวลาสูงสุด
      widget.onSend();
    }
  }

  /// ❌ ยกเลิกการบันทึก
  void _handleCancel() {
    _timer?.cancel();
    // _isRecording = false; // ตอนนี้ยังไม่ได้ใช้
    widget.onCancel();
  }

  /// ✅ ส่งเสียงที่บันทึกแล้ว
  void _handleSend() {
    _timer?.cancel();
    // _isRecording = false; // ตอนนี้ยังไม่ได้ใช้
    widget.onSend();
  }

  /// 🕒 แปลง Duration เป็น string format MM:SS
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        // 🌈 Gradient background สำหรับความสวยงาม
        gradient: LinearGradient(
          colors: [
            ColorsManager.customGreen.withOpacity(0.8),
            ColorsManager.customGreen.withOpacity(0.6),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(32.r),
        boxShadow: [
          BoxShadow(
            color: ColorsManager.customGreen.withOpacity(0.3),
            blurRadius: 12.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // 🗑️ ปุ่มยกเลิก (ขยะ)
          GestureDetector(
            onTap: _handleCancel,
            child: Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 24.sp,
              ),
            ),
          ),

          SizedBox(width: 16.w),

          // 🎙️ ไมค์กับ Animation
          Expanded(
            child: Row(
              children: [
                // Animated microphone icon
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Icon(Icons.mic, color: Colors.white, size: 28.sp),
                    );
                  },
                ),

                SizedBox(width: 12.w),

                // 🌊 Wave animation (สร้าง visual effect ขณะบันทึก)
                Expanded(
                  child: AnimatedBuilder(
                    animation: _waveAnimation,
                    builder: (context, child) {
                      return Container(
                        height: 40.h,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(20, (index) {
                            // สร้าง wave bars ที่มี animation
                            final double animationValue =
                                (_waveAnimation.value + (index * 0.05)) % 1.0;
                            final double barHeight =
                                8.h + (animationValue * 24.h);

                            return Container(
                              width: 3.w,
                              height: barHeight,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(2.r),
                              ),
                            );
                          }),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(width: 12.w),

                // ⏱️ Timer display
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Text(
                    _formatDuration(_recordingDuration),
                    style: CustomTextStyles.font16WhiteRegular.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 16.w),

          // ✅ ปุ่มส่ง (เฉพาะเมื่อบันทึกเกิน 1 วินาที)
          if (_recordingDuration.inSeconds >= 1)
            GestureDetector(
              onTap: _handleSend,
              child: Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: ColorsManager.customGreen,
                  size: 24.sp,
                ),
              ),
            )
          else
            // 🚫 แสดงข้อความให้บันทึกอย่างน้อย 1 วินาที
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(
                'บันทึกอีก ${1 - _recordingDuration.inSeconds}s',
                style: CustomTextStyles.font16WhiteRegular.copyWith(
                  fontSize: 12.sp,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
