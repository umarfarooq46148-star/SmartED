import 'package:flutter/material.dart';
import '../models/quiz.dart';
import 'notes_page.dart';
import '../widgets/global_fabs.dart';
import '../services/voice_assistant_mixin.dart';
import '../services/voice_command_parser.dart';

class QuizPage extends StatefulWidget {
  final String courseName;
  final int chapterNumber;

  const QuizPage({
    super.key,
    required this.courseName,
    required this.chapterNumber,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with VoiceAssistantMixin {
  int _currentQuestion = 0;
  int _score = 0;
  int? _selectedAnswer;
  bool _quizCompleted = false;

  late List<Quiz> _questions;

  @override
  Future<void> readPageContent() async {
    if (_quizCompleted) {
      await voiceService.speak('Quiz completed');
      await voiceService.speak('Your score is $_score out of ${_questions.length}');
      await voiceService.speak('${((_score / _questions.length) * 100).toStringAsFixed(0)} percent');
    } else {
      await voiceService.speak('Quiz Page');
      await voiceService.speak('Question ${_currentQuestion + 1} of ${_questions.length}');
      await voiceService.speak(_questions[_currentQuestion].question);
      for (int i = 0; i < _questions[_currentQuestion].options.length; i++) {
        await voiceService.speak('Option ${i + 1}: ${_questions[_currentQuestion].options[i]}');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _questions = [
      Quiz(
        question: 'What is the capital of Pakistan?',
        options: ['Karachi', 'Lahore', 'Islamabad', 'Peshawar'],
        correctAnswer: 2,
      ),
      Quiz(
        question: 'What is 2 + 2?',
        options: ['3', '4', '5', '6'],
        correctAnswer: 1,
      ),
      Quiz(
        question: 'What is the largest planet in our solar system?',
        options: ['Earth', 'Mars', 'Jupiter', 'Saturn'],
        correctAnswer: 2,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_quizCompleted) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quiz Results'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.note),
              tooltip: 'Notes',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotesPage(
                        courseName:
                            '${widget.courseName} - Chapter ${widget.chapterNumber}'),
                  ),
                );
              },
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, size: 100, color: Colors.amber),
                const SizedBox(height: 24),
                const Text(
                  'Quiz Completed!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Your Score: $_score/${_questions.length}',
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  '${((_score / _questions.length) * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Back to Chapter'),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: GlobalFABs(
          notesContextTitle:
              '${widget.courseName} - Chapter ${widget.chapterNumber}',
        ),
      );
    }

    final question = _questions[_currentQuestion];

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz - Chapter ${widget.chapterNumber}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.note),
            tooltip: 'Notes',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotesPage(
                      courseName:
                          '${widget.courseName} - Chapter ${widget.chapterNumber}'),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: (_currentQuestion + 1) / _questions.length,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 8),
            Text(
              'Question ${_currentQuestion + 1} of ${_questions.length}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Text(
              question.question,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            ...List.generate(
              question.options.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _selectedAnswer = index;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    side: BorderSide(
                      color:
                          _selectedAnswer == index ? Colors.blue : Colors.grey,
                      width: _selectedAnswer == index ? 2 : 1,
                    ),
                    backgroundColor: _selectedAnswer == index
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.white,
                  ),
                  child: Text(
                    question.options[index],
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _selectedAnswer == null ? null : _nextQuestion,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(
                _currentQuestion == _questions.length - 1
                    ? 'Submit'
                    : 'Next Question',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: GlobalFABs(
        notesContextTitle:
            '${widget.courseName} - Chapter ${widget.chapterNumber}',
      ),
    );
  }

  void _nextQuestion() {
    if (_selectedAnswer == _questions[_currentQuestion].correctAnswer) {
      setState(() {
        _score++;
      });
    }

    if (_currentQuestion < _questions.length - 1) {
      setState(() {
        _currentQuestion++;
        _selectedAnswer = null;
      });
    } else {
      setState(() {
        _quizCompleted = true;
      });
    }
  }
}
