import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

enum VoiceCommandType {
  navigate,
  select,
  action,
  input,
  unknown,
}

class VoiceCommand {
  final VoiceCommandType type;
  final String? target;
  final Map<String, dynamic>? params;

  VoiceCommand({
    required this.type,
    this.target,
    this.params,
  });
}

class VoiceAssistantService {
  static final VoiceAssistantService _instance =
      VoiceAssistantService._internal();
  factory VoiceAssistantService() => _instance;
  VoiceAssistantService._internal();

  final FlutterTts _tts = FlutterTts();
  late stt.SpeechToText _stt;

  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isInitialized = false;
  Function(String)? _onCommandRecognized;
  VoidCallback? _onListeningStarted;
  VoidCallback? _onListeningStopped;

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;

  bool _shouldKeepListening = true;

  Future<void> initialize() async {
    try {
      debugPrint('🎤 Initializing Voice Assistant Service...');

      // Request microphone permission first
      var status = await Permission.microphone.status;
      debugPrint('📱 Microphone permission status: $status');

      if (!status.isGranted) {
        debugPrint('📱 Requesting microphone permission...');
        status = await Permission.microphone.request();
        debugPrint('📱 Permission request result: $status');
      }

      if (!status.isGranted) {
        debugPrint('❌ Microphone permission denied');
        throw Exception('Microphone permission is required for voice commands');
      }

      // Initialize TTS
      debugPrint('🔊 Initializing Text-to-Speech...');
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setCompletionHandler(() {
        debugPrint('🔊 TTS completed');
        _isSpeaking = false;
        if (_shouldKeepListening) {
          _startListening();
        }
      });

      _tts.setErrorHandler((msg) {
        debugPrint('❌ TTS Error: $msg');
        _isSpeaking = false;
        if (_shouldKeepListening) {
          _startListening();
        }
      });

      // Initialize Speech Recognition
      debugPrint('🎙️ Initializing Speech Recognition...');
      _stt = stt.SpeechToText();

      _isInitialized = true;
      debugPrint('✅ Voice Assistant Service initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Voice Assistant: $e');
      rethrow;
    }
  }

  Future<void> speak(String text) async {
    try {
      debugPrint('🔊 Speaking: $text');
      if (_isSpeaking) {
        await _tts.stop();
      }
      _isSpeaking = true;
      await _tts.speak(text);
    } catch (e) {
      debugPrint('❌ Error speaking: $e');
      _isSpeaking = false;
    }
  }

  Future<void> stopSpeaking() async {
    if (_isSpeaking) {
      await _tts.stop();
      _isSpeaking = false;
      debugPrint('🔇 Speaking stopped');
    }
  }

  void setOnCommandRecognized(Function(String) callback) {
    _onCommandRecognized = callback;
    debugPrint('✅ Command recognized callback set');
  }

  void setOnListeningStarted(VoidCallback? callback) {
    _onListeningStarted = callback;
  }

  void setOnListeningStopped(VoidCallback? callback) {
    _onListeningStopped = callback;
  }

  Future<bool> startListening() async {
    if (_isListening || _isSpeaking) {
      debugPrint('⚠️ Already listening or speaking, skipping...');
      return false;
    }

    try {
      debugPrint('🎙️ Starting to listen...');

      bool available = await _stt.initialize(
        onError: (error) {
          debugPrint('❌ STT Error: ${error.errorMsg}');
          _isListening = false;
          _onListeningStopped?.call();
        },
        onStatus: (status) {
          debugPrint('📊 STT Status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
            _onListeningStopped?.call();

            // Automatically restart listening
            if (_shouldKeepListening && !_isSpeaking) {
              Future.delayed(const Duration(milliseconds: 800), () {
                if (_shouldKeepListening && !_isSpeaking && !_isListening) {
                  debugPrint('🔄 Auto-restarting listener...');
                  startListening();
                }
              });
            }
          } else if (status == 'listening') {
            _isListening = true;
            _onListeningStarted?.call();
            debugPrint('✅ Now listening for commands...');
          }
        },
      );

      if (!available) {
        debugPrint('❌ Speech recognition not available');
        return false;
      }

      await _stt.listen(
        onResult: (result) {
          debugPrint('📝 Result received - Final: ${result.finalResult}');
          if (result.finalResult) {
            String command = result.recognizedWords.toLowerCase().trim();
            debugPrint('✅ RECOGNIZED COMMAND: "$command"');
            _onCommandRecognized?.call(command);
          } else {
            debugPrint('👂 Partial: ${result.recognizedWords}');
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        cancelOnError: false,
        partialResults: true, // Enable partial results for debugging
        listenMode: stt.ListenMode.confirmation,
      );

      _isListening = true;
      _onListeningStarted?.call();
      debugPrint('✅ Listening started successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Error starting listener: $e');
      _isListening = false;
      return false;
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      try {
        await _stt.stop();
        _isListening = false;
        _onListeningStopped?.call();
        debugPrint('🛑 Listening stopped');
      } catch (e) {
        debugPrint('❌ Error stopping listener: $e');
      }
    }
  }

  Future<void> _startListening() async {
    if (_shouldKeepListening && !_isSpeaking && !_isListening) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (_shouldKeepListening && !_isSpeaking && !_isListening) {
        await startListening();
      }
    }
  }

  void setKeepListening(bool keepListening) {
    _shouldKeepListening = keepListening;
    debugPrint('🔄 Keep listening set to: $keepListening');
    if (!keepListening) {
      stopListening();
    } else if (!_isSpeaking && !_isListening) {
      startListening();
    }
  }

  Future<void> speakAndListen(String text) async {
    await stopListening();
    await speak(text);
  }

  void dispose() {
    debugPrint('🗑️ Disposing Voice Assistant Service');
    _shouldKeepListening = false;
    _tts.stop();
    _stt.stop();
    _isListening = false;
    _isSpeaking = false;
  }
}
