import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

class GroqResponse {
  final String? text;
  GroqResponse(this.text);
}

class GroqChatSession {
  final GroqModel model;
  final List<Map<String, String>> history;

  GroqChatSession({required this.model, required List<Map<String, String>> history})
      : history = List.from(history);

  Future<GroqResponse> sendMessage(Content content) async {
    // Extract text from the Content object
    String text = '';
    for (var part in content.parts) {
      if (part is TextPart) {
        text += part.text;
      }
    }

    // Append the user's message to the session history
    history.add({"role": "user", "content": text});

    try {
      final responseText = await model.generateChatCompletion(
        messages: history,
      );
      // Append the assistant's response to the session history
      if (responseText != null) {
        history.add({"role": "assistant", "content": responseText});
      }
      return GroqResponse(responseText);
    } catch (e) {
      // If failed, remove the user message so we don't pollute history
      if (history.isNotEmpty) {
        history.removeLast();
      }
      rethrow;
    }
  }
}

class GroqModel {
  final String model;
  final String apiKey;
  final String? systemInstruction;

  GroqModel({
    required this.model,
    required this.apiKey,
    this.systemInstruction,
  });

  GroqChatSession startChat({required List<Content> history}) {
    // Map list of Google Generative AI Content objects to Groq JSON messages
    final mappedHistory = <Map<String, String>>[];
    for (var content in history) {
      String text = '';
      for (var part in content.parts) {
        if (part is TextPart) {
          text += part.text;
        }
      }
      final role = content.role == 'user' ? 'user' : 'assistant';
      mappedHistory.add({"role": role, "content": text});
    }

    return GroqChatSession(model: this, history: mappedHistory);
  }

  Future<GroqResponse> generateContent(Iterable<Content> contents) async {
    final messages = <Map<String, String>>[];
    
    for (var content in contents) {
      String text = '';
      for (var part in content.parts) {
        if (part is TextPart) {
          text += part.text;
        }
      }
      final role = content.role == 'user' ? 'user' : 'assistant';
      messages.add({"role": role, "content": text});
    }

    final text = await generateChatCompletion(messages: messages);
    return GroqResponse(text);
  }

  Future<String?> generateChatCompletion({
    required List<Map<String, String>> messages,
  }) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
    
    // Construct request messages, prefixing system instruction if available
    final finalMessages = <Map<String, String>>[];
    if (systemInstruction != null && systemInstruction!.isNotEmpty) {
      finalMessages.add({"role": "system", "content": systemInstruction!});
    }
    finalMessages.addAll(messages);

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': finalMessages,
        'temperature': 0.7,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'] as String?;
    } else {
      debugPrint("Groq Error: ${response.statusCode} - ${response.body}");
      throw Exception("Groq API error: ${response.statusCode} - ${response.body}");
    }
  }
}
