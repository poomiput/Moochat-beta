import 'dart:convert'; // สำหรับแปลง base64
import 'dart:typed_data'; // สำหรับจัดการ byte data

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart'; // สำหรับเลือกรูปจากแกลเลอรี่ & กล้อง
import 'package:location/location.dart';
import 'package:moochat/core/helpers/logger_debug.dart';
import 'package:moochat/core/helpers/shared_prefences.dart';
import 'package:moochat/core/theming/styles.dart';
import 'package:moochat/core/widgets/feature_unavailable_dialog.dart';
import 'package:moochat/core/widgets/loading_animation.dart';
import 'package:moochat/features/chat/data/enums/message_status.dart';
import 'package:moochat/features/chat/data/enums/message_type.dart';
import 'package:moochat/features/chat/data/models/chat_message_model.dart';

class AttachmentOptions extends StatefulWidget {
  const AttachmentOptions({
    super.key,
    this.onLocationSelected,
    this.onImageSelected, // เพิ่ม callback สำหรับส่งรูปภาพ
  });

  final Function(LocationData)? onLocationSelected;
  final Function(ChatMessage)?
  onImageSelected; // Callback เมื่อเลือกรูปเสร็จแล้ว

  @override
  State<AttachmentOptions> createState() => _AttachmentOptionsState();
}

class _AttachmentOptionsState extends State<AttachmentOptions> {
  LocationData? _location;
  bool _isLoading = false;

  void _getLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Location location = Location();

