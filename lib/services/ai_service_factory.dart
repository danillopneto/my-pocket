import 'ai_service.dart';
import 'gemini_ai_service.dart';
import 'openai_ai_service.dart';

/// Factory service for creating and managing AI service instances.
/// Supports multiple AI providers like OpenAI and Google Gemini.
class AiServiceFactory {
  static const String openaiProvider = 'openai';
  static const String geminiProvider = 'gemini';
  static AiService? _currentService;
  static String _currentProvider = openaiProvider; // Default to OpenAI

  /// Get the current AI service instance
  static AiService getCurrentService() {
    if (_currentService == null) {
      _currentService = createService(_currentProvider);
    }
    return _currentService!;
  }

  /// Create a new AI service instance for the specified provider
  static AiService createService(String provider) {
    switch (provider.toLowerCase()) {
      case openaiProvider:
        return OpenAiAiService();
      case geminiProvider:
        return GeminiAiService();
      default:
        throw ArgumentError('Unsupported AI provider: $provider');
    }
  }

  /// Switch to a different AI provider
  static void switchProvider(String provider) {
    if (!isProviderSupported(provider)) {
      throw ArgumentError('Unsupported AI provider: $provider');
    }

    _currentProvider = provider;
    _currentService = createService(provider);
  }

  /// Get the current provider name
  static String getCurrentProvider() {
    return _currentProvider;
  }

  /// Check if a provider is supported
  static bool isProviderSupported(String provider) {
    return getSupportedProviders().contains(provider.toLowerCase());
  }

  /// Get list of all supported providers
  static List<String> getSupportedProviders() {
    return [openaiProvider, geminiProvider];
  }

  /// Get user-friendly display names for providers
  static String getProviderDisplayName(String provider) {
    switch (provider.toLowerCase()) {
      case openaiProvider:
        return 'OpenAI';
      case geminiProvider:
        return 'Google Gemini';
      default:
        return provider;
    }
  }

  /// Get the capabilities of a specific provider
  static Map<String, bool> getProviderCapabilities(String provider) {
    switch (provider.toLowerCase()) {
      case openaiProvider:
        return {
          'text_analysis': true,
          'image_analysis': true,
          'file_analysis': true,
          'multimodal': true,
          'high_quality_vision': true,
        };
      case geminiProvider:
        return {
          'text_analysis': true,
          'image_analysis': true,
          'file_analysis': true,
          'multimodal': true,
          'high_quality_vision': true,
        };
      default:
        return {};
    }
  }
}
