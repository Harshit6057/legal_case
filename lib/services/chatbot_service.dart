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
    'law',
    'constitution',
    'finance',
    'advocacy',
    'lawyer',
    'court',
    'judge',
    'legal',
    'article',
    'section',
    'ipc',
    'crpc',
    'cpc',
    'bns',
    'case',
    'hearing',
    'bail',
    'fir',
    'rights',
    'judiciary',
    'supreme court',
    'high court',
    'litigation',
    'affidavit',
    'contract',
    'property',
    'family',
    'civil',
    'criminal',
    'corporate',
    'immigration',
    'public interest',
    'help',
    'hi',
    'hello',
    'who are you'
  ];

  static final List<String> _lawyerIntentKeywords = [
    'lawyer',
    'advocate',
    'attorney',
    'counsel',
    'hire',
    'book',
    'consult',
    'specialist',
    'expert',
    'case'
  ];

  static bool isLegalTopic(String message) {
    final cleanMessage = message.toLowerCase();
    return _legalKeywords.any((keyword) => cleanMessage.contains(keyword));
  }

  static bool _needsLawyerRecommendations(String message) {
    final cleanMessage = message.toLowerCase();
    return _lawyerIntentKeywords.any((keyword) => cleanMessage.contains(keyword));
  }

  /// Fetches only in-app signed-up lawyers from users collection.
  static Future<List<Map<String, dynamic>>> fetchLawyers(String category) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'lawyer')
          .limit(80)
          .get();

      final lawyers = <Map<String, dynamic>>[];
      final targetCategory = category.toLowerCase();

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final specialization = (data['specialization'] ?? '').toString();
        final status = (data['status'] ?? '').toString().toLowerCase();
        final isVerified = data['isVerified'] == true || data['verified'] == true;

        final categoryMatches = category == 'General' || specialization.toLowerCase() == targetCategory;
        final isApprovedOrUnknown = status.isEmpty || status == 'verified' || isVerified;

        if (!categoryMatches || !isApprovedOrUnknown) {
          continue;
        }

        lawyers.add({
          'id': doc.id,
          'name': (data['name'] ?? 'Lawyer').toString(),
          'specialization': specialization.isEmpty ? 'General' : specialization,
          'experience': (data['experience'] ?? 0).toString(),
          'state': (data['state'] ?? '').toString(),
          'district': (data['district'] ?? '').toString(),
        });
      }

      lawyers.sort((a, b) {
        final aExp = int.tryParse(a['experience'].toString()) ?? 0;
        final bExp = int.tryParse(b['experience'].toString()) ?? 0;
        return bExp.compareTo(aExp);
      });

      return lawyers.take(5).toList();
    } catch (e) {
      if (kDebugMode) {
        log("Error fetching lawyers: $e");
      }
      return [];
    }
  }

  static String _buildLawyerRecommendationBlock(
    List<Map<String, dynamic>> lawyers,
    String category,
  ) {
    if (lawyers.isEmpty) {
      return "No verified in-app lawyers found right now for $category. Please try a broader category or check again later.";
    }

    final lines = <String>[];
    lines.add("Verified in-app lawyers (${category.toUpperCase()}):");

    for (final lawyer in lawyers) {
      final state = lawyer['state'].toString().trim();
      final district = lawyer['district'].toString().trim();
      final location = [district, state].where((value) => value.isNotEmpty).join(', ');

      lines.add(
        "- ${lawyer['name']} | ${lawyer['specialization']} | ${lawyer['experience']} years"
        "${location.isNotEmpty ? ' | $location' : ''}\n"
        "  Profile: app://lawyer-profile/${lawyer['id']}",
      );
    }

    return lines.join('\n');
  }

  /// Agent-style legal guidance + app-only lawyer recommendations.
  static Future<String> getAIResponse(String userMessage, List<Content> chatHistory) async {
    if (!isLegalTopic(userMessage)) {
      return "I can help with legal and case-related topics (law, constitution, courts, procedure, rights, contracts, property, family, criminal, civil, corporate, immigration). Ask your legal question and I will guide you.";
    }

    try {
      final category = identifyCategory(userMessage);
      final shouldRecommendLawyers = _needsLawyerRecommendations(userMessage);

      final lawyers = shouldRecommendLawyers ? await fetchLawyers(category) : <Map<String, dynamic>>[];

      final lawyerBlock = shouldRecommendLawyers
          ? _buildLawyerRecommendationBlock(lawyers, category)
          : "";

      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
        systemInstruction: Content.system('''
          You are the in-app legal agent for "Legal Case Manager".
          
          Follow these rules:
          1) Answer legal/case questions across the full legal field: constitution, courts, procedure, rights, criminal, civil, family, property, corporate, contracts, immigration, and legal strategy basics.
          2) Keep responses practical, accurate, and easy to follow.
          3) Never suggest random lawyers from the web.
          4) Use ONLY the app-provided recommendation block when sharing lawyers.
          5) If data is missing, state limits clearly and ask follow-up questions.
          6) Do not provide final legal representation claims; suggest consulting a verified in-app lawyer when needed.
        '''),
      );

      final chat = model.startChat(history: chatHistory);
      final prompt = '''
User query:
$userMessage

Detected case category: $category

In-app lawyer data block (use only this for recommendations):
${lawyerBlock.isEmpty ? 'No lawyer recommendation requested by user.' : lawyerBlock}

Response format:
- Start with concise legal guidance.
- If the user asked to find/hire/consult lawyer or asked case assistance, include the in-app lawyer data block exactly as provided under heading "Recommended Profiles".
- End with one practical next step question.
''';

      final chatbotResponse = await chat.sendMessage(Content.text(prompt));

      return chatbotResponse.text != null
          ? chatbotResponse.text!
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
    if (message.contains(RegExp(r'criminal|theft|murder|assault|fir|bail|police', caseSensitive: false))) {
      return 'Criminal';
    } else if (message.contains(RegExp(r'property|real estate|land|registry|tenant|rent', caseSensitive: false))) {
      return 'Property';
    } else if (message.contains(RegExp(r'family|divorce|child custody|alimony|domestic', caseSensitive: false))) {
      return 'Family';
    } else if (message.contains(RegExp(r'company|corporate|startup|shareholder|compliance|agreement', caseSensitive: false))) {
      return 'Corporate';
    } else if (message.contains(RegExp(r'immigration|visa|passport|citizenship|deportation', caseSensitive: false))) {
      return 'Immigration';
    } else if (message.contains(RegExp(r'civil|injunction|damages|notice|contract', caseSensitive: false))) {
      return 'Civil';
    } else if (message.contains(RegExp(r'public interest|pil|constitutional|article|fundamental rights', caseSensitive: false))) {
      return 'Public Interest';
    } else {
      return 'General';
    }
  }
}
