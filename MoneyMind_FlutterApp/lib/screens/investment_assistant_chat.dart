// lib/screens/investment_assistant_chat.dart
import 'package:flutter/material.dart';
import '../services/backend_investment_service.dart'; // Import the backend service
import '../utils/server_connection_checker.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final List<String>? suggestions;
  final List<String>? resources;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.suggestions,
    this.resources,
  });
}

class InvestmentAssistantChat extends StatefulWidget {
  final List<Map<String, dynamic>>? selectedProducts;

  const InvestmentAssistantChat({
    Key? key,
    this.selectedProducts,
  }) : super(key: key);

  static Route route({List<Map<String, dynamic>>? selectedProducts}) {
    return MaterialPageRoute(
      builder: (context) => InvestmentAssistantChat(
        selectedProducts: selectedProducts,
      ),
    );
  }

  @override
  State<InvestmentAssistantChat> createState() => _InvestmentAssistantChatState();
}

class _InvestmentAssistantChatState extends State<InvestmentAssistantChat> {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;
  bool _isServerConnected = false;

  // Add backend service
  late final BackendInvestmentService _investmentService;
  // Store conversation history in proper format for the backend
  final List<Map<String, String>> _conversationHistory = [];

  @override
  void initState() {
    super.initState();
    // Initialize the backend service
    final serverUrl = getServerUrl();
    _investmentService = BackendInvestmentService(baseUrl: serverUrl);

    // Check server connection
    checkServerConnection(serverUrl).then((isConnected) {
      setState(() {
        _isServerConnected = isConnected;
      });
      print('Server connection status: $_isServerConnected');
    });

    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    final welcomeText = widget.selectedProducts != null && widget.selectedProducts!.isNotEmpty
        ? "Hello! I'm your investment assistant. I see you're interested in comparing ${widget.selectedProducts!.map((p) => p['name'] ?? 'Unknown').join(' and ')}. How can I help you with these investments?"
        : "Hello! I'm your investment assistant. I can help you find the right investment products, explain different options, and answer questions about your financial goals. How can I help you today?";

    final suggestions = widget.selectedProducts != null && widget.selectedProducts!.isNotEmpty
        ? [
      "What are the key differences between these investments?",
      "Which one has lower fees?",
      "Which is better for my retirement?",
    ]
        : [
      "Help me find low-risk investments",
      "Explain ETFs vs. mutual funds",
      "How much should I save for retirement?",
    ];

    setState(() {
      _messages.add(
        ChatMessage(
          text: welcomeText,
          isUser: false,
          suggestions: suggestions,
        ),
      );
    });
  }

