import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'ai_service.dart';

/// Implementation of AiService using Google Gemini API.
class GeminiAiService extends AiService {
  late final String apiKey;
  final String apiEndpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro-preview-05-06:generateContent';

  GeminiAiService() {
    apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  @override
  Future<String> analyzePrompt(String prompt) async {
    final url = Uri.parse('$apiEndpoint?key=$apiKey');
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ]
    });
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
    } else {
      throw Exception('Failed to get response from Gemini: ${response.body}');
    }
  }

  @override
  Future<String> analyzeFile(File file, {String? userPrompt}) async {
    final url = Uri.parse('$apiEndpoint?key=$apiKey');
    final String mimeType = _getMimeType(file.path);
    final Uint8List fileData = await file.readAsBytes();
    final String fileBase64 = base64Encode(fileData);

    // Create a multimodal request with the file as an inline part
    final List<Map<String, dynamic>> parts = [];

    // Add file part first for better results with single files
    parts.add({
      'inline_data': {'mime_type': mimeType, 'data': fileBase64}
    });

    // Add the user prompt if provided
    if (userPrompt != null && userPrompt.isNotEmpty) {
      parts.add({'text': userPrompt.trim()});
    }

    final body = jsonEncode({
      'contents': [
        {'parts': parts}
      ]
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
    } else {
      throw Exception('Failed to get response from Gemini: ${response.body}');
    }
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
      case '.heic':
        return 'image/heic';
      case '.heif':
        return 'image/heif';
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
      default:
        return 'application/octet-stream'; // Generic binary data
    }
  }

  @override
  Future<String> analyzeImageBytes(Uint8List bytes, String mimeType,
      {String? userPrompt}) async {
    final url = Uri.parse('$apiEndpoint?key=$apiKey');
    final String fileBase64 = base64Encode(bytes);

    // Create a multimodal request with the image bytes as an inline part
    final List<Map<String, dynamic>> parts = [];

    // Add image part first for better results
    parts.add({
      'inline_data': {'mime_type': mimeType, 'data': fileBase64}
    });

    // Add the user prompt if provided
    if (userPrompt != null && userPrompt.isNotEmpty) {
      parts.add({'text': userPrompt.trim()});
    }

    final body = jsonEncode({
      'contents': [
        {'parts': parts}
      ]
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final String content =
          data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
      return content;
    } else {
      throw Exception('Failed to get response from Gemini: ${response.body}');
    }
  }

  @override
  void setProvider(String providerName) {
    // No-op for now. Add logic if supporting multiple providers.
  }
}
