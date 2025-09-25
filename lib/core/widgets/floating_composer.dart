import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:moochat/core/theming/colors.dart';
import 'package:easy_localization/easy_localization.dart';

/// Floating docked composer card with minimal glyph buttons
class FloatingComposer extends StatefulWidget {
  final VoidCallback? onCameraPressed;
  final VoidCallback? onMicPressed;
  final VoidCallback? onAttachPressed;
  final Function(String)? onMessageSent;
  final bool isRecording;

  const FloatingComposer({
    super.key,
    this.onCameraPressed,
    this.onMicPressed,
    this.onAttachPressed,
    this.onMessageSent,
    this.isRecording = false,
  });

  @override
  State<FloatingComposer> createState() => _FloatingComposerState();
}

class _FloatingComposerState extends State<FloatingComposer>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  late AnimationController _pulseController;
  late AnimationController _expandController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _expandAnimation;

  bool _hasText = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _expandController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _expandAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeOutCubic),
    );

    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);

    if (widget.isRecording) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(FloatingComposer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    _pulseController.dispose();
    _expandController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _textController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _onFocusChanged() {
    final shouldExpand = _focusNode.hasFocus;
    if (shouldExpand != _isExpanded) {
      setState(() => _isExpanded = shouldExpand);
      if (shouldExpand) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseAnimation, _expandAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isRecording ? _pulseAnimation.value : 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: ColorsManager.cardColor,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: widget.isRecording
                      ? ColorsManager.primaryColor.withOpacity(0.3)
                      : ColorsManager.strokeColor,
                  width: widget.isRecording ? 1.5 : 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    offset: Offset(0, 8.h),
                    blurRadius: 24.r,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: Offset(0, 2.h),
                    blurRadius: 8.r,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Row(
                  children: [
                    // Action buttons (left side)
                    if (!_hasText && !widget.isRecording) ...[
                      _buildActionButton(
                        icon: Icons.camera_alt,
                        onPressed: widget.onCameraPressed,
                      ),
                      SizedBox(width: 8.w),
                      _buildActionButton(
                        icon: Icons.attach_file,
                        onPressed: widget.onAttachPressed,
                      ),
                      SizedBox(width: 12.w),
                    ],

                    // Text input field
                    Expanded(
                      child: Container(
                        constraints: BoxConstraints(
                          minHeight: 36.h,
                          maxHeight: _isExpanded ? 120.h : 36.h,
                        ),
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          textInputAction: TextInputAction.newline,
                          enabled: !widget.isRecording,
                          style: TextStyle(
                            color: ColorsManager.titleText,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w400,
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            hintText: widget.isRecording
                                ? context.tr('recording')
                                : context.tr('write_message'),
                            hintStyle: TextStyle(
                              color: ColorsManager.captionText,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 8.h,
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 12.w),

                    // Send/Mic button (right side)
                    GestureDetector(
                      onTap: _hasText ? _sendMessage : widget.onMicPressed,
                      child: Container(
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(
                          color: _hasText || widget.isRecording
                              ? ColorsManager.primaryColor
                              : ColorsManager.backgroundColor,
                          borderRadius: BorderRadius.circular(18.r),
                          border: !(_hasText || widget.isRecording)
                              ? Border.all(
                                  color: ColorsManager.strokeColor,
                                  width: 0.5,
                                )
                              : null,
                        ),
                        child: Icon(
                          _hasText ? Icons.send : Icons.mic,
                          color: _hasText || widget.isRecording
                              ? Colors.white
                              : ColorsManager.captionText,
                          size: 18.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 32.w,
        height: 32.w,
        decoration: BoxDecoration(
          color: ColorsManager.backgroundColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: ColorsManager.strokeColor.withOpacity(0.5),
            width: 0.5,
          ),
        ),
        child: Icon(icon, color: ColorsManager.captionText, size: 16.sp),
      ),
    );
  }

  void _sendMessage() {
    final message = _textController.text.trim();
    if (message.isNotEmpty) {
      widget.onMessageSent?.call(message);
      _textController.clear();
      _focusNode.unfocus();
    }
  }
}