      bool serviceEnabled;
      PermissionStatus permissionGranted;

      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          setState(() {
            _isLoading = false;
          });
          // Show error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location service is disabled')),
            );
          }
          return;
        }
      }

      permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          setState(() {
            _isLoading = false;
          });
          // Show error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
      }

      _location = await location.getLocation();

      // Call the callback if provided
      widget.onLocationSelected?.call(_location!);

      // Close the bottom sheet and return the location data
      if (mounted) {
        Navigator.pop(context, _location);
      }
    } catch (e) {
      LoggerDebug.logger.e('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to get location')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 📸 ฟังก์ชันเลือกรูปจากแกลเลอรี่ (คลังรูป)
  Future<void> _pickImageFromGallery() async {
    try {
      // สร้างตัว ImagePicker เพื่อเปิดแกลเลอรี่
      final ImagePicker picker = ImagePicker();

      // เปิดแกลเลอรี่ให้ user เลือกรูป
      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.gallery, // เลือกจากแกลเลอรี่
        imageQuality: 70, // ลดคุณภาพรูปเหลือ 70% เพื่อประหยัดขนาดไฟล์
        maxWidth: 1024, // ขนาดสูงสุด 1024 pixels
        maxHeight: 1024, // ป้องกันไฟล์ใหญ่เกินไป
      );

      // ถ้า user ไม่เลือกรูป (กดยกเลิก) ให้หยุดทำงาน
      if (pickedImage == null) {
        LoggerDebug.logger.i('ผู้ใช้ยกเลิกการเลือกรูป');
        return;
      }

      LoggerDebug.logger.i('เลือกรูปสำเร็จ: ${pickedImage.path}');

      // เรียกฟังก์ชันแปลงรูปเป็นข้อความเพื่อส่ง
      await _processAndSendImage(pickedImage);
    } catch (e) {
      LoggerDebug.logger.e('เกิดข้อผิดพลาดในการเลือกรูป: $e');

      // แสดงข้อความแจ้งเตือนให้ผู้ใช้ทราบ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถเลือกรูปได้ กรุณาลองใหม่'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 📷 ฟังก์ชันถ่ายรูปด้วยกล้อง
  Future<void> _pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();

      // เปิดกล้องให้ user ถ่ายรูป
      final XFile? pickedImage = await picker.pickImage(
        source: ImageSource.camera, // เลือกจากกล้อง
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedImage == null) {
        LoggerDebug.logger.i('ผู้ใช้ยกเลิกการถ่ายรูป');
        return;
      }

      LoggerDebug.logger.i('ถ่ายรูปสำเร็จ: ${pickedImage.path}');

      // เรียกฟังก์ชันแปลงรูปเป็นข้อความเพื่อส่ง
      await _processAndSendImage(pickedImage);
    } catch (e) {
      LoggerDebug.logger.e('เกิดข้อผิดพลาดในการถ่ายรูป: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถถ่ายรูปได้ กรุณาลองใหม่'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🔄 ฟังก์ชันหลัก: แปลงรูปเป็นข้อมูลและส่ง
  Future<void> _processAndSendImage(XFile imageFile) async {
    try {
      LoggerDebug.logger.i('กำลังประมวลผลรูป...');

      // 1. อ่านไฟล์รูปเป็น bytes (ข้อมูลแบบ binary)
      final Uint8List imageBytes = await imageFile.readAsBytes();
      LoggerDebug.logger.i('ขนาดไฟล์: ${imageBytes.length} bytes');

      // 2. แปลง bytes เป็น base64 string (ข้อความที่สามารถส่งผ่าน Bluetooth ได้)
      final String base64Image = base64Encode(imageBytes);
      LoggerDebug.logger.i(
        'แปลง base64 สำเร็จ ขนาด: ${base64Image.length} ตัวอักษร',
      );

      // 3. ดึงข้อมูลผู้ใช้ปัจจุบันจาก SharedPreferences
      final String? myUsername = await SharedPrefHelper.getString('username');
      final String? myUUID = await SharedPrefHelper.getString('uuid');

      // 4. สร้างข้อความประเภทรูปภาพ
      final ChatMessage imageMessage = ChatMessage(
        text: base64Image, // ข้อมูลรูปในรูป base64 string
        type: MessageType.image, // ระบุว่าเป็นรูปภาพ (ไม่ใช่ข้อความธรรมดา)
        isSentByMe: true, // เราเป็นคนส่ง
        status: MessageStatus.sending, // สถานะ: กำลังส่ง
        username2P: myUsername ?? 'Unknown', // ชื่อผู้ส่ง
        uuid2P: myUUID ?? '', // ID ผู้ส่ง
      );

      LoggerDebug.logger.i('สร้างข้อความรูปสำเร็จ ID: ${imageMessage.id}');

      // 5. เรียก callback เพื่อส่งข้อความออกไป
      widget.onImageSelected?.call(imageMessage);

      // 6. ปิด bottom sheet เพราะทำงานเสร็จแล้ว
      if (mounted) {
        Navigator.pop(context);

        // แสดงข้อความแจ้งเตือนว่าส่งสำเร็จ
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('กำลังส่งรูปภาพ...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      LoggerDebug.logger.e('เกิดข้อผิดพลาดในการประมวลผลรูป: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถส่งรูปได้ กรุณาลองใหม่'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 📋 ฟังก์ชันแสดง Dialog เลือกแหล่งรูปภาพ
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900], // พื้นหลังมืดให้เข้าธีม
          title: const Text(
            '📸 เลือกแหล่งรูปภาพ',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ปุ่มเลือกจากแกลเลอรี่
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text(
                  'เลือกจากแกลเลอรี่',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'เลือกรูปที่มีอยู่ในเครื่อง',
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  Navigator.pop(context); // ปิด dialog
                  _pickImageFromGallery(); // เรียกฟังก์ชันเลือกจากแกลเลอรี่
                },
              ),

              const Divider(color: Colors.grey), // เส้นคั่น
              // ปุ่มถ่ายรูปใหม่
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text(
                  'ถ่ายรูปใหม่',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  'เปิดกล้องถ่ายรูปใหม่',
                  style: TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  Navigator.pop(context); // ปิด dialog
                  _pickImageFromCamera(); // เรียกฟังก์ชันถ่ายรูปใหม่
                },
              ),
            ],
          ),
          actions: [
            // ปุ่มยกเลิก
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: 40.w,
            height: 4.h,
            margin: EdgeInsets.only(bottom: 20.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          // Options
          ListTile(
            leading: const Icon(Icons.photo, color: Colors.white),
            title: Text(
              context.tr("photo"),
              style: CustomTextStyles.font16WhiteRegular,
            ),
            onTap: () {
              // 🎯 แสดง Dialog ให้เลือกแหล่งรูปภาพ
              _showImageSourceDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.videocam, color: Colors.white),
            title: Text(
              context.tr("video"),
              style: CustomTextStyles.font16WhiteRegular,
            ),
            onTap: () {
              FeatureUnavailableDialog.show(
                context,
                title: context.tr(
                  "feature_unavailable_send_video_message_title",
                ),
                description: context.tr(
                  "feature_unavailable_send_video_message_description",
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.attach_file, color: Colors.white),
            title: Text(
              context.tr("file"),
              style: CustomTextStyles.font16WhiteRegular,
            ),
            onTap: () {
              FeatureUnavailableDialog.show(
                context,
                title: context.tr(
                  "feature_unavailable_send_file_message_title",
                ),
                description: context.tr(
                  "feature_unavailable_send_file_message_description",
                ),
              );
            },
          ),
          ListTile(
            enabled: !_isLoading, // Disable tile when loading
            leading: _isLoading
                ? SizedBox(
                    width: 24.w,
                    height: 24.h,
                    child: const CustomLoadingAnimation(size: 30),
                  )
                : const Icon(Icons.location_on, color: Colors.white),
            title: Text(
              _isLoading
                  ? context.tr("getting_location")
                  : context.tr("location"),
              style: CustomTextStyles.font16WhiteRegular.copyWith(
                color: _isLoading
                    ? Colors.white.withOpacity(0.7)
                    : Colors.white,
              ),
            ),
            onTap: _isLoading ? null : _getLocation,
          ),
        ],
      ),
    );
  }
}
