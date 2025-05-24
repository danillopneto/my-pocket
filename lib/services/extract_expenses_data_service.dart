import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../models/ai_expense_extracted.dart';
import 'ai_service.dart';
import 'ai_service_factory.dart';
import '../models/category.dart';

class ExtractExpensesDataService {
  final AiService _aiService;
  ExtractExpensesDataService({AiService? aiService})
      : _aiService = aiService ?? AiServiceFactory.getCurrentService();

  Future<AiExpenseExtracted> extractFromFile({
    required File file,
    required List<Category> categories,
  }) async {
    final categoriesList = categories.map((c) => c.name).join(', ');
    final prompt =
        '''Analyze the following image looking for expenses and extract all data in the following JSON format:\n{\n    "description": "{Summary of all expenses}",\n    "value": {sum of all expenses},\n    "place": "{company name}",\n    "date": "{date of the expense}",\n    "category": "{name of the category}"
}\n\nThe expenses should be categorized in the following categories:\n$categoriesList''';
    final aiResponse = await _aiService.analyzeFile(file, userPrompt: prompt);
    final start = aiResponse.indexOf('{');
    final end = aiResponse.lastIndexOf('}');
    if (start == -1 || end == -1) {
      throw FormatException('Invalid JSON response from AI');
    }
    final jsonStr = aiResponse.substring(start, end + 1);
    return AiExpenseExtracted.fromJson(jsonDecode(jsonStr));
  }

  Future<AiExpenseExtracted> extractFromBytes({
    required Uint8List bytes,
    required List<Category> categories,
  }) async {
    final categoriesList = categories.map((c) => c.name).join(', ');
    final prompt =
        '''Analyze the following image looking for expenses and extract all data in the following JSON format:
{
    "description": "{Summary of all expenses}",
    "value": {sum of all expenses},
    "place": "{company name}",
    "date": "{date of the expense}",
    "category": "{name of the category}"
}

The expenses should be categorized in the following categories:
$categoriesList''';

    // Use the new analyzeImageBytes method for proper vision API handling
    final aiResponse = await _aiService.analyzeImageBytes(bytes, 'image/jpeg',
        userPrompt: prompt);
    final start = aiResponse.indexOf('{');
    final end = aiResponse.lastIndexOf('}');
    if (start == -1 || end == -1) {
      throw FormatException('Invalid JSON response from AI');
    }
    final jsonStr = aiResponse.substring(start, end + 1);
    return AiExpenseExtracted.fromJson(jsonDecode(jsonStr));
  }
}
