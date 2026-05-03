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
  // Multi-script OCR. ML Kit ships no Urdu/Arabic recogniser, so we run
  // Latin and Devanagari in parallel and keep whichever returned text.
  // For real Urdu accuracy, swap in Tesseract or a cloud OCR here.
  final TextRecognizer _latinRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  // The enum constant is misspelled `devanagiri` in 0.13.x.
  final TextRecognizer _devanagariRecognizer =
      TextRecognizer(script: TextRecognitionScript.devanagiri);

  String _extractedText = '';
  String _detectedLang = 'en-US';
  bool _isProcessing = false;
  bool _isReading = false;
  File? _imageFile;

  bool _waitingForInputType = false;
  bool _waitingForSaveResponse = false;

  final ScrollController _scrollController = ScrollController();

  // ==============================
  // 🌍 LANGUAGE DETECTION — Urdu vs Arabic vs English
  // ==============================
  String _detectLanguage(String text) {
    if (text.trim().isEmpty) return 'en-US';

    // Arabic block + Arabic Supplement + Presentation Forms-A and -B
    final arabicRegex = RegExp(
        r'[؀-ۿݐ-ݿﭐ-﷿ﹰ-﻿]');
    // Glyphs that strongly indicate Urdu (rare in Arabic).
    final urduSpecific = RegExp(r'[ٹڈڑںھہۂۃیےۓ]');

    final arabicCount = arabicRegex.allMatches(text).length;
    final urduCount = urduSpecific.allMatches(text).length;
    final latinCount = RegExp(r'[A-Za-z]').allMatches(text).length;

    if (arabicCount > 0 && arabicCount >= latinCount) {
      return urduCount > 0 ? 'ur-PK' : 'ar-SA';
    }
    return 'en-US';
  }

  // ==============================
  @override
  Future<void> readPageContent() async {
    await voiceService.speak(
        'OCR Reader. Say camera to scan with the camera, or say open document to choose a file.');
    await _askInputMethod();
  }

  @override
  Future<void> handlePageSpecificCommand(String command) async {
    final lower = command.toLowerCase().trim();

    // While we're waiting for "scan / file?" answer
    if (_waitingForInputType) {
      if (_isCameraCommand(lower)) {
        _waitingForInputType = false;
        await voiceService.speak('Opening camera');
        _openLiveCamera();
        return;
      }
      if (_isOpenDocumentCommand(lower)) {
        _waitingForInputType = false;
        await voiceService.speak('Opening file picker');
        await _startFileFlow();
        return;
      }
      // Fall through if neither — keep listening
    }

    // While we're waiting for "save?" answer
    if (_waitingForSaveResponse) {
      _waitingForSaveResponse = false;
      if (_isAffirmative(lower)) {
        await _saveText(_extractedText);
      } else {
        await voiceService.speak('Document not saved');
      }
      return;
    }

    // Standalone commands available any time
    if (_isReadCommand(lower)) {
      if (_extractedText.isEmpty) {
        await voiceService.speak(
            'There is no text to read. Open a document or scan with the camera first');
      } else {
        await _readTextWithAutoScroll();
      }
      return;
    }

    if (lower.contains('stop') && _isReading) {
      _isReading = false;
      await voiceService.stopSpeaking();
      await voiceService.speak('Stopped');
      return;
    }

    if (lower.contains('save')) {
      await _saveText(_extractedText);
      return;
    }

    if (_isOpenDocumentCommand(lower)) {
      await _startFileFlow();
      return;
    }

    if (_isCameraCommand(lower)) {
      _openLiveCamera();
      return;
    }

    if (lower.contains('ocr') || lower.contains('scan')) {
      await _askInputMethod();
      return;
    }

    await super.handlePageSpecificCommand(command);
  }

  // --- Voice command synonyms (intentionally generous) ---

  bool _isAffirmative(String c) =>
      c.contains('yes') ||
      c.contains('yeah') ||
      c.contains('yep') ||
      c.contains('sure') ||
      c.contains('okay') ||
      c == 'ok' ||
      c.contains('go ahead') ||
      c.contains('please do');

  bool _isCameraCommand(String c) =>
      c.contains('camera') ||
      c.contains('scan with camera') ||
      c.contains('use camera') ||
      c.contains('take photo') ||
      c.contains('take picture');

  bool _isOpenDocumentCommand(String c) =>
      c.contains('open document') ||
      c.contains('open the document') ||
      c.contains('open file') ||
      c.contains('load file') ||
      c.contains('load document') ||
      c.contains('open folder') ||
      c.contains('from folder') ||
      c.contains('pick file') ||
      c.contains('choose file') ||
      (c.contains('file') && c.contains('open')) ||
      c == 'load' ||
      c == 'document' ||
      c == 'file' ||
      c == 'open';

  bool _isReadCommand(String c) =>
      c == 'read' ||
      c == 'read it' ||
      c == 'read again' ||
      c == 'read aloud' ||
      c == 'read the text' ||
      c == 'read out loud' ||
      c == 'speak' ||
      c == 'speak it' ||
      c == 'repeat' ||
      c.contains('read this') ||
      c.contains('read me') ||
      c.contains('read the document');

  // ==============================
  Future<void> _askInputMethod() async {
    _waitingForInputType = true;
    await voiceService.speak(
        'Would you like to scan with the camera, or open a document from your folder? Say camera, or say open document.');
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
  // FILE PICKER — robust, with explicit feedback at each step
  // ==============================
  Future<void> _startFileFlow() async {
    try {
      await voiceService.speak('Opening file picker');
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.image,
      );
      if (result == null ||
          result.files.isEmpty ||
          result.files.single.path == null) {
        await voiceService.speak('No file selected');
        return;
      }

      final path = result.files.single.path!;

      if (mounted) {
        setState(() {
          _imageFile = File(path);
          _isProcessing = true;
          _extractedText = '';
        });
      }

      await voiceService.speak('Reading text from the image, please wait');
      await _validateAndProcess(path);
    } catch (e) {
      debugPrint('File picker error: $e');
      if (mounted) setState(() => _isProcessing = false);
      await voiceService.speak('Could not open the file picker');
    }
  }

  // ==============================
  // OCR — multi-script, robust
  // ==============================
  Future<void> _validateAndProcess(String path) async {
    try {
      final inputImage = InputImage.fromFilePath(path);

      // Run both recognisers in parallel — Devanagari sometimes
      // catches characters Latin doesn't, and vice versa.
      final results = await Future.wait<RecognizedText>([
        _latinRecognizer.processImage(inputImage).catchError((_) =>
            RecognizedText(text: '', blocks: const <TextBlock>[])),
        _devanagariRecognizer.processImage(inputImage).catchError((_) =>
            RecognizedText(text: '', blocks: const <TextBlock>[])),
      ]);

      final text = _pickBetterText(results[0].text, results[1].text);

      if (text.trim().isEmpty) {
        if (mounted) setState(() => _isProcessing = false);
        await voiceService.speak(
            'I could not read any text in this image. Note: Urdu pages may not be recognised by the offline OCR. Please try a clearer English picture, or scan with the camera.');
        return;
      }

      await _processOCRResult(text);
    } catch (e) {
      debugPrint('OCR error: $e');
      if (mounted) setState(() => _isProcessing = false);
      await voiceService.speak('OCR failed. Please try again.');
    }
  }

  // Prefer the longer non-empty text; if both have Arabic/Urdu glyphs,
  // pick whichever has more.
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

  // ==============================
  Future<void> _processOCRResult(String text) async {
    if (mounted) {
      setState(() {
        _extractedText = text;
        _detectedLang = _detectLanguage(text);
        _isProcessing = false;
      });
    }

    // Announce in English first, then auto-read in the detected
    // language. Asking "do you want me to read it?" wastes a step
    // for a blind user — they came here to be read to.
    await voiceService.setLanguage('en-US');
    if (_detectedLang.startsWith('ur')) {
      await voiceService.speak(
          'Text extracted in Urdu. Reading aloud now. Say stop to interrupt.');
    } else if (_detectedLang.startsWith('ar')) {
      await voiceService.speak(
          'Text extracted in Arabic. Reading aloud now. Say stop to interrupt.');
    } else {
      await voiceService.speak(
          'Text extracted successfully. Reading aloud now. Say stop to interrupt.');
    }

    await _readTextWithAutoScroll();
    await _askToSave();
  }

  // ==============================
  Future<void> _readTextWithAutoScroll() async {
    if (_extractedText.isEmpty || _isReading) return;
    _isReading = true;
    await voiceService.stopListening();

    // Pick the best available TTS voice for the detected script.
    String ttsLang;
    if (_detectedLang.startsWith('ur') || _detectedLang.startsWith('ar')) {
      ttsLang = await voiceService.bestUrduArabicLanguage();
    } else {
      ttsLang = _detectedLang;
    }
    await voiceService.setLanguage(ttsLang);

    // Split on Latin AND Urdu/Arabic punctuation so chunks line up.
    final parts = _extractedText
        .split(RegExp(r'(?<=[.!?؟۔])\s+|\n+'))
        .where((s) => s.trim().isNotEmpty)
        .toList();

    final total = parts.isEmpty ? 1 : parts.length;
    for (int i = 0; i < parts.length; i++) {
      if (!_isReading) break;
      final sentence = parts[i].trim();
      if (sentence.isEmpty) continue;

      await voiceService.speak(sentence);

      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (maxScroll > 0) {
          final pos = (maxScroll / total) * (i + 1);
          _scrollController.animateTo(
            pos,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      }
    }

    _isReading = false;
    await voiceService.setLanguage('en-US');
    voiceService.setKeepListening(true);
    await voiceService.startListening();
  }

  Future<void> _askToSave() async {
    _waitingForSaveResponse = true;
    await voiceService.speak('Do you want to save this document? Say yes or no.');
  }

  Future<void> _saveText(String text) async {
    if (text.isEmpty) {
      await voiceService.speak('Nothing to save');
      return;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/ocr_${DateTime.now().millisecondsSinceEpoch}.txt',
      );
      await file.writeAsString(text);
      await voiceService.speak('Document saved successfully');
    } catch (e) {
      debugPrint('Save error: $e');
      await voiceService.speak('Failed to save document');
    }
  }

  // ==============================
  @override
  Widget build(BuildContext context) {
    final isRtl =
        _detectedLang.startsWith('ur') || _detectedLang.startsWith('ar');
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    Image.file(_imageFile!, height: 200, fit: BoxFit.cover),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _openLiveCamera,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan with Camera'),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _startFileFlow,
              icon: const Icon(Icons.folder_open),
              label: const Text('Open Document'),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 20),
            if (_isProcessing)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            if (_extractedText.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _extractedText,
                  textDirection:
                      isRtl ? TextDirection.rtl : TextDirection.ltr,
                  style: const TextStyle(color: Colors.white, fontSize: 22),
                ),
              ),
            const SizedBox(height: 10),
            if (_extractedText.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isReading
                        ? () async {
                            _isReading = false;
                            await voiceService.stopSpeaking();
                          }
                        : _readTextWithAutoScroll,
                    icon: Icon(_isReading ? Icons.stop : Icons.volume_up),
                    label: Text(_isReading ? 'Stop' : 'Read'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _saveText(_extractedText),
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
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
    _latinRecognizer.close();
    _devanagariRecognizer.close();
    super.dispose();
  }
}
