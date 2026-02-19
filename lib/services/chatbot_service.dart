import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:developer';
import 'package:firebase_core/firebase_core.dart';

class ChatbotService {
  // ✅ Replace with your actual Gemini API Key from Google AI Studio
  static const String _apiKey = 'AIzaSyC4kiXuryJE7wr6BORX3-w-LL0S0LWfWYE';
  //AIzaSyApzHnlbeLUdeszhvvyhZ3NYlCOKY53U38

  static final List<String> _legalKeywords = [
    'law', 'constitution', 'finance', 'advocacy', 'lawyer', 'court', 'judge',
    'legal', 'article', 'section', 'ipc', 'case', 'hearing', 'prison', 'rights',
    'judiciary', 'supreme court', 'high court', 'litigation', 'affidavit'
  ];

  static bool isLegalTopic(String message) {
    final cleanMessage = message.toLowerCase();
    return _legalKeywords.any((keyword) => cleanMessage.contains(keyword));
  }

  static Future<String> getAIResponse(String userMessage) async {
    // 1. Enforce topic constraint locally before calling API
    if (!isLegalTopic(userMessage)) {
      return "You are going out of topic.";
    }

    try {
      // 2. Initialize Gemini Pro Model
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
      );

      // 3. System Instruction: Force the AI to stay within legal boundaries
      final prompt = "You are a professional Legal Assistant for an Indian Law app. "
          "Provide information based strictly on Law, the Constitution, and Finance. "
          "If the user asks something non-legal, say 'You are going out of topic.' "
          "User Query: $userMessage";

      final response = await model.generateContent([Content.text(prompt)]);

      return response.text ?? "No response generated.";
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable' || e.message?.contains('503') == true) {
        return "The legal AI server is currently busy. Please try again in a few moments.";
      }
      return "Database error: ${e.message}";
    } catch (e) {
      return "Service is currently unavailable. Google servers might be overloaded. Please retry.";
    }
  }
}