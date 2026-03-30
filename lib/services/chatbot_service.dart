import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:developer' show log;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class ChatbotService {
  /// Loads GEMINI API key from .env file (not hardcoded)
  static String get _apiKey {
    final key = dotenv.env['GEMINI_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('GEMINI_API_KEY not configured in .env file');
    }
    return key;
  }

  static final List<String> _legalKeywords = [
    'law', 'constitution', 'finance', 'advocacy', 'lawyer', 'court', 'judge',
    'legal', 'article', 'section', 'ipc', 'case', 'hearing', 'prison', 'rights',
    'judiciary', 'supreme court', 'high court', 'litigation', 'affidavit',
    'help', 'hi', 'hello', 'who are you'
  ];

  static bool isLegalTopic(String message) {
    final cleanMessage = message.toLowerCase();
    return _legalKeywords.any((keyword) => cleanMessage.contains(keyword));
  }

  /// ✅ Fetch lawyers from Firestore based on case category
  static Future<List<Map<String, dynamic>>> fetchLawyers(String category) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('lawyers')
          .where('specialization', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      if (kDebugMode) {
        log("Error fetching lawyers: $e");
      }
      return [];
    }
  }

  /// ✅ Support for Conversational Flow with Chatbot and Lawyer Recommendations
  static Future<String> getAIResponse(String userMessage, List<Content> chatHistory) async {
    if (!isLegalTopic(userMessage)) {
      return "I can only assist with legal, constitutional, and financial queries. How can I help you with your case today?";
    }

    try {
      // Identify the category based on user message
      String category = identifyCategory(userMessage);

      // Fetch lawyers from Firestore
      final lawyers = await fetchLawyers(category);

      // Generate a response with lawyer recommendations
      String lawyerList = lawyers.isNotEmpty
          ? lawyers.map((lawyer) => "- ${lawyer['name']} (${lawyer['experience']} years experience)").join("\n")
          : "No lawyers available for this category at the moment.";

      // Chatbot response
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        systemInstruction: Content.system('''
          You are a professional Legal Assistant for the "Legal Case Manager" app. 
          Your specific goal is to help users identify their legal problem and guide them to the right specialist.

          FLOW INSTRUCTIONS:
          1. Greet the user and ask them to describe their legal issue in detail.
          2. Based on their description, identify which category they need: 
             [Criminal, Civil, Corporate, Family, Property, Public Interest, Immigration].
          3. Once identified, explain briefly why that category fits.
          4. Show a list of verified lawyers specializing in the identified category.
          5. When the user clicks on a lawyer's name, open their profile with detailed information.
          6. ALWAYS conclude by asking: "Would you like to see the best verified lawyers for your case description in our Specialists section?"
          7. Keep responses professional, helpful, and concise.

          If the user asks non-legal questions, say "I specialize only in legal guidance."
        '''),
      );

      final chat = model.startChat(history: chatHistory);
      final chatbotResponse = await chat.sendMessage(Content.text(userMessage));

      return chatbotResponse.text != null
          ? "${chatbotResponse.text}\n\nBased on your case description, here are some recommended lawyers:\n$lawyerList\nClick on a lawyer's name to view their profile."
          : "I'm sorry, I couldn't process that. Please try again.";
    } on FirebaseException catch (e) {
      if (kDebugMode) {
        log("Firebase Error: $e");
      }
      return "Service is temporarily busy. Please retry.";
    } catch (e) {
      if (kDebugMode) {
        log("AI Error: $e");
      }
      return "I'm having trouble connecting. Please check your internet and retry.";
    }
  }

  /// ✅ Helper method to identify category from user message
  static String identifyCategory(String message) {
    if (message.contains(RegExp(r'criminal|theft|murder', caseSensitive: false))) {
      return 'Criminal';
    } else if (message.contains(RegExp(r'property|real estate', caseSensitive: false))) {
      return 'Property';
    } else if (message.contains(RegExp(r'family|divorce|child custody', caseSensitive: false))) {
      return 'Family';
    } else {
      return 'General';
    }
  }
}
