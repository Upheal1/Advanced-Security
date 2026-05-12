import 'dart:convert';
import 'package:http/http.dart' as http;

class AiChatService {
  static const String _apiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  static bool get isConfigured => _apiKey.isNotEmpty;

  /// Empathic offline replies when no API key or network failure.
  static String localFallbackReply(String userMessage) {
    final lower = userMessage.toLowerCase();
    if (RegExp(r'suicid|kill myself|self[- ]harm|end my life|want to die')
        .hasMatch(lower)) {
      return "I'm really glad you told me. Your safety matters most. If you're in immediate danger, call your local emergency number. In the U.S. you can call or text 988 for the Suicide & Crisis Lifeline. You deserve real-time support from trained people — I'm here to listen, but they're best equipped to help right now.";
    }
    if (lower.contains('anxious') || lower.contains('anxiety')) {
      return "Anxiety can feel so heavy in the body. You're not overreacting — you're human. What tends to trigger it most lately: mornings, social situations, school or work, or something else?";
    }
    if (lower.contains('focus') || lower.contains('phone') || lower.contains('screen')) {
      return "Screens steal attention in tiny pulls all day — it's not a character flaw. What if we tried one small experiment: a single 25-minute focus block, phone in another room? Would you want tips to set that up?";
    }
    if (lower.contains('sleep') || lower.contains('tired')) {
      return "Sleep touches everything else when it's off. Has your bedtime been shifting, or is it more that your mind won't switch off when you lie down?";
    }
    if (lower.contains('sad') || lower.contains('depress') || lower.contains('lonely')) {
      return "Thank you for trusting me with that. Feeling low or alone can shrink the world. What's one person or place — even a small one — where you've felt a little safer lately?";
    }
    return "Thanks for opening up — I'm here with you. What feels most important to talk through a bit more right now? You can go as slow as you need.";
  }
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
      throw Exception('GROQ_API_KEY is not set');
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
