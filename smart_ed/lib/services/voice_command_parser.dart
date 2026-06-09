import 'voice_assistant_service.dart';

class VoiceCommandParser {
  static VoiceCommandType parseCommandType(String command) {
    final lowerCommand = command.toLowerCase().trim();

    // Input commands - check first for text input
    if (isInputCommand(lowerCommand)) {
      return VoiceCommandType.input;
    }

    // Navigation commands
    if (_matchesPattern(
        lowerCommand, ['open', 'go to', 'navigate to', 'show'])) {
      return VoiceCommandType.navigate;
    }

    // Selection commands
    if (_matchesPattern(lowerCommand,
        ['graded', 'ungraded', 'yes', 'no', 'choose', 'select'])) {
      return VoiceCommandType.select;
    }

    // Action commands
    if (_matchesPattern(lowerCommand, [
      'read',
      'start',
      'take',
      'next',
      'previous',
      'back',
      'go back',
      'login',
      'submit'
    ])) {
      return VoiceCommandType.action;
    }

    return VoiceCommandType.unknown;
  }

  static bool _matchesPattern(String command, List<String> patterns) {
    return patterns.any((pattern) => command.contains(pattern));
  }

  // ========== TEXT INPUT COMMANDS ==========

  static bool isInputCommand(String command) {
    final lowerCommand = command.toLowerCase();
    return lowerCommand.contains('type') ||
        lowerCommand.contains('enter') ||
        lowerCommand.contains('write') ||
        lowerCommand.contains('username is') ||
        lowerCommand.contains('password is') ||
        lowerCommand.contains('email is') ||
        lowerCommand.contains('my username is') ||
        lowerCommand.contains('my password is') ||
        lowerCommand.contains('my email is');
  }

  static Map<String, String>? extractInputData(String command) {
    final lowerCommand = command.toLowerCase();

    // Extract username
    if (lowerCommand.contains('username')) {
      final patterns = [
        RegExp(r'username\s+is\s+(.+)', caseSensitive: false),
        RegExp(r'my\s+username\s+is\s+(.+)', caseSensitive: false),
        RegExp(r'type\s+username\s+(.+)', caseSensitive: false),
        RegExp(r'enter\s+username\s+(.+)', caseSensitive: false),
        RegExp(r'write\s+username\s+(.+)', caseSensitive: false),
      ];

      for (var pattern in patterns) {
        final match = pattern.firstMatch(command);
        if (match != null) {
          String value = match.group(1)!.trim();
          // Remove common trailing words
          value = _cleanInputValue(value);
          return {'field': 'username', 'value': value};
        }
      }
    }

    // Extract email
    if (lowerCommand.contains('email')) {
      final patterns = [
        RegExp(r'email\s+is\s+(.+)', caseSensitive: false),
        RegExp(r'my\s+email\s+is\s+(.+)', caseSensitive: false),
        RegExp(r'type\s+email\s+(.+)', caseSensitive: false),
        RegExp(r'enter\s+email\s+(.+)', caseSensitive: false),
        RegExp(r'write\s+email\s+(.+)', caseSensitive: false),
      ];

      for (var pattern in patterns) {
        final match = pattern.firstMatch(command);
        if (match != null) {
          String value = match.group(1)!.trim();
          value = _cleanInputValue(value);
          // Convert spoken email format
          value = _convertSpokenEmail(value);
          return {'field': 'email', 'value': value};
        }
      }
    }

    // Extract password
    if (lowerCommand.contains('password')) {
      final patterns = [
        RegExp(r'password\s+is\s+(.+)', caseSensitive: false),
        RegExp(r'my\s+password\s+is\s+(.+)', caseSensitive: false),
        RegExp(r'type\s+password\s+(.+)', caseSensitive: false),
        RegExp(r'enter\s+password\s+(.+)', caseSensitive: false),
        RegExp(r'write\s+password\s+(.+)', caseSensitive: false),
      ];

      for (var pattern in patterns) {
        final match = pattern.firstMatch(command);
        if (match != null) {
          String value = match.group(1)!.trim();
          value = _cleanInputValue(value);
          return {'field': 'password', 'value': value};
        }
      }
    }

    return null;
  }

  static String _cleanInputValue(String value) {
    // Remove common trailing command words
    final trailingWords = ['please', 'now', 'thanks', 'thank you'];
    for (var word in trailingWords) {
      if (value.toLowerCase().endsWith(' $word')) {
        value = value.substring(0, value.length - word.length - 1).trim();
      }
    }
    return value;
  }

  static String _convertSpokenEmail(String spokenEmail) {
    // Convert spoken email to actual email format
    // Example: "john at example dot com" -> "john@example.com"
    String converted = spokenEmail.toLowerCase();

    converted = converted.replaceAll(' at ', '@');
    converted = converted.replaceAll(' dot ', '.');
    converted = converted.replaceAll(' ', '');

    return converted;
  }

  // ========== EXISTING COMMANDS ==========

  static String? extractSubjectName(
      String command, List<String> availableSubjects) {
    final lowerCommand = command.toLowerCase();

    for (String subject in availableSubjects) {
      if (lowerCommand.contains(subject.toLowerCase())) {
        return subject;
      }
    }

    return null;
  }

  static bool isGradedCommand(String command) {
    final lowerCommand = command.toLowerCase();
    return lowerCommand.contains('graded') &&
        !lowerCommand.contains('ungraded');
  }

  static bool isUngradedCommand(String command) {
    final lowerCommand = command.toLowerCase();
    return lowerCommand.contains('ungraded') ||
        (lowerCommand.contains('not graded') ||
            lowerCommand.contains('no grade'));
  }

  static int? extractChapterNumber(String command) {
    final lowerCommand = command.toLowerCase();

    final regex =
        RegExp(r'\b(one|two|three|four|five|six|seven|eight|nine|ten|\d+)\b');
    final match = regex.firstMatch(lowerCommand);

    if (match != null) {
      String numberStr = match.group(0)!;

      final wordToNumber = {
        'one': 1,
        'two': 2,
        'three': 3,
        'four': 4,
        'five': 5,
        'six': 6,
        'seven': 7,
        'eight': 8,
        'nine': 9,
        'ten': 10,
      };

      if (wordToNumber.containsKey(numberStr)) {
        return wordToNumber[numberStr];
      } else {
        return int.tryParse(numberStr);
      }
    }

    return null;
  }

  static bool isQuizCommand(String command) {
    final lowerCommand = command.toLowerCase();
    return lowerCommand.contains('quiz') ||
        lowerCommand.contains('assessment') ||
        lowerCommand.contains('test');
  }

  static bool isBackCommand(String command) {
    final lowerCommand = command.toLowerCase();
    return lowerCommand.contains('back') ||
        lowerCommand.contains('return') ||
        lowerCommand.contains('go back');
  }

  static bool isReadCommand(String command) {
    final lowerCommand = command.toLowerCase();
    return lowerCommand.contains('read') ||
        lowerCommand.contains('start') ||
        lowerCommand.contains('open');
  }

  static bool isLoginCommand(String command) {
    final lowerCommand = command.toLowerCase();
    return lowerCommand.contains('login') ||
        lowerCommand.contains('log in') ||
        lowerCommand.contains('sign in') ||
        lowerCommand.contains('submit');
  }
}
