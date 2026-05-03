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

  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  bool _isCameraReady = false;
  bool _isCapturing = false;
  bool _isProcessing = false;

  Timer? _analysisTimer;

  String _lastMessage = '';
  String _extractedText = '';

  int _guidanceCount = 0;
  bool _waitingForCapture = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  Future<void> handlePageSpecificCommand(String command) async {
    final lower = command.toLowerCase();

    if (lower.contains("capture")) {
      if (_waitingForCapture) {
        await voiceService.speak("Capturing image");
        await _captureImage();
      } else {
        await voiceService.speak("Wait for clear text before capturing");
      }
      return;
    }

    if (lower.contains("repeat")) {
      if (_extractedText.isNotEmpty) {
        await voiceService.speak(_extractedText);
      }
      return;
    }

    if (lower.contains("save")) {
      await _saveText();
      return;
    }

    await super.handlePageSpecificCommand(command);
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.first;

    _cameraController = CameraController(
      backCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();

    setState(() => _isCameraReady = true);

    await voiceService.speak("Camera ready. Point at a document");

    voiceService.setKeepListening(true);
    await voiceService.startListening();

    _startLiveAnalysis();
  }

  void _startLiveAnalysis() {
    _analysisTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_isProcessing || _isCapturing) return;

      _isProcessing = true;

      try {
        final image = await _cameraController!.takePicture();
        final inputImage = InputImage.fromFilePath(image.path);

        final recognizedText = await _textRecognizer.processImage(inputImage);

        _analyzeText(recognizedText);
      } catch (e) {
        debugPrint("Analysis Error: $e");
      }

      _isProcessing = false;
    });
  }

  void _analyzeText(RecognizedText text) async {
    if (_waitingForCapture) return;

    if (text.text.trim().isEmpty) {
      _resetGuidance();
      await _speakOnce("No text found. Move camera to a document");
      return;
    }

    final block = text.blocks.first;
    final rect = block.boundingBox;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final centerX = rect.center.dx;
    final centerY = rect.center.dy;

    String direction = "";

    if (centerX < screenWidth * 0.4) {
      direction = "Move phone right";
    } else if (centerX > screenWidth * 0.6) {
      direction = "Move phone left";
    } else if (centerY < screenHeight * 0.4) {
      direction = "Move phone down";
    } else if (centerY > screenHeight * 0.6) {
      direction = "Move phone up";
    } else if (text.text.length < 25) {
      direction = "Move closer";
    }

    if (_guidanceCount < 3 && direction.isNotEmpty) {
      _guidanceCount++;
      await _speakOnce(direction);
      return;
    }

    if (!_waitingForCapture) {
      _waitingForCapture = true;

      await voiceService.speak("Text is clear. Say capture to scan");

      Future.delayed(const Duration(seconds: 3), () {
        _waitingForCapture = false;
        _guidanceCount = 0;
      });
    }
  }

  Future<void> _speakOnce(String message) async {
    if (message != _lastMessage) {
      _lastMessage = message;
      await voiceService.speak(message);
    }
  }

  void _resetGuidance() {
    _guidanceCount = 0;
    _waitingForCapture = false;
  }

  Future<void> _captureImage() async {
    if (_isCapturing) return;

    _isCapturing = true;
    _analysisTimer?.cancel();

    try {
      final image = await _cameraController!.takePicture();

      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.text.trim().isEmpty) {
        await voiceService.speak("No readable text found");
        _restart();
        return;
      }

      setState(() {
        _extractedText = recognizedText.text;
      });

      await voiceService.speak("Reading text");
      await voiceService.speak(recognizedText.text);
    } catch (e) {
      await voiceService.speak("Error capturing image");
    }

    _isCapturing = false;
  }

  Future<void> _saveText() async {
    if (_extractedText.isEmpty) return;

    final dir = await getApplicationDocumentsDirectory();
    final file =
        File('${dir.path}/ocr_${DateTime.now().millisecondsSinceEpoch}.txt');

    await file.writeAsString(_extractedText);

    await voiceService.speak("Document saved");
  }

  void _restart() {
    _isCapturing = false;
    _startLiveAnalysis();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart OCR Camera"),
        backgroundColor: Colors.green,
      ),
      body: _isCameraReady
          ? Column(
              children: [
                Expanded(
                  flex: 2,
                  child: CameraPreview(_cameraController!),
                ),
                Expanded(
                  flex: 1,
                  child: Container(
                    width: double.infinity,
                    color: Colors.black,
                    padding: const EdgeInsets.all(16),
                    child: _extractedText.isEmpty
                        ? const Text(
                            "Captured text will appear here",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          )
                        : SingleChildScrollView(
                            child: Text(
                              _extractedText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                          ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _captureImage,
                      child: const Text("Capture"),
                    ),
                    ElevatedButton(
                      onPressed: () => voiceService.speak(_extractedText),
                      child: const Text("Repeat"),
                    ),
                    ElevatedButton(
                      onPressed: _saveText,
                      child: const Text("Save"),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }
}
