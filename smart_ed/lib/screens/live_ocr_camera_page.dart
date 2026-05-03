import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../services/voice_assistant_mixin.dart';

class LiveOCRCameraPage extends StatefulWidget {
  const LiveOCRCameraPage({super.key});

  @override
  State<LiveOCRCameraPage> createState() => _LiveOCRCameraPageState();
}

class _LiveOCRCameraPageState extends State<LiveOCRCameraPage>
    with VoiceAssistantMixin {
  CameraController? _cameraController;

  // Multi-script OCR (see OCRReaderPage for the same rationale).
  final TextRecognizer _latinRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  final TextRecognizer _devanagariRecognizer =
      TextRecognizer(script: TextRecognitionScript.devanagiri);

  bool _isCameraReady = false;
  bool _isCapturing = false;
  bool _isProcessing = false;
  bool _hasReadResult = false;

  Timer? _analysisTimer;

  String _lastMessage = '';
  String _extractedText = '';
  String _detectedLang = 'en-US';
  String _statusMessage = 'Initialising camera…';

  int _guidanceCount = 0;
  bool _waitingForCapture = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  Future<void> readPageContent() async {
    await voiceService.speak(
        'Smart OCR Camera. Point your phone at a document. I will guide you. Say capture to scan, or press the Capture button at any time.');
  }

  // 🎤 VOICE COMMANDS — generous synonyms so common phrasings all work.
  @override
  Future<void> handlePageSpecificCommand(String command) async {
    final lower = command.toLowerCase().trim();

    if (_isCaptureCommand(lower)) {
      // Manual capture works anytime — don't gate on `_waitingForCapture`.
      await voiceService.speak('Capturing now');
      await _captureImage();
      return;
    }

    if (_isReadCommand(lower)) {
      if (_extractedText.isNotEmpty) {
        await _speakExtractedText();
      } else {
        await voiceService.speak(
            'No text yet. Say capture to scan, or press the Capture button');
      }
      return;
    }

    if (lower.contains('save')) {
      await _saveText();
      return;
    }

    if (lower.contains('again') || lower.contains('rescan')) {
      await voiceService.speak('Restarting scan');
      _restart();
      return;
    }

    if (lower.contains('stop')) {
      await voiceService.stopSpeaking();
      return;
    }

    await super.handlePageSpecificCommand(command);
  }

  bool _isCaptureCommand(String c) =>
      c.contains('capture') ||
      c.contains('capture to scan') ||
      c.contains('scan now') ||
      c.contains('take photo') ||
      c.contains('take picture') ||
      c.contains('snap') ||
      c == 'click' ||
      c == 'shoot';

  bool _isReadCommand(String c) =>
      c == 'read' ||
      c == 'read it' ||
      c == 'read again' ||
      c == 'repeat' ||
      c.contains('read aloud') ||
      c.contains('read the text');

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _statusMessage = 'No camera found');
        await voiceService.speak('No camera found on this device');
        return;
      }
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      try {
        await _cameraController!.setFocusMode(FocusMode.auto);
        await _cameraController!.setExposureMode(ExposureMode.auto);
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _isCameraReady = true;
        _statusMessage = 'Camera ready. Point at a document';
      });

      voiceService.setKeepListening(true);
      _startLiveAnalysis();
    } catch (e) {
      debugPrint('Camera init error: $e');
      if (mounted) setState(() => _statusMessage = 'Camera error');
      await voiceService.speak('Could not start camera');
    }
  }

  // 🔍 LIVE ANALYSIS — runs every ~2s, gives spoken centring guidance.
  void _startLiveAnalysis() {
    _analysisTimer?.cancel();
    _analysisTimer =
        Timer.periodic(const Duration(milliseconds: 2000), (timer) async {
      if (!mounted ||
          _cameraController == null ||
          !_cameraController!.value.isInitialized ||
          _isProcessing ||
          _isCapturing ||
          _hasReadResult) {
        return;
      }

      _isProcessing = true;
      try {
        final XFile shot = await _cameraController!.takePicture();
        final inputImage = InputImage.fromFilePath(shot.path);

        // Multi-script in parallel — needed so Urdu pages still produce
        // bounding boxes (otherwise alignment guidance never speaks).
        final results = await Future.wait<RecognizedText>([
          _latinRecognizer.processImage(inputImage).catchError((_) =>
              RecognizedText(text: '', blocks: const <TextBlock>[])),
          _devanagariRecognizer.processImage(inputImage).catchError((_) =>
              RecognizedText(text: '', blocks: const <TextBlock>[])),
        ]);

        final blocks = <TextBlock>[
          ...results[0].blocks,
          ...results[1].blocks,
        ];
        final mergedText = results[0].text.length >= results[1].text.length
            ? results[0].text
            : results[1].text;

        await _analyzeFrame(blocks, mergedText);

        try {
          await File(shot.path).delete();
        } catch (_) {}
      } catch (e) {
        debugPrint('Analysis error: $e');
      } finally {
        _isProcessing = false;
      }
    });
  }

  Future<void> _analyzeFrame(List<TextBlock> blocks, String mergedText) async {
    if (_waitingForCapture || _hasReadResult) return;

    if (blocks.isEmpty) {
      _resetGuidance();
      await _speakOnce('No text detected. Move closer to the page');
      return;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Union of all blocks.
    Rect union = blocks.first.boundingBox;
    for (final b in blocks.skip(1)) {
      union = union.expandToInclude(b.boundingBox);
    }
    final centerX = union.center.dx;
    final centerY = union.center.dy;

    String direction = '';
    if (centerX < screenWidth * 0.4) {
      direction = 'Move phone slightly left';
    } else if (centerX > screenWidth * 0.6) {
      direction = 'Move phone slightly right';
    } else if (centerY < screenHeight * 0.4) {
      direction = 'Move phone down';
    } else if (centerY > screenHeight * 0.6) {
      direction = 'Move phone up';
    } else if (mergedText.length < 20) {
      direction = 'Move closer';
    }

    if (_guidanceCount < 3 && direction.isNotEmpty) {
      _guidanceCount++;
      await _speakOnce(direction);
      return;
    }

    if (!_waitingForCapture) {
      _waitingForCapture = true;
      if (mounted) {
        setState(() => _statusMessage = 'Text is clear — say "capture to scan"');
      }
      await voiceService.speak(
          'Text is clear and centred. Say capture to scan, or wait and I will capture for you');

      // Auto-capture fallback if user can't speak.
      Future.delayed(const Duration(seconds: 4), () async {
        if (!mounted ||
            !_waitingForCapture ||
            _isCapturing ||
            _hasReadResult) {
          return;
        }
        await voiceService.speak('Capturing now');
        await _captureImage();
      });
    }
  }

  Future<void> _speakOnce(String message) async {
    if (message != _lastMessage) {
      _lastMessage = message;
      if (mounted) setState(() => _statusMessage = message);
      await voiceService.speak(message);
    }
  }

  void _resetGuidance() {
    _guidanceCount = 0;
    _waitingForCapture = false;
  }

  // 📸 CAPTURE + multi-script OCR. Manual button-press goes through here too,
  // so it works regardless of the live-analysis state.
  Future<void> _captureImage() async {
    if (_isCapturing || _cameraController == null) return;
    _isCapturing = true;
    _waitingForCapture = false;
    _analysisTimer?.cancel();
    if (mounted) setState(() => _statusMessage = 'Processing image…');

    try {
      // Wait briefly for any in-flight analysis frame to finish.
      int wait = 0;
      while (_isProcessing && wait < 2000) {
        await Future.delayed(const Duration(milliseconds: 100));
        wait += 100;
      }

      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);

      final results = await Future.wait<RecognizedText>([
        _latinRecognizer.processImage(inputImage).catchError((_) =>
            RecognizedText(text: '', blocks: const <TextBlock>[])),
        _devanagariRecognizer.processImage(inputImage).catchError((_) =>
            RecognizedText(text: '', blocks: const <TextBlock>[])),
      ]);

      final text = _pickBetterText(results[0].text, results[1].text);

      if (text.trim().isEmpty) {
        await voiceService.speak(
            'No readable text found. Note: Urdu pages may not be recognised by the offline OCR. Trying again');
        _restart();
        return;
      }

      if (!mounted) return;
      setState(() {
        _extractedText = text;
        _detectedLang = _detectLanguage(text);
        _hasReadResult = true;
        _statusMessage = 'Text captured. Reading aloud…';
      });

      await voiceService.setLanguage('en-US');
      if (_detectedLang.startsWith('ur')) {
        await voiceService
            .speak('Text captured in Urdu. Reading now. Say stop to interrupt');
      } else if (_detectedLang.startsWith('ar')) {
        await voiceService.speak(
            'Text captured in Arabic. Reading now. Say stop to interrupt');
      } else {
        await voiceService
            .speak('Text captured. Reading now. Say stop to interrupt');
      }

      await _speakExtractedText();

      await voiceService.setLanguage('en-US');
      await voiceService.speak(
          'Say save to keep the document, again to scan another page, or back to leave');
    } catch (e) {
      debugPrint('Capture error: $e');
      await voiceService.speak('Error capturing image');
      _restart();
    } finally {
      _isCapturing = false;
    }
  }

  String _pickBetterText(String a, String b) {
    final aT = a.trim();
    final bT = b.trim();
    if (aT.isEmpty) return bT;
    if (bT.isEmpty) return aT;
    final arabic = RegExp(
        r'[؀-ۿݐ-ݿﭐ-﷿ﹰ-﻿]');
    final aArabic = arabic.allMatches(aT).length;
    final bArabic = arabic.allMatches(bT).length;
    if (bArabic > aArabic) return bT;
    if (aArabic > bArabic) return aT;
    return aT.length >= bT.length ? aT : bT;
  }

  String _detectLanguage(String text) {
    if (text.trim().isEmpty) return 'en-US';
    final arabicRegex = RegExp(
        r'[؀-ۿݐ-ݿﭐ-﷿ﹰ-﻿]');
    final urduSpecific = RegExp(r'[ٹڈڑںھہۂۃیےۓ]');
    final arabicCount = arabicRegex.allMatches(text).length;
    final urduCount = urduSpecific.allMatches(text).length;
    final latinCount = RegExp(r'[A-Za-z]').allMatches(text).length;
    if (arabicCount > 0 && arabicCount >= latinCount) {
      return urduCount > 0 ? 'ur-PK' : 'ar-SA';
    }
    return 'en-US';
  }

  Future<void> _speakExtractedText() async {
    if (_extractedText.isEmpty) return;
    String ttsLang;
    if (_detectedLang.startsWith('ur') || _detectedLang.startsWith('ar')) {
      ttsLang = await voiceService.bestUrduArabicLanguage();
    } else {
      ttsLang = _detectedLang;
    }
    await voiceService.setLanguage(ttsLang);

    final parts = _extractedText
        .split(RegExp(r'(?<=[.!?؟۔])\s+|\n+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      await voiceService.speak(_extractedText);
      return;
    }
    for (final s in parts) {
      await voiceService.speak(s.trim());
    }
  }

  Future<void> _saveText() async {
    if (_extractedText.isEmpty) {
      await voiceService.speak('Nothing to save');
      return;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
          '${dir.path}/ocr_${DateTime.now().millisecondsSinceEpoch}.txt');
      await file.writeAsString(_extractedText);
      await voiceService.speak('Document saved');
    } catch (e) {
      debugPrint('Save error: $e');
      await voiceService.speak('Could not save document');
    }
  }

  void _restart() {
    if (!mounted) return;
    setState(() {
      _isCapturing = false;
      _waitingForCapture = false;
      _hasReadResult = false;
      _guidanceCount = 0;
      _lastMessage = '';
      _statusMessage = 'Camera ready';
    });
    _startLiveAnalysis();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl =
        _detectedLang.startsWith('ur') || _detectedLang.startsWith('ar');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart OCR Camera'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: _isCameraReady
          ? Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Stack(
                    children: [
                      Positioned.fill(child: CameraPreview(_cameraController!)),
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _statusMessage,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    width: double.infinity,
                    color: Colors.black,
                    padding: const EdgeInsets.all(16),
                    child: _extractedText.isEmpty
                        ? const Text(
                            'Captured text will appear here',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          )
                        : SingleChildScrollView(
                            child: Text(
                              _extractedText,
                              textDirection: isRtl
                                  ? TextDirection.rtl
                                  : TextDirection.ltr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isCapturing ? null : _captureImage,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Capture'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _extractedText.isEmpty
                            ? null
                            : _speakExtractedText,
                        icon: const Icon(Icons.volume_up),
                        label: const Text('Read'),
                      ),
                      ElevatedButton.icon(
                        onPressed:
                            _extractedText.isEmpty ? null : _saveText,
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(_statusMessage),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _cameraController?.dispose();
    _latinRecognizer.close();
    _devanagariRecognizer.close();
    super.dispose();
  }
}