  Future<void> _handleSubmit(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
      ));
      _isTyping = true;
    });

    try {
      // Check server connection first
      final isConnected = await checkServerConnection(_investmentService.baseUrl);

      if (isConnected) {
        // Store this message in conversation history
        Map<String, String> userMessage = {'user': text};
        _conversationHistory.add(userMessage);

        print('Sending to backend: ${text}');
        print('Conversation history: $_conversationHistory');

        // Call the backend API with Gemini
        final response = await _investmentService.queryAssistant(
          question: text,
          products: widget.selectedProducts,
          conversationHistory: _conversationHistory.length > 1 ? _conversationHistory.sublist(0, _conversationHistory.length - 1) : null,
        );

        print('Received response: $response');

        // Extract response components
        final String answer = response['answer'] ?? "I couldn't process your request at this time.";
        final List<String> followUpQuestions = List<String>.from(response['follow_up_questions'] ?? []);
        final List<String> resources = List<String>.from(response['resources'] ?? []);

        // Update the conversation history with the assistant's response
        if (_conversationHistory.isNotEmpty) {
          _conversationHistory.last['assistant'] = answer;
        }

        setState(() {
          _messages.add(ChatMessage(
            text: answer,
            isUser: false,
            suggestions: followUpQuestions.isNotEmpty ? followUpQuestions : null,
            resources: resources.isNotEmpty ? resources : null,
          ));
          _isTyping = false;
        });
      } else {
        print('Server not connected. Using local response');
        // Fallback to local response if server is not connected
        _useLocalResponse(text);
      }
    } catch (e) {
      print('Error getting AI response: $e');
      // Fallback to local response if API call fails
      _useLocalResponse(text);
    }

    // Scroll to bottom after adding new messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _useLocalResponse(String text) {
    // Generate local response
    String response = _getLocalAIResponse(text);
    List<String> suggestions = _generateSuggestions(text);
    List<String> resources = _generateResources(text);

    // Store in conversation history for consistency
    Map<String, String> userMessage = {'user': text, 'assistant': response};
    _conversationHistory.add(userMessage);

    setState(() {
      _messages.add(ChatMessage(
        text: response,
        isUser: false,
        suggestions: suggestions,
        resources: resources.isNotEmpty ? resources : null,
      ));
      _isTyping = false;
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Fallback method for when the backend is unavailable
  String _getLocalAIResponse(String question) {
    final questionLower = question.toLowerCase();

    if (widget.selectedProducts != null && widget.selectedProducts!.isNotEmpty) {
      if (questionLower.contains('difference') || questionLower.contains('compare')) {
        return "Based on my analysis, the key differences between these investments are in their risk levels, expected returns, and fee structures. ${widget.selectedProducts![0]['name'] ?? 'The first product'} offers ${widget.selectedProducts![0]['return'] ?? 'unknown'} return with ${widget.selectedProducts![0]['risk'] ?? 'unknown'} risk, while ${widget.selectedProducts!.length > 1 ? (widget.selectedProducts![1]['name'] ?? 'the second product') + ' provides ' + (widget.selectedProducts![1]['return'] ?? 'unknown') + ' return with ' + (widget.selectedProducts![1]['risk'] ?? 'unknown') + ' risk.' : ''}";
      } else if (questionLower.contains('fee') || questionLower.contains('expense')) {
        return "Looking at the fee structures: ${widget.selectedProducts!.map((p) => (p['name'] ?? 'Unknown') + ' has an expense ratio of ' + (p['expenseRatio'] ?? 'unknown')).join(', ')}. Lower fees can significantly impact your long-term returns, especially for passive investments held over many years.";
      } else if (questionLower.contains('retirement') || questionLower.contains('long term')) {
        return "For retirement planning, I'd consider the time horizon and risk tolerance. ${widget.selectedProducts!.firstWhere((p) => p['timeHorizon'] == '5+ years', orElse: () => widget.selectedProducts![0])['name'] ?? 'The longer-term product'} is designed for longer-term investing, which aligns well with retirement goals. It offers a good balance of growth potential and manageable risk for a retirement portfolio.";
      }
    }

    // Default responses for common topics
    if (questionLower.contains('etf') || questionLower.contains('mutual fund')) {
      return "ETFs (Exchange Traded Funds) and mutual funds are both investment vehicles that pool money from multiple investors to purchase a diversified portfolio of securities. Key differences:\n\n• Trading: ETFs trade like stocks throughout the day, while mutual funds trade once daily at market close.\n• Fees: ETFs typically have lower expense ratios than mutual funds.\n• Minimum investment: Many ETFs have no minimum investment beyond the share price, while mutual funds may require \$1,000+ to start.\n• Tax efficiency: ETFs are generally more tax-efficient than mutual funds.";
    } else if (questionLower.contains('risk') && questionLower.contains('low')) {
      return "For low-risk investments, consider:\n\n• Treasury bonds and TIPS (Treasury Inflation-Protected Securities)\n• High-yield savings accounts\n• Short-term bond ETFs like VTIP or SHY\n• Blue-chip dividend stocks with stable histories\n• Investment-grade corporate bond funds\n\nThese options typically offer modest returns but with significantly less volatility than growth-oriented investments.";
    } else if (questionLower.contains('retirement') || questionLower.contains('retire')) {
      return "For retirement savings, financial experts often recommend saving 15% of your pre-tax income, including any employer match. The exact amount you should save depends on your age, current savings, desired retirement lifestyle, and when you plan to retire. A common guideline is to have 1x your annual salary saved by 30, 3x by 40, 6x by 50, and 8x by 60. Would you like me to help you calculate a more specific target based on your situation?";
    }

    // Default response for other questions
    return "That's a great question about investing. Based on financial best practices, I'd recommend focusing on a diversified approach that aligns with your risk tolerance and time horizon. Would you like me to provide more specific information or explain any particular aspect of investing in more detail?";
  }

  List<String> _generateSuggestions(String question) {
    final questionLower = question.toLowerCase();

    if (questionLower.contains('etf') || questionLower.contains('mutual fund')) {
      return [
        "Which ETFs have the lowest fees?",
        "Are ETFs better than mutual funds for my taxes?",
        "How do I choose an ETF for my portfolio?"
      ];
    } else if (questionLower.contains('risk') || questionLower.contains('safe')) {
      return [
        "How do I balance risk and return?",
        "What are the safest investments right now?",
        "How much risk should I take for retirement?"
      ];
    } else if (questionLower.contains('retirement') || questionLower.contains('retire')) {
      return [
        "What's the 4% rule for retirement?",
        "Should I max out my 401(k) first?",
        "How do I catch up on retirement savings?"
      ];
    } else if (questionLower.contains('dividend') || questionLower.contains('income')) {
      return [
        "What dividend yield is considered good?",
        "Are high-dividend stocks risky?",
        "How are dividends taxed?"
      ];
    }

    // Default suggestions
    return [
      "How should I diversify my portfolio?",
      "What's a good investment strategy for a bear market?",
      "How much should I have in emergency savings?"
    ];
  }

  List<String> _generateResources(String question) {
    final questionLower = question.toLowerCase();

    List<String> resources = [];

    if (questionLower.contains('tax') || questionLower.contains('taxes')) {
      resources.add("Tax Professional");
    }

    if (questionLower.contains('retire') || questionLower.contains('401k') ||
        questionLower.contains('ira') || questionLower.contains('pension')) {
      resources.add("Retirement Planner");
    }

    if (questionLower.contains('estate') || questionLower.contains('will') ||
        questionLower.contains('trust') || questionLower.contains('inheritance')) {
      resources.add("Estate Attorney");
    }

    if (questionLower.contains('debt') || questionLower.contains('credit') ||
        questionLower.contains('loan')) {
      resources.add("Credit Counselor");
    }

    // Always add Financial Advisor for complex questions
    if (question.split(' ').length > 10) {
      resources.add("Financial Advisor");
    }

    return resources;
  }

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    // Get bottom padding for safe area (especially important for iPhone X and newer)
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Investment Assistant',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.black),
            onPressed: () {
              _showAssistantInfo();
            },
          ),
        ],
      ),
      body: SafeArea(
        // Use SafeArea to respect system UI
        child: Column(
          children: [
            // Connection status indicator
            if (!_isServerConnected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.orange[50],
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI Assistant is running in offline mode',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        setState(() {
                          _isTyping = true;
                        });
                        final isConnected = await checkServerConnection(_investmentService.baseUrl);
                        setState(() {
                          _isServerConnected = isConnected;
                          _isTyping = false;
                        });
                      },
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Selected products banner (if any)
            if (widget.selectedProducts != null && widget.selectedProducts!.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.blue[50],
                child: Row(
                  children: [
                    Icon(Icons.compare_arrows, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Comparing: ${widget.selectedProducts!.map((p) => p['name'] ?? 'Unknown').join(', ')}',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Chat messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessage(_messages[index]);
                },
              ),
            ),

            // AI is typing indicator
            if (_isTyping)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI is thinking...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            // Input area with improved padding
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                left: 8.0,
                right: 8.0,
                top: 12.0,
                bottom: 12.0 + bottomPadding, // Add extra padding at the bottom
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        hintText: 'Ask me about investing...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Increased vertical padding
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: _isTyping ? null : _handleSubmit,
                      enabled: !_isTyping,
                      maxLines: null, // Allow multiple lines if needed
                      textInputAction: TextInputAction.send, // Use send button on keyboard
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _isTyping
                          ? null
                          : () {
                        if (_textController.text.isNotEmpty) {
                          _handleSubmit(_textController.text);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.isUser;

    return Container(
      margin: EdgeInsets.only(
        top: 8,
        bottom: 8,
        left: isUser ? 64 : 16,
        right: isUser ? 16 : 64,
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isUser ? Colors.green : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
              ),
            ),
          ),

          // Suggested follow-up questions
          if (!isUser && message.suggestions != null && message.suggestions!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: message.suggestions!.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: OutlinedButton(
                      onPressed: _isTyping
                          ? null
                          : () {
                        _handleSubmit(message.suggestions![index]);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue[700],
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.blue[200]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        message.suggestions![index],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Resources (if any)
          if (!isUser && message.resources != null && message.resources!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.book, size: 16, color: Colors.grey[700]),
                      const SizedBox(width: 6),
                      Text(
                        'Resources',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Use Wrap instead of Column for resources to prevent overflow
                  Wrap(
                    spacing: 8, // horizontal space between items
                    runSpacing: 8, // vertical space between lines
                    children: message.resources!.map((resource) =>
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min, // Important to prevent Row from taking full width
                            children: [
                              Icon(Icons.circle, size: 6, color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  resource,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                  ),
                                  overflow: TextOverflow.ellipsis, // Add ellipsis if text is too long
                                ),
                              ),
                            ],
                          ),
                        ),
                    ).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showAssistantInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lightbulb, color: Colors.green[700]),
            ),
            const SizedBox(width: 12),
            const Text('About Investment Assistant'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'The Investment Assistant helps you:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('• Find investment products matching your goals'),
            Text('• Compare different investment options'),
            Text('• Learn about investment concepts'),
            Text('• Get answers to financial planning questions'),
            SizedBox(height: 16),
            Text(
              'Note: This assistant provides educational information, not personalized financial advice. Always consult with a qualified financial advisor for advice specific to your situation.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}