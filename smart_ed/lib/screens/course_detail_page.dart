import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/chapter.dart';
import '../services/voice_assistant_service.dart';
import '../services/voice_command_parser.dart';
import 'notes_page.dart';
import 'slide_view_page.dart';
import '../widgets/global_fabs.dart';

class CourseDetailPage extends StatefulWidget {
  final Course course;
  final bool isGraded;

  const CourseDetailPage({
    super.key,
    required this.course,
    this.isGraded = true,
  });

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
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

    // Read page title
    await _voiceService.speak(widget.course.name);

    // Read course info
    await _voiceService.speak(
        '${widget.course.totalChapters} chapters, ${widget.course.totalSlides} slides total. Progress: ${(widget.course.progress * 100).toInt()} percent complete.');

    // Mode-specific announcements
    if (widget.isGraded) {
      await _voiceService
          .speak('Graded mode. Quizzes and assessments are available.');
    } else {
      await _voiceService
          .speak('Ungraded mode. Quizzes are disabled in ungraded mode.');
    }

    // Read chapters
    String chaptersList = 'Available chapters: ';
    for (int i = 0; i < widget.course.chapters.length && i < 5; i++) {
      chaptersList += 'Chapter ${widget.course.chapters[i].number}, ';
    }
    if (widget.course.chapters.length > 5) {
      chaptersList += 'and ${widget.course.chapters.length - 5} more chapters.';
    }
    await _voiceService.speak(chaptersList);

    await _voiceService.speak('Please speak your command.');

    // Start listening
    await _voiceService.startListening();
  }

  Future<void> _handleVoiceCommand(String command) async {
    await _voiceService.stopListening();

    // Check for back command
    if (VoiceCommandParser.isBackCommand(command)) {
      await _voiceService.speak('Going back.');
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    // Check for quiz command (only if graded)
    if (VoiceCommandParser.isQuizCommand(command)) {
      if (widget.isGraded) {
        await _voiceService.speak('Starting quiz.');
        // TODO: Navigate to quiz page when implemented
      } else {
        await _voiceService.speak(
            'This action is not available in the selected mode. Quizzes are disabled in ungraded mode.');
        // Listening will restart automatically after speaking completes
        return;
      }
    }

    // Check for chapter navigation
    int? chapterNumber = VoiceCommandParser.extractChapterNumber(command);
    if (chapterNumber != null && VoiceCommandParser.isReadCommand(command)) {
      if (chapterNumber >= 1 &&
          chapterNumber <= widget.course.chapters.length) {
        Chapter selectedChapter = widget.course.chapters[chapterNumber - 1];
        await _voiceService.speak('Opening chapter $chapterNumber');

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SlideViewPage(
                slideNumber: selectedChapter.number,
                slideTitle: selectedChapter.title,
                courseColor: widget.course.color,
                totalSlides: selectedChapter.totalSlides,
              ),
            ),
          );
        }
        return;
      } else {
        await _voiceService.speak(
            'Chapter $chapterNumber not found. Available chapters are 1 to ${widget.course.chapters.length}.');
        await _voiceService.startListening();
        return;
      }
    }

    // Unknown command
    await _voiceService
        .speak('I did not understand. Please repeat your command.');
    // Listening will restart automatically after speaking completes
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
        title: Text(widget.course.name),
        backgroundColor: widget.course.color,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () {},
            tooltip: 'Read Course Info',
          ),
          IconButton(
            icon: const Icon(Icons.note_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      NotesPage(courseName: widget.course.name),
                ),
              );
            },
            tooltip: 'Course Notes',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.book, size: 40, color: widget.course.color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.course.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${widget.course.totalChapters} Chapters • ${widget.course.totalSlides} Slides Total',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Course Progress',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: widget.course.progress,
                    backgroundColor: Colors.grey[300],
                    valueColor:
                        AlwaysStoppedAnimation<Color>(widget.course.color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(widget.course.progress * 100).toInt()}% Complete',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (widget.isGraded) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.quiz),
                      label: const Text('Take Grand Quiz'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.course.color,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chapters',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...widget.course.chapters.map((chapter) => _buildChapterCard(
                context,
                chapter,
              )),
        ],
      ),
      floatingActionButton: GlobalFABs(notesContextTitle: widget.course.name),
    );
  }

  Widget _buildChapterCard(BuildContext context, Chapter chapter) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              chapter.isCompleted ? Colors.green : widget.course.color,
          child: chapter.isCompleted
              ? const Icon(Icons.check, color: Colors.white)
              : Text(
                  '${chapter.number}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        title: Text(
          chapter.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${chapter.totalSlides} Slides'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.volume_up),
              onPressed: () {},
              tooltip: 'Read Slide',
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SlideViewPage(
                slideNumber: chapter.number,
                slideTitle: chapter.title,
                courseColor: widget.course.color,
                totalSlides: chapter.totalSlides,
              ),
            ),
          );
        },
      ),
    );
  }
}
