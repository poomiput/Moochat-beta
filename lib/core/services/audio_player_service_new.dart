import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import '../helpers/logger_debug.dart';

/// 🔊 Service สำหรับเล่นเสียงจากไฟล์ที่บันทึกไว้ (ใช้ just_audio)
class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  // Just Audio Player instance
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isInitialized = false;
  bool _isPlaying = false;
  String? _currentPlayingFile;

  /// 🎵 เริ่มต้น service
  Future<void> initialize() async {
    try {
      if (!_isInitialized) {
        // just_audio ไม่ต้อง initialize แยก เพียงแค่สร้าง instance
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
      await _audioPlayer.dispose();
      _isInitialized = false;
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

      // Set audio source และเล่น
      await _audioPlayer.setFilePath(tempPath);

      // Listen for completion
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          LoggerDebug.logger.i('🎵 Audio playback finished');
          _isPlaying = false;
          _currentPlayingFile = null;

          // ลบไฟล์ชั่วคราว
          _deleteTempFile(tempPath);
        }
      });

      // เล่นเสียง
      await _audioPlayer.play();

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

      // Set audio source และเล่น
      await _audioPlayer.setFilePath(filePath);

      // Listen for completion
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          LoggerDebug.logger.i('🎵 Audio playback finished');
          _isPlaying = false;
          _currentPlayingFile = null;
        }
      });

      // เล่นเสียง
      await _audioPlayer.play();

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
        await _audioPlayer.stop();
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
      if (_audioPlayer.playing) {
        await _audioPlayer.pause();
        LoggerDebug.logger.i('⏸️ Audio playback paused');
      } else {
        await _audioPlayer.play();
        LoggerDebug.logger.i('▶️ Audio playback resumed');
      }
    } catch (e) {
      LoggerDebug.logger.e('💥 Error pausing/resuming audio: $e');
    }
  }

  /// 🔍 ตรวจสอบว่ากำลังเล่นเสียงอยู่หรือไม่
  bool get isPlaying => _audioPlayer.playing && _isPlaying;

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

  /// 📊 ได้ duration ของไฟล์เสียงปัจจุบัน
  Duration? get currentDuration => _audioPlayer.duration;

  /// 📊 ได้ position ปัจจุบันของการเล่นเสียง
  Duration? get currentPosition => _audioPlayer.position;
}
