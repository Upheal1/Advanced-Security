import 'dart:convert';
import 'package:http/http.dart' as http;

class AiChatService {
  static const String _apiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );
  static const String _endpoint =
      "https://api.groq.com/openai/v1/chat/completions";

  static const String systemPrompt = """You are an AI mental health support assistant acting as a warm, empathetic therapist and life coach.

Core behavior:
- Use Cognitive Behavioral Therapy (CBT) techniques
- Validate emotions before giving guidance
- Keep responses short to medium (3–7 sentences)
- Be calm, friendly, non-judgmental, and supportive
- Ask gentle follow-up questions to continue the conversation
- Speak in a natural, human tone suitable for Gen-Z and Gen-Alpha

CBT techniques to apply:
- Cognitive reframing
- Thought awareness
- Grounding exercises
- Behavioral activation
- Stress and anxiety coping strategies

Memory:
- Remember important details shared by the user during this conversation
- Refer back to them naturally when helpful

Safety rules (VERY IMPORTANT):
- Do NOT diagnose
- Do NOT give medical or clinical advice
- If the user expresses suicidal thoughts, self-harm, or crisis:
  - Respond with empathy
  - Encourage contacting local emergency services or a trusted person
  - Suggest reaching out to a mental health professional
  - Never act as a replacement for professional care

Your goal:
Help the user feel heard, supported, and gently guided — like a trusted therapist and friend.
""";

  static Future<String> sendMessage(
      String userMessage,
      List<Map<String, String>> history,
      ) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'GROQ_API_KEY is not set. '
            'Build with: flutter run --dart-define=GROQ_API_KEY=<your_key>',
      );
    }

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "llama-3.1-8b-instant",
          "messages": [
            {"role": "system", "content": systemPrompt},
            ...history,
            {"role": "user", "content": userMessage}
          ],
          "temperature": 0.7,
          "max_tokens": 300
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'AI service error (${response.statusCode}). Please try again.',
        );
      }

      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) {
        throw Exception('Unexpected response format from AI service.');
      }

      final choices = data['choices'];
      if (choices == null || choices is! List || choices.isEmpty) {
        throw Exception('No response received from AI service.');
      }

      final content = choices[0]?['message']?['content'];
      if (content == null || content is! String) {
        throw Exception('Invalid response structure from AI service.');
      }

      return content;
    } on FormatException {
      throw Exception('Failed to parse AI service response.');
    }
  }
}
