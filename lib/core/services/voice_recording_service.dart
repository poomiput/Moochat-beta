import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:moochat/core/helpers/logger_debug.dart';

/// 🎙️ Voice Recording Service
/// คลาสนี้จัดการการบันทึกเสียง รวมถึงการขอ permission และการเก็บไฟล์เสียง
class VoiceRecordingService {
  static final VoiceRecordingService _instance =
      VoiceRecordingService._internal();
  factory VoiceRecordingService() => _instance;
  VoiceRecordingService._internal();

  // 📱 FlutterSoundRecorder instance สำหรับการบันทึกเสียง
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();

  // 🗂️ ตัวแปรสำหรับเก็บ path ของไฟล์ที่บันทึก
  String? _currentRecordingPath;

  // ⏱️ ตัวแปรสำหรับติดตามเวลาการบันทึก
  DateTime? _recordingStartTime;

  // 🎛️ ตัวแปรสำหรับติดตามสถานะการบันทึก
  bool _isRecording = false;

  // 🔧 ตัวแปรสำหรับตรวจสอบว่า initialized แล้วหรือยัง
  bool _isInitialized = false;

  /// 🔍 ตรวจสอบว่ากำลังบันทึกอยู่หรือไม่
  bool get isRecording => _isRecording;

  /// ⏰ ได้เวลาการบันทึกปัจจุบัน (วินาที)
  Duration? get recordingDuration {
    if (_recordingStartTime == null) return null;
    return DateTime.now().difference(_recordingStartTime!);
  }

  /// 🔐 ขอ permission สำหรับการใช้ microphone
  /// ต้องเรียกก่อนใช้งานการบันทึกเสียง
  Future<bool> requestPermission() async {
    try {
      LoggerDebug.logger.i('🎙️ Requesting microphone permission...');

      // ขอ permission สำหรับ microphone
      PermissionStatus status = await Permission.microphone.request();

      if (status == PermissionStatus.granted) {
        LoggerDebug.logger.i('✅ Microphone permission granted');
        return true;
      } else {
        LoggerDebug.logger.w('❌ Microphone permission denied: $status');
        return false;
      }
    } catch (e) {
      LoggerDebug.logger.e('💥 Error requesting microphone permission: $e');
      return false;
    }
  }

