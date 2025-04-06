// lib/pages/landing_page.dart
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../components/explore_grid.dart';
import '../components/animated_chat_button.dart';
import '../components/search_input.dart';
import '../services/moneyMind_service.dart';
import '../screens/product_finder_page.dart';

class ChatMessage {
  final String message;
  final bool isUser;
  ChatMessage({required this.message, required this.isUser});
}

class LandingPage extends StatefulWidget {
  const LandingPage({Key? key}) : super(key: key);

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();

  final MoneyMindService _moneyMindService = MoneyMindService(
    // Use the IP address where your FastAPI is running
    // For Android emulator, use 10.0.2.2 to access localhost
    // For physical device, use your computer's IP address on the network
    baseUrl: 'https://moneymind-dlnl.onrender.com',
    userId: 'flutter_user_${DateTime
        .now()
        .millisecondsSinceEpoch}',
  );

  final List<ChatMessage> _messages = [];
  bool _isListening = false;
  bool _isServerConnected = false; // Changed from _isModelAccessible
  bool _isLoading = false;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _verifyServerConnection(); // Changed from _verifyModelAccess
  }

  void _initSpeech() async {
    // No changes needed here
    try {
      await _speech.initialize(
        onError: (error) {
          setState(() => _isListening = false);
          _showErrorSnackBar('Error: ${error.errorMsg}');
        },
      );
    } catch (e) {
      _showErrorSnackBar('Failed to initialize speech recognition');
    }
  }

  // Updated to check server connection instead of model access
  Future<void> _verifyServerConnection() async {
    try {
      final isConnected = await _moneyMindService.verifyServerConnection();
      if (mounted) {
        setState(() {
          _isServerConnected = isConnected;
        });

        if (!isConnected) {
          _showErrorSnackBar(
              'Unable to connect to MoneyMind server. Please check your connection.');
        }
      }
    } catch (e) {
      print('Error verifying server connection: $e');
      _showErrorSnackBar(
          'Error connecting to MoneyMind server. Please check your connection.');
    }
  }

  void _scrollToBottom() {
    // No changes needed here
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showErrorSnackBar(String message) {
    // No changes needed here
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    // No changes needed here
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    // No changes needed here
    setState(() {
      _showSearch = !_showSearch;
    });
  }

  void _handleMicPressed() async {
    // No changes needed here
    try {
      if (!_isListening) {
        bool available = await _speech.initialize(
          onError: (errorNotification) {
            setState(() => _isListening = false);
            _showErrorSnackBar(_getErrorMessage(errorNotification.errorMsg));
          },
        );

        if (available) {
          setState(() => _isListening = true);
          await _speech.listen(
            onResult: (result) {
              setState(() {
                _searchController.text = result.recognizedWords;
                if (result.finalResult) {
                  _handleSearchPressed();
                }
              });
            },
            onDevice: true,
          );
        } else {
          _showErrorSnackBar('Speech recognition not available on this device');
        }
      } else {
        setState(() => _isListening = false);
        await _speech.stop();
      }
    } catch (e) {
      setState(() => _isListening = false);
      _showErrorSnackBar('Please check your internet connection and try again');
    }
  }

  String _getErrorMessage(String error) {
    // No changes needed here
    if (error.contains('network')) {
      return 'Please check your internet connection and try again';
    } else if (error.contains('permission')) {
      return 'Microphone permission is required for voice input';
    } else {
      return 'Unable to recognize speech. Please try again';
    }
  }

  Future<void> _handleSearchPressed() async {
    final question = _searchController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(message: question, isUser: true));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final response = await _moneyMindService.generateResponse(question);

      if (mounted) {
        if (response.startsWith('Error:')) {
          _showErrorSnackBar(response);
        } else {
          setState(() {
            _messages.add(ChatMessage(message: response, isUser: false));
            _searchController.clear();
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      print('Error in _handleSearchPressed: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to generate response. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Updated debug info method
  void _showDebugInfo() async {
    try {
      final isConnected = await _moneyMindService.verifyServerConnection();
      print('Server connected: $isConnected');
      if (!isConnected) {
        _showErrorSnackBar(
            'Server is not accessible. Please check connection settings.');
      }
    } catch (e) {
      print('Debug info error: $e');
    }
  }

  Widget _buildMessage(ChatMessage message) {
    // No changes needed here
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('assets/profile.png'),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.blue[100] : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: message.isUser ? null : Border.all(
                    color: Colors.grey[300]!),
              ),
              child: Text(
                message.message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundImage: AssetImage('assets/profile.png'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 25,
                        backgroundImage: AssetImage('assets/profile.png'),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Hi, Ashwin',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Center(
                        child: AnimatedChatButton(
                          onTap: _toggleSearch,
                          isSearchVisible: _showSearch,
                          hasMessages: _messages.isNotEmpty,
                        ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: Column(
                          children: [
                            if (_showSearch) ...[
                              const SizedBox(height: 20),
                              // Display messages above the input field
                              if (_messages.isNotEmpty || _isLoading) ...[
                                ...List.generate(
                                  _messages.length,
                                      (index) =>
                                      _buildMessage(_messages[index]),
                                ),
                                if (_isLoading)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                                const SizedBox(height: 20),
                              ],
                              // Input field comes after messages
                              AnimatedOpacity(
                                opacity: _showSearch ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                curve: Curves.easeInOut,
                                child: SearchInput(
                                  controller: _searchController,
                                  onMicPressed: _handleMicPressed,
                                  onSearchPressed: _handleSearchPressed,
                                  isListening: _isListening,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Explore',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const SizedBox(
                        height: 400,
                        child: ExploreGrid(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}