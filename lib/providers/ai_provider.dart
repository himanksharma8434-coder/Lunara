import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'cycle_provider.dart';
import '../services/ai_rate_limit_service.dart';
import '../services/plus_service.dart';
import '../services/groq_service.dart';

class AIProvider with ChangeNotifier {
  final GroqModel _model;
  List<Map<String, String>> messages = [];
  bool isLoading = false;

  AIProvider({required String apiKey}) : _model = _initializeModel(apiKey);

  static GroqModel _initializeModel(String apiKey) {
    final List<String> potentialModels = PlusService.instance.availableModels;

    for (var modelName in potentialModels) {
      try {
        return GroqModel(model: modelName, apiKey: apiKey);
      } catch (e) {
        debugPrint("AIProvider: Failed with $modelName: $e");
      }
    }
    // Fallback
    return GroqModel(model: 'qwen-2.5-32b', apiKey: apiKey);
  }

  Future<void> askLunara(String userPrompt, CycleProvider cycle) async {
    messages.add({"role": "user", "content": userPrompt});
    isLoading = true;
    notifyListeners();

    try {
      // Check Rate Limit
      final canRequest = await AIRateLimitService.instance.canMakeRequest();
      if (!canRequest) {
        messages.add({
          "role": "ai",
          "content": "Daily limit reached (${PlusService.freeDailyLimit}). Upgrade to Plus for unlimited! 💎"
        });
        isLoading = false;
        notifyListeners();
        return;
      }

      // We wrap the user's question with their health data
      final content = [
        Content.text("${cycle.aiUserContext} \n Question: $userPrompt")
      ];
      final response = await _model.generateContent(content);

      if (response.text != null) {
        await AIRateLimitService.instance.incrementRequestCount();
      }

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
