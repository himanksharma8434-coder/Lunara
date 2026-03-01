import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'cycle_provider.dart';

class AIProvider with ChangeNotifier {
  final GenerativeModel _model;
  List<Map<String, String>> messages = [];
  bool isLoading = false;

  AIProvider({required String apiKey})
      : _model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);

  Future<void> askLunara(String userPrompt, CycleProvider cycle) async {
    messages.add({"role": "user", "content": userPrompt});
    isLoading = true;
    notifyListeners();

    try {
      // We wrap the user's question with their health data
      final content = [
        Content.text("${cycle.aiUserContext} \n Question: $userPrompt")
      ];
      final response = await _model.generateContent(content);

      messages.add({
        "role": "ai",
        "content": response.text ?? "I'm not sure, try again."
      });
    } catch (e) {
      messages
          .add({"role": "ai", "content": "Connection error. Check your key!"});
    }

    isLoading = false;
    notifyListeners();
  }
}
