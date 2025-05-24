import 'dart:io';
import 'dart:typed_data';

/// Abstract class for AI integration service.
/// Implementations can use different LLM providers (e.g., OpenAI, Azure, Google, etc).
abstract class AiService {
  /// Analyze a prompt and return the AI's response as a string.
  Future<String> analyzePrompt(String prompt);

  /// Analyze a file (e.g., text, PDF, etc) and return the AI's response as a string.
  Future<String> analyzeFile(File file, {String? userPrompt});

  /// Analyze image bytes directly and return the AI's response as a string.
  Future<String> analyzeImageBytes(Uint8List bytes, String mimeType,
      {String? userPrompt});

  /// Optionally, set or change the current LLM provider at runtime.
  void setProvider(String providerName);
}
