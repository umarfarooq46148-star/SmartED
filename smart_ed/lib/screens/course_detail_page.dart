import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/chapter.dart';
import 'notes_page.dart';
import 'slide_view_page.dart';
import '../widgets/global_fabs.dart';

class CourseDetailPage extends StatelessWidget {
  final Course course;

  const CourseDetailPage({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(course.name),
        backgroundColor: course.color,
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
                  builder: (context) => NotesPage(courseName: course.name),
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
                      Icon(Icons.book, size: 40, color: course.color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${course.totalChapters} Chapters • ${course.totalSlides} Slides Total',
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
                    value: course.progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(course.color),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(course.progress * 100).toInt()}% Complete',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.quiz),
                    label: const Text('Take Grand Quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: course.color,
                      foregroundColor: Colors.white,
                    ),
                  ),
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
          ...course.chapters.map((chapter) => _buildChapterCard(
                context,
                chapter,
              )),
        ],
      ),
      floatingActionButton: GlobalFABs(notesContextTitle: course.name),
    );
  }

  Widget _buildChapterCard(BuildContext context, Chapter chapter) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: chapter.isCompleted ? Colors.green : course.color,
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
                courseColor: course.color,
                totalSlides: chapter.totalSlides,
              ),
            ),
          );
        },
      ),
    );
  }
}
