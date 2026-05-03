import 'package:flutter/material.dart';
import 'voice_assistant_service.dart';
import 'voice_command_parser.dart';

mixin VoiceAssistantMixin<T extends StatefulWidget> on State<T> {
  final VoiceAssistantService _voiceService = VoiceAssistantService();
  bool _voiceInitialized = false;

  bool get voiceInitialized => _voiceInitialized;
  VoiceAssistantService get voiceService => _voiceService;

  @override
  void initState() {
    super.initState();
    debugPrint('🔧 VoiceAssistantMixin: initState called');
    _initializeVoiceAssistant();
  }

  Future<void> _initializeVoiceAssistant() async {
    try {
      debugPrint('🔧 VoiceAssistantMixin: Starting initialization...');

      // Only initialize if not already initialized
      if (!_voiceService.isInitialized) {
        await _voiceService.initialize();
      }

      _voiceService.setOnCommandRecognized(_handleVoiceCommand);

      _voiceService.setOnListeningStarted(() {
        debugPrint('🔧 VoiceAssistantMixin: Listening started callback');
        if (mounted) {
          setState(() {});
        }
      });

      _voiceService.setOnListeningStopped(() {
        debugPrint('🔧 VoiceAssistantMixin: Listening stopped callback');
        if (mounted) {
          setState(() {});
        }
      });

      if (mounted) {
        setState(() {
          _voiceInitialized = true;
        });
        debugPrint('✅ VoiceAssistantMixin: Initialization complete');

        // Start voice guidance automatically after a short delay
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) {
            await _startVoiceGuidance();
          }
        });
      }
    } catch (e) {
      debugPrint('❌ VoiceAssistantMixin: Error initializing: $e');
    }
  }

  Future<void> _startVoiceGuidance() async {
    if (!_voiceInitialized) {
      debugPrint('⚠️ VoiceAssistantMixin: Not initialized, skipping guidance');
      return;
    }

    try {
      debugPrint('🎯 VoiceAssistantMixin: Starting voice guidance');

      // Make sure we're not already speaking or listening
      if (_voiceService.isSpeaking) {
        await _voiceService.stopSpeaking();
      }
      if (_voiceService.isListening) {
        await _voiceService.stopListening();
      }

      // Enable keep listening
      _voiceService.setKeepListening(true);

      // Read page content
      await readPageContent();

      // Small delay before starting to listen
      await Future.delayed(const Duration(milliseconds: 500));

      // Start listening
      if (!_voiceService.isListening && !_voiceService.isSpeaking) {
        bool started = await _voiceService.startListening();
        debugPrint('🎯 VoiceAssistantMixin: Listening started: $started');
      }
    } catch (e) {
      debugPrint('❌ VoiceAssistantMixin: Error starting voice guidance: $e');
    }
  }

  Future<void> readPageContent() async {
    // Override this method in your widget to provide page-specific guidance
    debugPrint(
        '📖 VoiceAssistantMixin: readPageContent (default implementation)');
    if (mounted && context.mounted) {
      final route = ModalRoute.of(context);
      if (route != null) {
        final settings = route.settings;
        if (settings.name != null) {
          await _voiceService.speak(settings.name!);
        }
      }
    }
  }

  Future<void> _handleVoiceCommand(String command) async {
    debugPrint('🎤 VoiceAssistantMixin: Voice command received: "$command"');

    // Stop listening while processing command
    await _voiceService.stopListening();

    // Check for back command
    if (VoiceCommandParser.isBackCommand(command)) {
      await _voiceService.speak('Going back.');
      if (mounted && context.mounted) {
        Navigator.pop(context);
      }
      // Don't restart listening here - it will restart after speaking completes
      return;
    }

    // Handle page-specific commands
    await handlePageSpecificCommand(command);

    // Listening will automatically restart after speaking completes
    // due to the setKeepListening(true) flag
  }

  // Override this method in your widget for page-specific commands
  Future<void> handlePageSpecificCommand(String command) async {
    debugPrint('⚠️ VoiceAssistantMixin: Unhandled command: "$command"');
    await _voiceService
        .speak('I did not understand. Please repeat your command.');
  }

  // Helper method to read back actions
  Future<void> readAction(String actionDescription) async {
    debugPrint('📢 VoiceAssistantMixin: Reading action: $actionDescription');
    await _voiceService.speak(actionDescription);
  }

  // Helper method to read back navigation
  Future<void> readNavigation(String destination) async {
    debugPrint('🧭 VoiceAssistantMixin: Reading navigation: $destination');
    await _voiceService.speak('Navigating to $destination');
  }

  // Ensure listening restarts after any action
  Future<void> ensureListening() async {
    debugPrint('🔄 VoiceAssistantMixin: Ensuring listening is active');
    if (!_voiceService.isListening &&
        !_voiceService.isSpeaking &&
        _voiceInitialized &&
        mounted) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!_voiceService.isListening && !_voiceService.isSpeaking && mounted) {
        debugPrint('🔄 VoiceAssistantMixin: Restarting listening');
        await _voiceService.startListening();
      }
    }
  }

  @override
  void dispose() {
    debugPrint(
        '🗑️ VoiceAssistantMixin: Disposing (but NOT disposing service - it\'s a singleton)');
    // DON'T dispose the service - it's a singleton and should persist
    // Just stop listening for this page
    _voiceService.setKeepListening(false);
    _voiceService.stopListening();
    super.dispose();
  }
}
