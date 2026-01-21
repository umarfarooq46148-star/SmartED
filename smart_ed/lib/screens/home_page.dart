import 'package:flutter/material.dart';
import '../models/student.dart';
import '../models/course.dart';
import '../models/chapter.dart';
import '../widgets/ai_agent_panel.dart';
import '../widgets/global_fabs.dart';
import 'notes_page.dart';
import 'login_page.dart';
import 'course_detail_page.dart';
import 'ocr_reader_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _showAIAgent = false;

  final Student student = Student(
    name: 'Shaheryar Ashraf',
    rollNumber: '45417',
    className: '10th (SSC Part II)',
  );

  late List<Course> courses;

  @override
  void initState() {
    super.initState();
    _initializeCourses();
  }

  void _initializeCourses() {
    courses = [
      Course(
        name: 'Mathematics',
        totalChapters: 12,
        progress: 0.65,
        color: Colors.blue,
        chapters: List.generate(
          12,
          (i) => Chapter(
            number: i + 1,
            title: 'Chapter ${i + 1}: Topic Name',
            totalSlides: 15 + (i * 2),
            isCompleted: i < 7,
          ),
        ),
      ),
      Course(
        name: 'Physics',
        totalChapters: 10,
        progress: 0.45,
        color: Colors.red,
        chapters: List.generate(
          10,
          (i) => Chapter(
            number: i + 1,
            title: 'Chapter ${i + 1}: Topic Name',
            totalSlides: 15 + (i * 2),
            isCompleted: i < 4,
          ),
        ),
      ),
      Course(
        name: 'Chemistry',
        totalChapters: 11,
        progress: 0.80,
        color: Colors.green,
        chapters: List.generate(
          11,
          (i) => Chapter(
            number: i + 1,
            title: 'Chapter ${i + 1}: Topic Name',
            totalSlides: 15 + (i * 2),
            isCompleted: i < 8,
          ),
        ),
      ),
      Course(
        name: 'Biology',
        totalChapters: 9,
        progress: 0.30,
        color: Colors.orange,
        chapters: List.generate(
          9,
          (i) => Chapter(
            number: i + 1,
            title: 'Chapter ${i + 1}: Topic Name',
            totalSlides: 15 + (i * 2),
            isCompleted: i < 3,
          ),
        ),
      ),
      Course(
        name: 'English',
        totalChapters: 8,
        progress: 0.55,
        color: Colors.purple,
        chapters: List.generate(
          8,
          (i) => Chapter(
            number: i + 1,
            title: 'Chapter ${i + 1}: Topic Name',
            totalSlides: 15 + (i * 2),
            isCompleted: i < 4,
          ),
        ),
      ),
      Course(
        name: 'Urdu',
        totalChapters: 7,
        progress: 0.70,
        color: Colors.teal,
        chapters: List.generate(
          7,
          (i) => Chapter(
            number: i + 1,
            title: 'Chapter ${i + 1}: Topic Name',
            totalSlides: 15 + (i * 2),
            isCompleted: i < 5,
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.note),
            tooltip: 'My Notes',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const NotesPage(courseName: 'All Subjects'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: Row(
        children: [
          Expanded(
            flex: _showAIAgent ? 7 : 10,
            child: _buildMainContent(),
          ),
          if (_showAIAgent)
            Container(
              width: 350,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: const Border(
                  left: BorderSide(color: Colors.grey, width: 1),
                ),
              ),
              child: const AIAgentPanel(),
            ),
        ],
      ),
      floatingActionButton: const GlobalFABs(notesContextTitle: 'All Subjects'),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 35, color: Colors.blue),
                ),
                const SizedBox(height: 10),
                Text(
                  student.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Roll: ${student.rollNumber} | Class: ${student.className}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('My Courses'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('OCR Reader'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OCRReaderPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.note),
            title: const Text('My Notes'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.quiz),
            title: const Text('Quizzes'),
            onTap: () => Navigator.pop(context),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStudentInfo(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 24),
          _buildEnrolledCourses(),
        ],
      ),
    );
  }

  Widget _buildStudentInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Roll Number: ${student.rollNumber}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    'Class: ${student.className}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.volume_up, size: 30),
              onPressed: () {},
              tooltip: 'Read Aloud',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildActionCard(
          'OCR Reader',
          Icons.camera_alt,
          Colors.green,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OCRReaderPage(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnrolledCourses() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enrolled Courses',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return _buildCourseCard(course);
          },
        ),
      ],
    );
  }

  Widget _buildCourseCard(Course course) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailPage(course: course),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.book, color: course.color, size: 30),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      course.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${course.totalChapters} Chapters',
                    style: const TextStyle(color: Colors.grey),
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
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
