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
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  String _extractedText = '';
  bool _isProcessing = false;
  File? _imageFile;

  bool _waitingForInputType = false;
  bool _waitingForSaveResponse = false;
  bool _waitingForReadConfirmation = false;

  final ScrollController _scrollController = ScrollController();

  // ==============================
  // 🌍 LANGUAGE DETECTION
  // ==============================
  String _detectLanguage(String text) {
    final arabicRegex = RegExp(r'[\u0600-\u06FF]');

    if (arabicRegex.hasMatch(text)) {
      return 'ar-SA';
    } else {
      return 'en-US';
    }
  }

  // ==============================
  // VOICE START
  // ==============================
  @override
  Future<void> readPageContent() async {
    await voiceService.speak('OCR Reader Page');
    await _askInputMethod();
  }

  @override
  Future<void> handlePageSpecificCommand(String command) async {
    final lower = command.toLowerCase();

    // ✅ READ CONFIRMATION
    if (_waitingForReadConfirmation) {
      _waitingForReadConfirmation = false;

      if (lower.contains('yes')) {
        await _readTextWithAutoScroll();
      } else {
        await voiceService.speak("Okay, not reading");
      }
      return;
    }

    // CAMERA / FILE
    if (_waitingForInputType) {
      _waitingForInputType = false;

      if (lower.contains('camera')) {
        await readAction('Opening camera');
        _openLiveCamera();
      } else if (lower.contains('file') || lower.contains('folder')) {
        await readAction('Opening file picker');
        _startFileFlow();
      } else {
        await voiceService.speak('Please say camera or file');
        _waitingForInputType = true;
      }
      return;
    }

    // SAVE RESPONSE
    if (_waitingForSaveResponse) {
      _waitingForSaveResponse = false;

      if (lower.contains('yes')) {
        await _saveText(_extractedText);
      } else {
        await voiceService.speak('Okay, document not saved');
      }
      return;
    }

    // EXTRA COMMANDS
    if (lower.contains('repeat')) {
      await _readTextWithAutoScroll();
      return;
    }

    if (lower.contains('save')) {
      await _saveText(_extractedText);
      return;
    }

    if (lower.contains('ocr') || lower.contains('scan')) {
      await _askInputMethod();
      return;
    }

    await super.handlePageSpecificCommand(command);
  }

  // ==============================
  Future<void> _askInputMethod() async {
    _waitingForInputType = true;

    await voiceService.speak(
        'Would you like to scan using the camera or open a file from your folder?');
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
  // FILE PICKER
  // ==============================
  Future<void> _startFileFlow() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result == null) {
      await voiceService.speak('No file selected');
      return;
    }

    final path = result.files.single.path!;

    setState(() {
      _imageFile = File(path);
      _isProcessing = true;
      _extractedText = '';
    });

    await voiceService.speak('File selected. Processing...');
    await _validateAndProcess(path);
  }

  // ==============================
  Future<void> _validateAndProcess(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    if (recognizedText.text.trim().isEmpty) {
      setState(() => _isProcessing = false);

      await voiceService
          .speak('This image is not suitable for OCR. Please try again.');

      await _askInputMethod();
      return;
    }

    await _processOCRResult(recognizedText.text);
  }

  // ==============================
  Future<void> _processOCRResult(String text) async {
    setState(() {
      _extractedText = text;
      _isProcessing = false;
    });

    String lang = _detectLanguage(text);
    await voiceService.setLanguage(lang);

    await voiceService.speak("Text extraction successful");

    if (lang == "ar-SA") {
      await voiceService.speak("هل تريد مني قراءة النص؟");
    } else {
      await voiceService.speak("Do you want me to read it?");
    }

    _waitingForReadConfirmation = true;
  }

  // ==============================
  Future<void> _readTextWithAutoScroll() async {
    if (_extractedText.isEmpty) return;

    await voiceService.stopListening();

    String lang = _detectLanguage(_extractedText);
    await voiceService.setLanguage(lang);

    List<String> parts = _extractedText.split(RegExp(r'[.؟!]'));

    for (int i = 0; i < parts.length; i++) {
      String sentence = parts[i].trim();
      if (sentence.isEmpty) continue;

      await voiceService.speak(sentence);

      double scrollPosition =
          (_scrollController.position.maxScrollExtent / parts.length) * i;

      _scrollController.animateTo(
        scrollPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }

    await voiceService.setLanguage("en-US");
    await voiceService.startListening();

    await _askToSave();
  }

  // ==============================
  Future<void> _askToSave() async {
    _waitingForSaveResponse = true;
    await voiceService.speak('Do you want to save this document?');
  }

  Future<void> _saveText(String text) async {
    if (text.isEmpty) return;

    final dir = await getApplicationDocumentsDirectory();
    final file =
        File('${dir.path}/ocr_${DateTime.now().millisecondsSinceEpoch}.txt');

    await file.writeAsString(text);

    await voiceService.speak('Document saved successfully');
  }

  // ==============================
  // UI
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
                    fontSize: 22,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            if (_extractedText.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _readTextWithAutoScroll,
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

  @override
  void dispose() {
    _scrollController.dispose();
    _textRecognizer.close();
    super.dispose();
  }
}
