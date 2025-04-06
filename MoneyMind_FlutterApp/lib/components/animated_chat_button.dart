import 'package:flutter/material.dart';

class AnimatedChatButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isSearchVisible;
  final bool hasMessages; // Added new parameter to check if there are messages

  const AnimatedChatButton({
    Key? key,
    required this.onTap,
    this.isSearchVisible = false,
    this.hasMessages = false, // Default to false
  }) : super(key: key);

  @override
  State<AnimatedChatButton> createState() => _AnimatedChatButtonState();
}

class _AnimatedChatButtonState extends State<AnimatedChatButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20), // Kept at 20 seconds as in your code
      vsync: this,
    )..repeat();
  }

  @override
  void didUpdateWidget(AnimatedChatButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSearchVisible) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        children: [
          RotationTransition(
            turns: _controller,
            child: Image.asset(
              'assets/chat_button.png',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 5),
          // Only show the text if there are no messages
          if (!widget.hasMessages)
            const Text(
              'Tap to start Chat',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
        ],
      ),
    );
  }
}