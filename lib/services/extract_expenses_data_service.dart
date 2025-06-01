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
        '''Analyze the following image looking for expenses and extract all data in the following JSON format:
{
    "description": "{Summary of purchase in user language (max 5 words)}",
    "place": "{company name}",
    "date": "{date of the expense}",
    "category": "{name of the category}",
    "value": {total amount paid as number},
    "items": [
        {
            "name": "{item name}",
            "value": {individual item price as number}
        }
    ]
}

IMPORTANT INSTRUCTIONS:
- ALWAYS extract the "value" (total amount) from the FINAL TOTAL shown on the receipt (after taxes, discounts, etc.)
- Do NOT calculate the total from individual items - use the actual total printed on the receipt
- If there are multiple items in the receipt, list them all in the "items" array with their individual prices
- If there is only one expense item (not a detailed receipt with multiple items), leave the "items" array empty: "items": []
- Look for terms like "TOTAL", "GRAND TOTAL", "AMOUNT DUE", "TOTAL PAID", etc. to find the final amount
- The total should include all taxes, fees, and discounts as shown on the receipt

- The expenses should be categorized in the following categories: $categoriesList''';

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
    "description": "{Summary of purchase in user language (max 5 words)}",
    "place": "{company name}",
    "date": "{date of the expense}",
    "category": "{name of the category}",
    "value": {total amount paid as number},
    "items": [
        {
            "name": "{item name}",
            "value": {individual item price as number}
        }
    ]
}

IMPORTANT INSTRUCTIONS:
- ALWAYS extract the "value" (total amount) from the FINAL TOTAL shown on the receipt (after taxes, discounts, etc.)
- Do NOT calculate the total from individual items - use the actual total printed on the receipt
- If there are multiple items in the receipt, list them all in the "items" array with their individual prices
- If there is only one expense item (not a detailed receipt with multiple items), leave the "items" array empty: "items": []
- Look for terms like "TOTAL", "GRAND TOTAL", "AMOUNT DUE", "TOTAL PAID", etc. to find the final amount
- The total should include all taxes, fees, and discounts as shown on the receipt

- The expenses should be categorized in the following categories: $categoriesList''';

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
