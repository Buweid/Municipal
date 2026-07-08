import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String _apiUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _apiKey = String.fromEnvironment('GROQ_API_KEY');
  static const String _model = 'llama-3.1-8b-instant';

  static const String _systemPrompt = '''You are a helpful assistant 
for Muscat Municipality's reporting system in Oman. Help citizens 
submit issue reports, track complaints, and understand services. 
Keep responses concise, friendly, and focused on municipality services.
Respond in the same language the user writes in (Arabic or English).
If asked about unrelated topics, politely redirect to municipality services.''';

  // ── SHARED REQUEST ───────────────────────────────────────────────
  static Future<Map<String, dynamic>?> _post(
      List<Map<String, String>> messages) async {
    try {
      final response = await http
          .post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            ...messages,
          ],
          'max_tokens': 512,
          'temperature': 0.7,
        }),
      )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── CHATBOT ──────────────────────────────────────────────────────
  static Future<String> chat({
    required List<Map<String, String>> messages,
  }) async {
    final data = await _post(messages);
    if (data == null) {
      return 'Connection error. Please check your internet and try again.';
    }
    try {
      return data['choices'][0]['message']['content'] as String? ??
          'Sorry, I could not process your request.';
    } catch (_) {
      return 'Sorry, I could not process your request.';
    }
  }

  // ── AUTOCOMPLETE ─────────────────────────────────────────────────
  static Future<List<String>> getIssueSuggestions({
    required String issueType,
    required String partialTitle,
  }) async {
    if (partialTitle.trim().length < 3) return [];

    final data = await _post([
      {
        'role': 'user',
        'content':
        'Generate exactly 3 short issue title suggestions for a municipality report.\n'
            'Issue type: $issueType\n'
            'Partial title: "$partialTitle"\n'
            'Respond ONLY with a JSON array of 3 strings. Example: ["Title 1","Title 2","Title 3"]',
      }
    ]);

    if (data == null) return [];

    try {
      final text =
      data['choices'][0]['message']['content'] as String;
      final cleaned = text
          .trim()
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      final List<dynamic> list = jsonDecode(cleaned);
      return list.map((s) => s.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  // ── IMPROVE DESCRIPTION ──────────────────────────────────────────
  static Future<String> improveDescription({
    required String issueType,
    required String roughDescription,
  }) async {
    if (roughDescription.trim().length < 10) return roughDescription;

    final data = await _post([
      {
        'role': 'user',
        'content':
        'Improve this municipality issue description to be clear and professional.\n'
            'Issue type: $issueType\n'
            'Description: "$roughDescription"\n'
            'Return ONLY the improved description. Max 150 words. '
            'Keep the same language (Arabic or English).',
      }
    ]);

    if (data == null) return roughDescription;

    try {
      return data['choices'][0]['message']['content'] as String? ??
          roughDescription;
    } catch (_) {
      return roughDescription;
    }
  }
}