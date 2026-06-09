import 'package:flutter/material.dart';
import 'register_page.dart';
import 'splash_screen.dart';
import '../services/voice_assistant_mixin.dart';
import '../services/voice_command_parser.dart';
import '../services/voice_assistant_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with VoiceAssistantMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  Future<void> readPageContent() async {
    await voiceService.speak(
        'Login Page. You can say: email is followed by your email address, '
        'password is followed by your password, login to submit, '
        'register to create new account, or back to go back.');
  }

  @override
  Future<void> handlePageSpecificCommand(String command) async {
    final commandType = VoiceCommandParser.parseCommandType(command);

    // Handle text input commands
    if (commandType == VoiceCommandType.input) {
      final inputData = VoiceCommandParser.extractInputData(command);

      if (inputData != null) {
        final field = inputData['field'];
        final value = inputData['value'];

        if (field == 'email') {
          _emailController.text = value!;
          await voiceService.speak('Email set to $value');
          await Future.delayed(const Duration(milliseconds: 800));
          await voiceService.speak('Now say your password.');
          setState(() {});
        } else if (field == 'password') {
          _passwordController.text = value!;
          await voiceService.speak('Password entered.');
          await Future.delayed(const Duration(milliseconds: 800));
          await voiceService.speak('Say login to submit.');
          setState(() {});
        } else if (field == 'username') {
          // Accept username as email
          _emailController.text = value!;
          await voiceService.speak('Email set to $value');
          await Future.delayed(const Duration(milliseconds: 800));
          await voiceService.speak('Now say your password.');
          setState(() {});
        }
        return;
      }
    }

    // Handle login/submit command
    if (VoiceCommandParser.isLoginCommand(command)) {
      await _handleLogin();
      return;
    }

    // Handle register navigation
    if (command.contains('register') || command.contains('sign up')) {
      await readNavigation('Register Page');
      if (mounted && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const RegisterPage(),
          ),
        );
      }
      return;
    }

    // Handle forgot password
    if (command.contains('forgot password') ||
        command.contains('reset password')) {
      await readAction('Forgot password option selected');
      // TODO: Implement forgot password
      return;
    }

    // Handle show/hide password
    if (command.contains('show password') ||
        command.contains('visible password')) {
      setState(() {
        _isPasswordVisible = true;
      });
      await readAction('Password visible');
      return;
    }

    if (command.contains('hide password') ||
        command.contains('invisible password')) {
      setState(() {
        _isPasswordVisible = false;
      });
      await readAction('Password hidden');
      return;
    }

    // Handle read command
    if (VoiceCommandParser.isReadCommand(command)) {
      await readPageContent();
      return;
    }

    // Unknown command
    await voiceService
        .speak('Command not recognized. Say email is followed by your email, '
            'password is followed by your password, or say login to submit.');
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty) {
      await voiceService.speak('Please enter your email first.');
      return;
    }

    if (_passwordController.text.isEmpty) {
      await voiceService.speak('Please enter your password first.');
      return;
    }

    // Validate and submit
    if (_formKey.currentState!.validate()) {
      await readAction('Logging in');
      await readNavigation('Dashboard');

      // Navigate to splash screen which will then go to home
      if (mounted && context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const SplashScreen(goToHome: true),
          ),
        );
      }
    } else {
      await readAction('Please enter valid email and password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        actions: [
          // Voice indicator
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Icon(
              voiceService.isListening
                  ? Icons.mic
                  : voiceService.isSpeaking
                      ? Icons.volume_up
                      : Icons.mic_off,
              color: voiceService.isListening
                  ? Colors.red
                  : voiceService.isSpeaking
                      ? Colors.blue
                      : Colors.grey,
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo Image
                Image.asset(
                  'assets/images/logo.png',
                  height: 350,
                  width: 350,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.school_rounded,
                      size: 80,
                      color: Colors.blue,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Voice command instructions
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.mic,
                              color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Voice Commands',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• "email is [your email]"\n'
                        '• "password is [your password]"\n'
                        '• "login" to submit\n'
                        '• "register" to sign up',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Email field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password field
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () async {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                        await readAction(_isPasswordVisible
                            ? 'Password visible'
                            : 'Password hidden');
                      },
                    ),
                  ),
                  obscureText: !_isPasswordVisible,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Login button
                ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 16),

                // Forgot password
                TextButton(
                  onPressed: () async {
                    await readAction('Forgot password option selected');
                    // TODO: Implement forgot password
                  },
                  child: const Text('Forgot Password?'),
                ),
                const SizedBox(height: 8),

                // Register link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: () async {
                        await readNavigation('Register Page');
                        if (mounted && context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterPage(),
                            ),
                          );
                        }
                      },
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
