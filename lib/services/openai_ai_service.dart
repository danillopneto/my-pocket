import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'ai_service.dart';

/// Implementation of AiService using OpenAI API.
class OpenAiAiService extends AiService {
  late final String apiKey;
  final String apiEndpoint = 'https://api.openai.com/v1/chat/completions';
  final String defaultModel =
      'gpt-4.1-nano'; // GPT-4.1 Nano - cheapest model with vision capabilities
  OpenAiAiService() {
    apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      throw Exception(
          'OpenAI API key not found. Please add OPENAI_API_KEY to your .env file.');
    }
  }
  @override
  Future<String> analyzePrompt(String prompt) async {
    final url = Uri.parse(apiEndpoint);
    final body = jsonEncode({
      'model': defaultModel,
      'messages': [
        {
          'role': 'user',
          'content': prompt,
        }
      ],
      'max_tokens': 4000,
      'temperature': 0.7,
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    return _handleResponse(response);
  }

  @override
  Future<String> analyzeFile(File file, {String? userPrompt}) async {
    final String mimeType = _getMimeType(file.path);

    // Check if the file is an image that can be analyzed
    if (_isImageFile(mimeType)) {
      return await _analyzeImage(file, userPrompt);
    } else if (_isTextFile(mimeType)) {
      return await _analyzeTextFile(file, userPrompt);
    } else {
      throw Exception('Unsupported file type: $mimeType');
    }
  }

  /// Analyzes image files using OpenAI's vision capabilities
  Future<String> _analyzeImage(File file, String? userPrompt) async {
    final url = Uri.parse(apiEndpoint);
    final Uint8List fileData = await file.readAsBytes();
    final String fileBase64 = base64Encode(fileData);
    final String mimeType = _getMimeType(file.path);

    // Construct the content array for multimodal input
    final List<Map<String, dynamic>> content = [];

    // Add text prompt if provided, with explicit instruction about image analysis
    String finalPrompt = userPrompt ?? 'Please analyze this image';
    if (!finalPrompt.toLowerCase().contains('image') &&
        !finalPrompt.toLowerCase().contains('picture')) {
      finalPrompt = 'Please analyze this image: $finalPrompt';
    }

    content.add({
      'type': 'text',
      'text': finalPrompt,
    });

    // Add image data
    content.add({
      'type': 'image_url',
      'image_url': {
        'url': 'data:$mimeType;base64,$fileBase64',
        'detail': 'high', // Use high detail for better analysis
      },
    });

    final body = jsonEncode({
      'model': defaultModel,
      'messages': [
        {
          'role': 'user',
          'content': content,
        }
      ],
      'max_tokens': 4000,
      'temperature': 0.7,
    });

    // Debug: Print request structure (without full base64 data)
    print('OpenAI _analyzeImage - Model: $defaultModel');
    print(
        'OpenAI _analyzeImage - Content types: ${content.map((c) => c['type']).join(', ')}');
    print('OpenAI _analyzeImage - MIME type: $mimeType');
    print('OpenAI _analyzeImage - Base64 length: ${fileBase64.length}');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    return _handleResponse(response);
  }

  /// Analyzes text files by reading content and sending as text prompt
  Future<String> _analyzeTextFile(File file, String? userPrompt) async {
    final String fileContent = await file.readAsString();

    String prompt = '';
    if (userPrompt != null && userPrompt.isNotEmpty) {
      prompt = '$userPrompt\n\nFile content:\n$fileContent';
    } else {
      prompt = 'Please analyze this file content:\n\n$fileContent';
    }

    return await analyzePrompt(prompt);
  }

  /// Determines the MIME type of a file based on its extension.
  String _getMimeType(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    switch (ext) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      case '.pdf':
        return 'application/pdf';
      case '.txt':
        return 'text/plain';
      case '.json':
        return 'application/json';
      case '.csv':
        return 'text/csv';
      case '.md':
        return 'text/markdown';
      case '.html':
      case '.htm':
        return 'text/html';
      case '.xml':
        return 'text/xml';
      case '.yaml':
      case '.yml':
        return 'text/yaml';
      default:
        return 'application/octet-stream';
    }
  }

  /// Checks if the MIME type represents an image file
  bool _isImageFile(String mimeType) {
    return mimeType.startsWith('image/') &&
        !mimeType.contains('svg'); // SVG is not supported by OpenAI vision
  }

  /// Checks if the MIME type represents a text file
  bool _isTextFile(String mimeType) {
    return mimeType.startsWith('text/') ||
        mimeType == 'application/json' ||
        mimeType == 'text/yaml';
  }

  @override
  void setProvider(String providerName) {
    // No-op for now. Add logic if supporting multiple providers.
  }

  /// Sets a custom model to use for requests
  void setModel(String model) {
    // This could be implemented to allow switching between different OpenAI models
    // For now, we'll keep using the default model
  }

  /// Gets available OpenAI models (ordered by cost-effectiveness for vision tasks)
  List<String> getAvailableModels() {
    return [
      'gpt-4o-mini', // Cheapest model with vision capabilities
      'gpt-4o', // GPT-4 Omni (more expensive but higher quality)
      'gpt-4-turbo', // GPT-4 Turbo (vision support, high cost)
      'gpt-4', // GPT-4 (vision support, highest cost)
      'gpt-3.5-turbo', // GPT-3.5 Turbo (text only, no vision)
    ];
  }

  /// Handles HTTP response and extracts content or throws appropriate error
  String _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices']?[0]?['message']?['content'] ?? '';
    } else if (response.statusCode == 401) {
      throw Exception(
          'OpenAI API authentication failed. Please check your API key.');
    } else if (response.statusCode == 429) {
      throw Exception(
          'OpenAI API rate limit exceeded. Please try again later.');
    } else if (response.statusCode == 400) {
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Bad request';
        throw Exception('OpenAI API error: $errorMessage');
      } catch (e) {
        throw Exception(
            'OpenAI API bad request (${response.statusCode}): ${response.body}');
      }
    } else {
      throw Exception(
          'Failed to get response from OpenAI (${response.statusCode}): ${response.body}');
    }
  }

  @override
  Future<String> analyzeImageBytes(Uint8List bytes, String mimeType,
      {String? userPrompt}) async {
    final url = Uri.parse(apiEndpoint);
    final String fileBase64 = base64Encode(bytes);

    // Construct the content array for multimodal input
    final List<Map<String, dynamic>> content = [];

    // Add text prompt if provided, with explicit instruction about image analysis
    String finalPrompt = userPrompt ?? 'Please analyze this image';
    if (!finalPrompt.toLowerCase().contains('image') &&
        !finalPrompt.toLowerCase().contains('picture')) {
      finalPrompt = 'Please analyze this image: $finalPrompt';
    }

    content.add({
      'type': 'text',
      'text': finalPrompt,
    });

    // Add image data
    content.add({
      'type': 'image_url',
      'image_url': {
        'url': 'data:$mimeType;base64,$fileBase64',
        'detail': 'high', // Use high detail for better analysis
      },
    });
    final body = jsonEncode({
      'model': defaultModel,
      'messages': [
        {
          'role': 'user',
          'content': content,
        }
      ],
      'max_tokens': 4000,
      'temperature': 0.7,
    });

    // Debug: Print request structure (without full base64 data)
    print('OpenAI analyzeImageBytes - Model: $defaultModel');
    print(
        'OpenAI analyzeImageBytes - Content types: ${content.map((c) => c['type']).join(', ')}');
    print('OpenAI analyzeImageBytes - MIME type: $mimeType');
    print('OpenAI analyzeImageBytes - Base64 length: ${fileBase64.length}');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: body,
    );

    return _handleResponse(response);
  }
}
