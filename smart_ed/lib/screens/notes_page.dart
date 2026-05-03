import 'package:flutter/material.dart';
import '../widgets/global_fabs.dart';
import '../services/voice_assistant_mixin.dart';
import '../services/voice_command_parser.dart';

class NotesPage extends StatefulWidget {
  final String courseName;

  const NotesPage({super.key, required this.courseName});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> with VoiceAssistantMixin {
  final List<Map<String, String>> _notes = [];
  final TextEditingController _noteController = TextEditingController();

  @override
  Future<void> readPageContent() async {
    await voiceService.speak('Notes Page for ${widget.courseName}');
    if (_notes.isEmpty) {
      await voiceService.speak('No notes yet. Say Add Note to create your first note.');
    } else {
      await voiceService.speak('You have ${_notes.length} notes. Say Add Note to add more.');
    }
  }

  @override
  Future<void> handlePageSpecificCommand(String command) async {
    final lowerCommand = command.toLowerCase();
    
    if (lowerCommand.contains('add note') || lowerCommand.contains('new note')) {
      await readAction('Opening add note dialog');
      _showAddNoteDialog();
    } else if (lowerCommand.contains('delete') && VoiceCommandParser.extractChapterNumber(command) != null) {
      int? noteIndex = VoiceCommandParser.extractChapterNumber(command);
      if (noteIndex != null && noteIndex > 0 && noteIndex <= _notes.length) {
        await readAction('Deleting note $noteIndex');
        setState(() {
          _notes.removeAt(noteIndex - 1);
        });
        await voiceService.speak('Note deleted');
        // Listening will restart automatically after speaking completes
      }
    } else {
      await super.handlePageSpecificCommand(command);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.courseName} Notes'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Note',
            onPressed: () async {
              await readAction('Add note button pressed');
              _showAddNoteDialog();
            },
          ),
        ],
      ),
      body: _notes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.note_add, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No notes yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first note',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notes.length,
              itemBuilder: (context, index) {
                final note = _notes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.note),
                    title: Text(note['text']!),
                    subtitle: Text(note['date']!),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.volume_up),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await readAction('Deleting note ${index + 1}');
                            setState(() {
                              _notes.removeAt(index);
                            });
                            await voiceService.speak('Note deleted');
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: GlobalFABs(notesContextTitle: widget.courseName),
    );
  }

  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                hintText: 'Type your note here...',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: () {},
                  tooltip: 'Voice Input',
                ),
                const Text('or tap to use voice'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await readAction('Cancelled');
              if (mounted && context.mounted) {
                Navigator.pop(context);
              }
              _noteController.clear();
              // Listening will restart automatically after speaking completes
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_noteController.text.isNotEmpty) {
                await readAction('Saving note');
                setState(() {
                  _notes.add({
                    'text': _noteController.text,
                    'date': DateTime.now().toString().split(' ')[0],
                  });
                });
                _noteController.clear();
                await voiceService.speak('Note saved successfully');
                if (mounted && context.mounted) {
                  Navigator.pop(context);
                }
                // Listening will restart automatically after speaking completes
              } else {
                await readAction('Note is empty. Please enter some text.');
                // Listening will restart automatically after speaking completes
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }
}
