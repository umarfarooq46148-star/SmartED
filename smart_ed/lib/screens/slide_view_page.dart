// lib/screens/slide_view_page.dart
import 'package:flutter/material.dart';
import 'notes_page.dart';
import '../widgets/global_fabs.dart';
import '../services/voice_assistant_mixin.dart';
import '../services/voice_command_parser.dart';

class SlideViewPage extends StatefulWidget {
  final int slideNumber;
  final String slideTitle;
  final Color courseColor;
  final int totalSlides;

  const SlideViewPage({
    super.key,
    required this.slideNumber,
    required this.slideTitle,
    required this.courseColor,
    required this.totalSlides,
  });

  @override
  State<SlideViewPage> createState() => _SlideViewPageState();
}

class _SlideViewPageState extends State<SlideViewPage>
    with SingleTickerProviderStateMixin, VoiceAssistantMixin {
  late TabController _tabController;
  late int currentSlide;

  @override
  Future<void> readPageContent() async {
    await voiceService.speak('Slide $currentSlide of ${widget.totalSlides}');
    await voiceService.speak(widget.slideTitle);
    await voiceService.speak(
        'You can say Next, Previous, or Read for Me to hear the slide content.');
  }

  @override
  Future<void> handlePageSpecificCommand(String command) async {
    final lowerCommand = command.toLowerCase();

    if (lowerCommand.contains('next') && currentSlide < widget.totalSlides) {
      await readAction('Moving to next slide');
      setState(() {
        currentSlide++;
      });
      await voiceService.speak('Slide $currentSlide');
      // Listening will restart automatically after speaking completes
    } else if (lowerCommand.contains('previous') && currentSlide > 1) {
      await readAction('Moving to previous slide');
      setState(() {
        currentSlide--;
      });
      await voiceService.speak('Slide $currentSlide');
      // Listening will restart automatically after speaking completes
    } else if (lowerCommand.contains('read') ||
        lowerCommand.contains('read for me')) {
      await readAction('Reading slide content');
      await voiceService.speak(widget.slideTitle);
      await voiceService.speak(
          'This is the slide content. In a real implementation, this would display the actual slide image or formatted content.');
      // Listening will restart automatically after speaking completes
    } else {
      await super.handlePageSpecificCommand(command);
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    currentSlide = widget.slideNumber;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Slide $currentSlide of ${widget.totalSlides}'),
        backgroundColor: widget.courseColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.note),
            tooltip: 'Notes',
            onPressed: () async {
              await readNavigation('Notes Page');
              if (mounted && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        NotesPage(courseName: 'Slide ${widget.slideNumber}'),
                  ),
                );
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.slideshow), text: 'Slides'),
            Tab(icon: Icon(Icons.headphones), text: 'Audio'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSlideView(),
                _buildAudioView(),
              ],
            ),
          ),
          _buildNavigationControls(),
        ],
      ),
      floatingActionButton:
          GlobalFABs(notesContextTitle: 'Slide $currentSlide'),
    );
  }

  Widget _buildSlideView() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.slideshow, size: 80, color: widget.courseColor),
            const SizedBox(height: 16),
            Text(
              widget.slideTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'This is the slide content. In a real implementation, this would display the actual slide image or formatted content.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioView() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.headphones, size: 100, color: widget.courseColor),
            const SizedBox(height: 16),
            const Text(
              'Audio Lecture',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Listen to audio explanation',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.replay_10),
                  iconSize: 40,
                  onPressed: () {},
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon:
                      Icon(Icons.play_circle_filled, color: widget.courseColor),
                  iconSize: 60,
                  onPressed: () {},
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.forward_10),
                  iconSize: 40,
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: currentSlide > 1
                ? () async {
                    await readAction('Previous slide');
                    setState(() {
                      currentSlide--;
                    });
                    await voiceService.speak('Slide $currentSlide');
                  }
                : null,
            icon: const Icon(Icons.skip_previous),
            label: const Text('Previous'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await readAction('Reading slide content');
              await voiceService.speak(widget.slideTitle);
              await voiceService.speak(
                  'This is the slide content. In a real implementation, this would display the actual slide image or formatted content.');
            },
            icon: const Icon(Icons.volume_up),
            label: const Text('Read for Me'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.courseColor,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: currentSlide < widget.totalSlides
                ? () async {
                    await readAction('Next slide');
                    setState(() {
                      currentSlide++;
                    });
                    await voiceService.speak('Slide $currentSlide');
                  }
                : null,
            icon: const Icon(Icons.skip_next),
            label: const Text('Next'),
          ),
        ],
      ),
    );
  }
}
