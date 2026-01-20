import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../widgets/global_fabs.dart';

class OCRReaderPage extends StatefulWidget {
  const OCRReaderPage({super.key});

  @override
  State<OCRReaderPage> createState() => _OCRReaderPageState();
}

class _OCRReaderPageState extends State<OCRReaderPage> {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  String _extractedText = '';
  bool _isProcessing = false;
  File? _imageFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Reader'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _imageFile == null
                        ? const Icon(Icons.camera_alt,
                            size: 80, color: Colors.green)
                        : Image.file(_imageFile!, height: 200),
                    const SizedBox(height: 16),
                    const Text(
                      'Document Scanner',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Capture a document to extract text',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _captureImage,
                      icon: const Icon(Icons.camera),
                      label: const Text('Open Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_isProcessing)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Extracting text...'),
                    ],
                  ),
                ),
              ),
            if (_extractedText.isNotEmpty)
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Extracted Text',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      Text(
                        _extractedText,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: const GlobalFABs(notesContextTitle: 'OCR Reader'),
    );
  }

  /// 📸 Capture image using camera
  Future<void> _captureImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

    if (photo == null) return;

    setState(() {
      _imageFile = File(photo.path);
      _isProcessing = true;
      _extractedText = '';
    });

    await _performOCR(photo.path);
  }

  /// 🔍 Perform OCR
  Future<void> _performOCR(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText =
        await _textRecognizer.processImage(inputImage);

    setState(() {
      _extractedText = recognizedText.text;
      _isProcessing = false;
    });
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }
}
