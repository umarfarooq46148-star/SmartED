import 'package:flutter/material.dart';
import '../screens/ai_chat_page.dart';
import '../screens/notes_page.dart';

class GlobalFABs extends StatelessWidget {
  final String notesContextTitle;

  const GlobalFABs({
    super.key,
    required this.notesContextTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: '${notesContextTitle}_voice',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Voice command activated')),
            );
          },
          backgroundColor: Colors.blue,
          child: const Icon(Icons.mic, color: Colors.white),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: '${notesContextTitle}_notes',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotesPage(courseName: notesContextTitle),
              ),
            );
          },
          backgroundColor: Colors.orange,
          child: const Icon(Icons.note, color: Colors.white),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: '${notesContextTitle}_ai',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AIChatPage()),
            );
          },
          backgroundColor: Colors.green,
          child: const Icon(Icons.smart_toy, color: Colors.white),
        ),
      ],
    );
  }
}

