import 'package:flutter/material.dart';
import 'course_detail_page.dart';
import '../models/course.dart';
import '../services/voice_assistant_service.dart';
import '../services/voice_command_parser.dart';

class SubjectModeSelectionPage extends StatefulWidget {
  final String subjectName;
  final Course course;

  const SubjectModeSelectionPage({
    super.key,
    required this.subjectName,
    required this.course,
  });

  @override
  State<SubjectModeSelectionPage> createState() =>
      _SubjectModeSelectionPageState();
}

class _SubjectModeSelectionPageState extends State<SubjectModeSelectionPage> {
  final VoiceAssistantService _voiceService = VoiceAssistantService();
  bool _voiceInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVoiceAssistant();
  }

  Future<void> _initializeVoiceAssistant() async {
    await _voiceService.initialize();
    _voiceService.setOnCommandRecognized(_handleVoiceCommand);

    if (mounted) {
      setState(() {
        _voiceInitialized = true;
      });

      // Start voice guidance automatically
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startVoiceGuidance();
      });
    }
  }

  Future<void> _startVoiceGuidance() async {
    if (!_voiceInitialized) return;

    // Read page title and question
    await _voiceService.speak(widget.subjectName);
    await _voiceService
        .speak('Do you want to study this subject as Graded or Ungraded?');
    await _voiceService.speak('Please speak your command.');

    // Start listening
    await _voiceService.startListening();
  }

  Future<void> _handleVoiceCommand(String command) async {
    await _voiceService.stopListening();

    // Check for back command
    if (VoiceCommandParser.isBackCommand(command)) {
      await _voiceService.speak('Going back to home page.');
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    // Check for graded/ungraded selection
    if (VoiceCommandParser.isGradedCommand(command)) {
      await _voiceService.speak('Graded mode selected');
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailPage(
              course: widget.course,
              isGraded: true,
            ),
          ),
        );
      }
    } else if (VoiceCommandParser.isUngradedCommand(command)) {
      await _voiceService.speak('Ungraded mode selected');
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailPage(
              course: widget.course,
              isGraded: false,
            ),
          ),
        );
      }
    } else {
      await _voiceService
          .speak('I did not understand. Please say Graded or Ungraded.');
      // Listening will restart automatically after speaking completes
    }
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectName),
        backgroundColor: widget.course.color,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school,
                size: 80,
                color: widget.course.color,
              ),
              const SizedBox(height: 32),
              Text(
                'Do you want to study this subject as Graded or Ungraded?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseDetailPage(
                          course: widget.course,
                          isGraded: true,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.course.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Graded',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CourseDetailPage(
                          course: widget.course,
                          isGraded: false,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: widget.course.color,
                    side: BorderSide(color: widget.course.color, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Ungraded',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
