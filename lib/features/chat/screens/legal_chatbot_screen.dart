import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:legal_case_manager/services/chatbot_service.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:legal_case_manager/features/lawyer/screens/lawyer_profile_view_screen.dart';

class LegalChatbotScreen extends StatefulWidget {
  const LegalChatbotScreen({super.key});

  @override
  State<LegalChatbotScreen> createState() => _LegalChatbotScreenState();
}

class _LegalChatbotScreenState extends State<LegalChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Create a chat history list
    List<Content> chatHistory = _messages.map((message) {
      return message["role"] == "user"
          ? Content.text(message["content"]!)
          : Content.text(message["content"]!);
    }).toList();

    String response = await ChatbotService.getAIResponse(text, chatHistory);

    setState(() {
      _isLoading = false;
      _messages.add({"role": "bot", "content": response});
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Light professional grey
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0F172A), // Midnight Blue
        centerTitle: false,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: const Icon(Icons.gavel, color: Color(0xFF0F172A), size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Legal AI Assistant", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                Text("Online", style: TextStyle(fontSize: 12, color: Colors.greenAccent)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final isUser = _messages[i]['role'] == 'user';
                return _buildChatBubble(isUser, _messages[i]['content']!);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(left: 20, bottom: 10),
              child: Align(alignment: Alignment.centerLeft, child: Text("Legal AI is typing...", style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic))),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(bool isUser, String message) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
          ],
        ),
        child: _buildMessageContent(isUser, message),
      ),
    );
  }

  Widget _buildMessageContent(bool isUser, String message) {
    if (isUser) {
      return SelectableText(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          height: 1.4,
        ),
      );
    }

    final profileLinkPattern = RegExp(r'app://lawyer-profile/([A-Za-z0-9_-]+)');
    final matches = profileLinkPattern.allMatches(message).toList();

    if (matches.isEmpty) {
      return SelectableText(
        message,
        style: const TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 15,
          height: 1.4,
        ),
      );
    }

    final spans = <TextSpan>[];
    int cursor = 0;

    for (final match in matches) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(
            text: message.substring(cursor, match.start),
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 15,
              height: 1.4,
            ),
          ),
        );
      }

      final lawyerId = match.group(1);
      if (lawyerId != null && lawyerId.isNotEmpty) {
        spans.add(
          TextSpan(
            text: 'Open Profile',
            style: const TextStyle(
              color: Color(0xFF1D4ED8),
              fontSize: 15,
              height: 1.4,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LawyerProfileViewScreen(lawyerId: lawyerId),
                  ),
                );
              },
          ),
        );
      }

      cursor = match.end;
    }

    if (cursor < message.length) {
      spans.add(
        TextSpan(
          text: message.substring(cursor),
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 15,
            height: 1.4,
          ),
        ),
      );
    }

    return SelectableText.rich(TextSpan(children: spans));
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -2), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 1,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: "Ask about law or courts...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.blueGrey, fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _handleSend,
            child: const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFF0F172A),
              child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}