  /// 🎵 เริ่มการบันทึกเสียง
  /// return: ถ้าสำเร็จจะ return path ของไฟล์, ถ้าไม่สำเร็จจะ return null
  Future<String?> startRecording() async {
    try {
      LoggerDebug.logger.i('🎙️ Starting voice recording...');

      // Initialize หากยังไม่เคย
      if (!_isInitialized) {
        await _audioRecorder.openRecorder();
        _isInitialized = true;
      }

      // ตรวจสอบว่ามี permission หรือไม่
      bool hasPermission = await Permission.microphone.isGranted;
      if (!hasPermission) {
        hasPermission = await requestPermission();
        if (!hasPermission) {
          LoggerDebug.logger.e('❌ Cannot record without microphone permission');
          return null;
        }
      }

      // ตรวจสอบว่ากำลังบันทึกอยู่หรือไม่
      if (_isRecording) {
        LoggerDebug.logger.w(
          '⚠️ Already recording, stopping current recording first',
        );
        await stopRecording();
      }

      // สร้าง path สำหรับเก็บไฟล์เสียง
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String voiceDir = '${appDocDir.path}/voices';

      // สร้างโฟลเดอร์ถ้าไม่มี
      final Directory voiceDirObj = Directory(voiceDir);
      if (!await voiceDirObj.exists()) {
        await voiceDirObj.create(recursive: true);
        LoggerDebug.logger.i('📁 Created voice directory: $voiceDir');
      }

      // สร้างชื่อไฟล์โดยใช้ timestamp
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      _currentRecordingPath = '$voiceDir/voice_$timestamp.aac';

      // เริ่มบันทึกด้วย flutter_sound
      await _audioRecorder.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.aacMP4, // ใช้ AAC codec
        bitRate: 128000, // 128 kbps
        sampleRate: 44100, // 44.1 kHz
      );

      _isRecording = true;
      _recordingStartTime = DateTime.now();

      LoggerDebug.logger.i(
        '🎤 Recording started successfully: $_currentRecordingPath',
      );
      return _currentRecordingPath;
    } catch (e) {
      LoggerDebug.logger.e('💥 Error starting recording: $e');
      _isRecording = false;
      _recordingStartTime = null;
      _currentRecordingPath = null;
      return null;
    }
  }

  /// ⏹️ หยุดการบันทึกเสียง
  /// return: path ของไฟล์ที่บันทึกเสร็จ หรือ null ถ้าไม่สำเร็จ
  Future<String?> stopRecording() async {
    try {
      LoggerDebug.logger.i('⏹️ Stopping voice recording...');

      if (!_isRecording) {
        LoggerDebug.logger.w('⚠️ Not currently recording');
        return null;
      }

      // หยุดการบันทึก
      final String? path = await _audioRecorder.stopRecorder();

      _isRecording = false;
      final Duration? duration = recordingDuration;
      _recordingStartTime = null;

      if (path != null) {
        // ตรวจสอบว่าไฟล์มีอยู่จริงและมีขนาด
        final File file = File(path);
        if (await file.exists()) {
          final int fileSize = await file.length();
          LoggerDebug.logger.i(
            '✅ Recording saved successfully: $path (${fileSize} bytes, ${duration?.inSeconds}s)',
          );

          // รีเซ็ตตัวแปร
          final String recordedPath = _currentRecordingPath!;
          _currentRecordingPath = null;

          return recordedPath;
        } else {
          LoggerDebug.logger.e('💥 Recorded file does not exist: $path');
        }
      } else {
        LoggerDebug.logger.e('💥 Recording path is null');
      }

      _currentRecordingPath = null;
      return null;
    } catch (e) {
      LoggerDebug.logger.e('💥 Error stopping recording: $e');
      _isRecording = false;
      _recordingStartTime = null;
      _currentRecordingPath = null;
      return null;
    }
  }

  /// 🗑️ ยกเลิกการบันทึกและลบไฟล์
  Future<void> cancelRecording() async {
    try {
      LoggerDebug.logger.i('❌ Cancelling voice recording...');

      if (_isRecording) {
        await _audioRecorder.stopRecorder();
        _isRecording = false;
        _recordingStartTime = null;
      }

      // ลบไฟล์ที่บันทึกไว้ (ถ้ามี)
      if (_currentRecordingPath != null) {
        final File file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          LoggerDebug.logger.i(
            '🗑️ Deleted cancelled recording: $_currentRecordingPath',
          );
        }
        _currentRecordingPath = null;
      }
    } catch (e) {
      LoggerDebug.logger.e('💥 Error cancelling recording: $e');
      _isRecording = false;
      _recordingStartTime = null;
      _currentRecordingPath = null;
    }
  }

  /// 🧹 ทำความสะอาด resources
  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await cancelRecording();
      }
      if (_isInitialized) {
        await _audioRecorder.closeRecorder();
        _isInitialized = false;
      }
      LoggerDebug.logger.i('🧹 Voice recording service disposed');
    } catch (e) {
      LoggerDebug.logger.e('💥 Error disposing voice recording service: $e');
    }
  }

  /// 📊 ได้ขนาดไฟล์เสียงในรูปแบบ human-readable
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// ⏱️ ได้เวลาในรูปแบบ MM:SS
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 🧪 ตรวจสอบว่า device รองรับการบันทึกเสียงหรือไม่
  Future<bool> isRecordingAvailable() async {
    try {
      return await Permission.microphone.isGranted ||
          await Permission.microphone.request() == PermissionStatus.granted;
    } catch (e) {
      LoggerDebug.logger.e('💥 Error checking recording availability: $e');
      return false;
    }
  }

  /// 📁 ลบไฟล์เสียงทั้งหมดที่เก่า (เก็บแค่ 50 ไฟล์ล่าสุด)
  Future<void> cleanupOldVoiceFiles() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String voiceDir = '${appDocDir.path}/voices';
      final Directory voiceDirObj = Directory(voiceDir);

      if (await voiceDirObj.exists()) {
        final List<FileSystemEntity> files = voiceDirObj.listSync();

        // กรองเอาแต่ไฟล์เสียง และเรียงตาม modified time
        final List<File> voiceFiles =
            files
                .whereType<File>()
                .where((file) => file.path.endsWith('.m4a'))
                .toList()
              ..sort(
                (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
              );

        // เก็บแค่ 50 ไฟล์ล่าสุด
        if (voiceFiles.length > 50) {
          final filesToDelete = voiceFiles.skip(50);
          for (final file in filesToDelete) {
            await file.delete();
          }
          LoggerDebug.logger.i(
            '🧹 Cleaned up ${filesToDelete.length} old voice files',
          );
        }
      }
    } catch (e) {
      LoggerDebug.logger.e('💥 Error cleaning up old voice files: $e');
    }
  }
}
