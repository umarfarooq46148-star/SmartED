import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../widgets/global_fabs.dart';
import '../services/voice_assistant_mixin.dart';
import 'live_ocr_camera_page.dart';

class OCRReaderPage extends StatefulWidget {
  const OCRReaderPage({super.key});

  @override
  State<OCRReaderPage> createState() => _OCRReaderPageState();
}

class _OCRReaderPageState extends State<OCRReaderPage>
    with VoiceAssistantMixin {
  // ✅ FIX 1: safer ML Kit recognizer
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  String _extractedText = '';
  bool _isProcessing = false;
  bool _isReading = false; // ✅ FIX: guard against concurrent reads
  File? _imageFile;

  bool _waitingForInputType = false;
  bool _waitingForSaveResponse = false;
  bool _waitingForReadConfirmation = false;

  final ScrollController _scrollController = ScrollController();

  // ==============================
  // 🌍 LANGUAGE DETECTION (✅ FIX: added Urdu support)
  // ==============================
  String _detectLanguage(String text) {
    final arabicUrduRegex = RegExp(r'[\u0600-\u06FF\u0750-\u077F]');
    return arabicUrduRegex.hasMatch(text) ? 'ur-PK' : 'en-US';
  }

  // ==============================
  @override
  Future<void> readPageContent() async {
    await voiceService.speak('OCR Reader Page');
    await _askInputMethod();
  }

  @override
  Future<void> handlePageSpecificCommand(String command) async {
    final lower = command.toLowerCase();

    if (_waitingForInputType) {
      _waitingForInputType = false;

      if (lower.contains('camera')) {
        await voiceService.speak('Opening camera');
        _openLiveCamera();
      } else if (lower.contains('file')) {
        await voiceService.speak('Opening file picker');
        await _startFileFlow();
      } else {
        await voiceService.speak('Please say camera or file');
        _waitingForInputType = true;
      }
      return;
    }

    if (_waitingForReadConfirmation) {
      _waitingForReadConfirmation = false;

      if (lower.contains('yes')) {
        await _readTextWithAutoScroll();
      } else {
        await voiceService.speak("Okay, not reading");
      }
      return;
    }

    if (_waitingForSaveResponse) {
      _waitingForSaveResponse = false;

      if (lower.contains('yes')) {
        await _saveText(_extractedText);
      } else {
        await voiceService.speak('Document not saved');
      }
      return;
    }

    await super.handlePageSpecificCommand(command);
  }

  // ==============================
  Future<void> _askInputMethod() async {
    _waitingForInputType = true;
    await voiceService.speak('Scan using camera or open file from folder?');
  }

  void _openLiveCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LiveOCRCameraPage(),
      ),
    );
  }

  // ==============================
  // ✅ FIX 2: FilePicker corrected (CRASH FIX)
  // ==============================
  Future<void> _startFileFlow() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
      );
      if (result == null || result.files.single.path == null) {
        await voiceService.speak('No file selected');
        return;
      }

      final path = result.files.single.path!;

      setState(() {
        _imageFile = File(path);
        _isProcessing = true;
        _extractedText = '';
      });

      await voiceService.speak('Processing image...');
      await _validateAndProcess(path);
    } catch (e) {
      setState(() => _isProcessing = false);
      await voiceService.speak('File processing failed');
    }
  }

  // ==============================
  // ✅ FIX 3: ML KIT SAFE PROCESSING
  // ==============================
  Future<void> _validateAndProcess(String path) async {
    try {
      final inputImage = InputImage.fromFilePath(path);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.text.trim().isEmpty) {
        setState(() => _isProcessing = false);
        await voiceService.speak('No text found. Try another image.');
        return;
      }

      await _processOCRResult(recognizedText.text);
    } catch (e) {
      setState(() => _isProcessing = false);
      await voiceService.speak('OCR failed. Please try again.');
    }
  }

  // ==============================
  Future<void> _processOCRResult(String text) async {
    setState(() {
      _extractedText = text;
      _isProcessing = false;
    });

    final lang = _detectLanguage(text);
    await voiceService.setLanguage(lang);

    await voiceService.speak("Text extraction successful");

    await voiceService.speak(
      lang == "ur-PK"
          ? "کیا آپ متن پڑھنا چاہتے ہیں؟"
          : "Do you want me to read it?",
    );

    _waitingForReadConfirmation = true;
  }

  // ==============================
  // ✅ FIX 4: guard against concurrent reads
  // ==============================
  Future<void> _readTextWithAutoScroll() async {
    if (_extractedText.isEmpty || _isReading) return;
    _isReading = true;

    await voiceService.stopListening();

    final lang = _detectLanguage(_extractedText);
    await voiceService.setLanguage(lang);

    final parts = _extractedText.split(RegExp(r'[.؟!]'));

    for (int i = 0; i < parts.length; i++) {
      final sentence = parts[i].trim();
      if (sentence.isEmpty) continue;

      await voiceService.speak(sentence);

      if (_scrollController.hasClients) {
        final max = _scrollController.position.maxScrollExtent;
        final pos = (max / parts.length) * i;

        _scrollController.animateTo(
          pos,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }

    await voiceService.setLanguage("en-US");
    await voiceService.startListening();

    _isReading = false;
    await _askToSave();
  }

  Future<void> _askToSave() async {
    _waitingForSaveResponse = true;
    await voiceService.speak('Do you want to save this document?');
  }

  // ✅ FIX 5: error handling in _saveText
  Future<void> _saveText(String text) async {
    if (text.isEmpty) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/ocr_${DateTime.now().millisecondsSinceEpoch}.txt',
      );
      await file.writeAsString(text);
      await voiceService.speak('Document saved successfully');
    } catch (e) {
      await voiceService.speak('Failed to save document');
    }
  }

  // ==============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Reader'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_imageFile != null) Image.file(_imageFile!, height: 200),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openLiveCamera,
              icon: const Icon(Icons.camera),
              label: const Text("Scan with Camera"),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _startFileFlow,
              icon: const Icon(Icons.folder),
              label: const Text("Open from Folder"),
            ),
            const SizedBox(height: 20),
            if (_isProcessing) const CircularProgressIndicator(),
            if (_extractedText.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.black,
                child: Text(
                  _extractedText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            if (_extractedText.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _isReading ? null : _readTextWithAutoScroll,
                    child: const Text("Read"),
                  ),
                  ElevatedButton(
                    onPressed: () => _saveText(_extractedText),
                    child: const Text("Save"),
                  ),
                ],
              ),
          ],
        ),
      ),
      floatingActionButton: const GlobalFABs(notesContextTitle: 'OCR Reader'),
    );
  }

  // ✅ FIX 6: full dispose cleanup
  @override
  void dispose() {
    _scrollController.dispose();
    _textRecognizer.close();
    super.dispose();
  }
}
