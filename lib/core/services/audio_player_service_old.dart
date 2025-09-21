import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import '../helpers/logger_debug.dart';

/// 🔊 Service สำหรับเล่นเสียงจากไฟล์ที่บันทึกไว้
class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  // Flutter Sound Player instance
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();
  bool _isInitialized = false;
  bool _isPlaying = false;
  String? _currentPlayingFile;

  /// 🎵 เริ่มต้น service
  Future<void> initialize() async {
    try {
      if (!_isInitialized) {
        await _audioPlayer.openPlayer();
        _isInitialized = true;
        LoggerDebug.logger.i('🔊 Audio player initialized successfully');
      }
    } catch (e) {
      LoggerDebug.logger.e('💥 Error initializing audio player: $e');
    }
  }

  /// 🗑️ ทำความสะอาดเมื่อไม่ใช้
  Future<void> dispose() async {
    try {
      if (_isPlaying) {
        await stopPlayback();
      }
      if (_isInitialized) {
        await _audioPlayer.closePlayer();
        _isInitialized = false;
      }
      LoggerDebug.logger.i('🔊 Audio player disposed');
    } catch (e) {
      LoggerDebug.logger.e('💥 Error disposing audio player: $e');
    }
  }

  /// 🎵 เล่นเสียงจาก base64 string
  /// base64Audio: ข้อมูลเสียงใน format base64
  /// return: true ถ้าเล่นได้, false ถ้าเล่นไม่ได้
  Future<bool> playFromBase64(String base64Audio) async {
    try {
      LoggerDebug.logger.i('🎵 Starting to play audio from base64...');

      // Initialize หากยังไม่เคย
      if (!_isInitialized) {
        await initialize();
      }

      // หยุดการเล่นปัจจุบันก่อน (ถ้ามี)
      if (_isPlaying) {
        await stopPlayback();
      }

      // แปลง base64 เป็น bytes
      final Uint8List audioBytes = base64Decode(base64Audio);

      // สร้างไฟล์ชั่วคราวสำหรับเล่น
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath =
          '${tempDir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.aac';
      final File tempFile = File(tempPath);

      // เขียนข้อมูลเสียงลงไฟล์
      await tempFile.writeAsBytes(audioBytes);
      LoggerDebug.logger.i('🎵 Temporary audio file created: $tempPath');

      // เล่นไฟล์เสียง
      await _audioPlayer.startPlayer(
        fromURI: tempPath,
        codec: Codec.aacMP4,
        whenFinished: () {
          LoggerDebug.logger.i('🎵 Audio playback finished');
          _isPlaying = false;
          _currentPlayingFile = null;

          // ลบไฟล์ชั่วคราว
          _deleteTempFile(tempPath);
        },
      );

      _isPlaying = true;
      _currentPlayingFile = tempPath;

      LoggerDebug.logger.i('🎵 Audio playback started successfully');
      return true;
    } catch (e) {
      LoggerDebug.logger.e('💥 Error playing audio from base64: $e');
      return false;
    }
  }

  /// 🎵 เล่นเสียงจากไฟล์ path
  /// filePath: path ของไฟล์เสียง
  /// return: true ถ้าเล่นได้, false ถ้าเล่นไม่ได้
  Future<bool> playFromFile(String filePath) async {
    try {
      LoggerDebug.logger.i('🎵 Starting to play audio from file: $filePath');

      // Initialize หากยังไม่เคย
      if (!_isInitialized) {
        await initialize();
      }

      // หยุดการเล่นปัจจุบันก่อน (ถ้ามี)
      if (_isPlaying) {
        await stopPlayback();
      }

      // ตรวจสอบว่าไฟล์มีอยู่จริง
      if (!await File(filePath).exists()) {
        LoggerDebug.logger.e('❌ Audio file not found: $filePath');
        return false;
      }

      // เล่นไฟล์เสียง
      await _audioPlayer.startPlayer(
        fromURI: filePath,
        codec: Codec.aacMP4,
        whenFinished: () {
          LoggerDebug.logger.i('🎵 Audio playback finished');
          _isPlaying = false;
          _currentPlayingFile = null;
        },
      );

      _isPlaying = true;
      _currentPlayingFile = filePath;

      LoggerDebug.logger.i('🎵 Audio playback started successfully');
      return true;
    } catch (e) {
      LoggerDebug.logger.e('💥 Error playing audio from file: $e');
      return false;
    }
  }

  /// ⏸️ หยุดการเล่นเสียง
  Future<void> stopPlayback() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.stopPlayer();
        LoggerDebug.logger.i('⏸️ Audio playback stopped');

        // ลบไฟล์ชั่วคราวถ้ามี
        if (_currentPlayingFile != null &&
            _currentPlayingFile!.contains('temp_audio_')) {
          _deleteTempFile(_currentPlayingFile!);
        }
      }
      _isPlaying = false;
      _currentPlayingFile = null;
    } catch (e) {
      LoggerDebug.logger.e('💥 Error stopping audio playback: $e');
    }
  }

  /// ⏸️ Pause/Resume การเล่นเสียง
  Future<void> pauseResumePlayback() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pausePlayer();
        LoggerDebug.logger.i('⏸️ Audio playback paused');
      } else {
        await _audioPlayer.resumePlayer();
        LoggerDebug.logger.i('▶️ Audio playback resumed');
      }
    } catch (e) {
      LoggerDebug.logger.e('💥 Error pausing/resuming audio: $e');
    }
  }

  /// 🔍 ตรวจสอบว่ากำลังเล่นเสียงอยู่หรือไม่
  bool get isPlaying => _isPlaying;

  /// 🔍 ได้ path ของไฟล์ที่กำลังเล่น
  String? get currentPlayingFile => _currentPlayingFile;

  /// 🗑️ ลบไฟล์ชั่วคราว
  Future<void> _deleteTempFile(String filePath) async {
    try {
      final File file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        LoggerDebug.logger.i('🗑️ Temporary file deleted: $filePath');
      }
    } catch (e) {
      LoggerDebug.logger.e('💥 Error deleting temporary file: $e');
    }
  }

  /// 📊 ได้ duration ของไฟล์เสียงปัจจุบัน (ถ้าเล่นอยู่)
  /// return: duration ในรูปแบบ Duration หรือ null ถ้าไม่ได้เล่น
  Duration? get currentDuration {
    // Note: flutter_sound ไม่ได้มี built-in method สำหรับ duration
    // สามารถใช้ package อื่นเช่น just_audio สำหรับ feature นี้
    return null;
  }

  /// 📊 ได้ position ปัจจุบันของการเล่นเสียง
  /// return: position ในรูปแบบ Duration หรือ null ถ้าไม่ได้เล่น
  Duration? get currentPosition {
    // Note: flutter_sound ไม่ได้มี built-in method สำหรับ position
    // สามารถใช้ package อื่นเช่น just_audio สำหรับ feature นี้
    return null;
  }
}
