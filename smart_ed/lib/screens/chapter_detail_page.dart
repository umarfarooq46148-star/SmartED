import 'package:flutter/material.dart';
import '../models/chapter.dart';
import 'slide_view_page.dart';
import 'quiz_page.dart';
import 'notes_page.dart';
import '../widgets/global_fabs.dart';

class ChapterDetailPage extends StatelessWidget {
  final String courseName;
  final Chapter chapter;
  final Color courseColor;

  const ChapterDetailPage({
    super.key,
    required this.courseName,
    required this.chapter,
    required this.courseColor,
  });

  @override
  Widget build(BuildContext context) {
    final slides = List.generate(
      chapter.totalSlides,
      (index) => {
        'number': index + 1,
        'title': 'Slide ${index + 1}: Concept Explanation',
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Chapter ${chapter.number}'),
        backgroundColor: courseColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up),
            onPressed: () {},
            tooltip: 'Read Chapter',
          ),
          IconButton(
            icon: const Icon(Icons.note),
            tooltip: 'Notes',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      NotesPage(courseName: '$courseName - Chapter ${chapter.number}'),
                ),
              );
            },
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
                  Text(
                    chapter.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$courseName • ${slides.length} Slides',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SlideViewPage(
                                  slideNumber: 1,
                                  slideTitle: slides[0]['title'] as String,
                                  courseColor: courseColor,
                                  totalSlides: slides.length,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start Learning'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: courseColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QuizPage(
                                  courseName: courseName,
                                  chapterNumber: chapter.number,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.quiz),
                          label: const Text('Take Quiz'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Slides',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...slides.map((slide) => _buildSlideCard(
                context,
                slide['number'] as int,
                slide['title'] as String,
                slides.length,
              )),
        ],
      ),
      floatingActionButton:
          GlobalFABs(notesContextTitle: '$courseName - Chapter ${chapter.number}'),
    );
  }

  Widget _buildSlideCard(
      BuildContext context, int number, String title, int totalSlides) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: courseColor,
          child: Text(
            '$number',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.volume_up),
              onPressed: () {},
              tooltip: 'Read Slide',
            ),
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SlideViewPage(
                      slideNumber: number,
                      slideTitle: title,
                      courseColor: courseColor,
                      totalSlides: totalSlides,
                    ),
                  ),
                );
              },
              tooltip: 'View Slide',
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SlideViewPage(
                slideNumber: number,
                slideTitle: title,
                courseColor: courseColor,
                totalSlides: totalSlides,
              ),
            ),
          );
        },
      ),
    );
  }
}
