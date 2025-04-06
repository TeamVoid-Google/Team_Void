import 'package:flutter/material.dart';

class SearchInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onMicPressed;
  final VoidCallback onSearchPressed;
  final bool isListening;

  const SearchInput({
    Key? key,
    required this.controller,
    required this.onMicPressed,
    required this.onSearchPressed,
    required this.isListening,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Type your message...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => onSearchPressed(),
            ),
          ),
          IconButton(
            icon: Icon(isListening ? Icons.mic : Icons.mic_none),
            onPressed: onMicPressed,
            color: isListening ? Colors.red : Colors.blue,
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: onSearchPressed,
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}