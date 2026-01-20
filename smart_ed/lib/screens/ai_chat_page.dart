import 'package:flutter/material.dart';
import '../widgets/ai_agent_panel.dart';
import '../widgets/global_fabs.dart';

class AIChatPage extends StatelessWidget {
  const AIChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const AIAgentPanel(),
      floatingActionButton: const GlobalFABs(notesContextTitle: 'All Subjects'),
    );
  }
}

