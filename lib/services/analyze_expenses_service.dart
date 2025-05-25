import 'dart:convert';

import '../models/expense.dart';
import '../models/category.dart';
import '../models/payment_method.dart';
import '../models/dashboard_summary.dart';
import '../services/user_preferences_service.dart';
import '../services/currency_format_service.dart';
import 'ai_service_factory.dart';
import 'ai_service.dart';

class AnalyzeExpensesService {
  final AiService _aiService;
  AnalyzeExpensesService({AiService? aiService})
      : _aiService = aiService ?? AiServiceFactory.getCurrentService();
  Future<String> analyzeExpenses(
    List<Expense> expenses, {
    required List<Category> categories,
    required List<PaymentMethod> paymentMethods,
    DashboardSummary? summary,
    UserPreferences? userPreferences,
  }) async {
    if (expenses.isEmpty) {
      // Return message in user's preferred language
      final userLanguage = userPreferences?.language ?? 'pt';
      final noExpensesMessages = {
        'pt': 'Não há despesas para analisar.',
        'en': 'No expenses to analyze.',
        'es': 'No hay gastos para analizar.',
      };
      return noExpensesMessages[userLanguage] ?? noExpensesMessages['pt']!;
    }

    // Build lookup maps for category and payment method names
    final categoryMap = {for (var c in categories) c.id: c.name};
    final paymentMethodMap = {for (var p in paymentMethods) p.id: p.name};

    // Use user preferences for currency formatting, or fallback to defaults
    final currencySymbol = userPreferences?.currencySymbol ?? 'R\$';
    final currencyFormat = userPreferences?.currencyFormat ?? '0.000,00';

    // Prepare a compact JSON list of expenses for the AI, using names and formatted values
    final expenseList = expenses
        .map((e) => {
              'description': e.description,
              'value': CurrencyFormatService.formatCurrencyWithPreferences(
                e.value,
                currencySymbol: currencySymbol,
                currencyFormat: currencyFormat,
              ),
              'place': e.place,
              'date': e.date.toIso8601String(),
              'category': categoryMap[e.categoryId] ?? e.categoryId,
              'paymentMethod':
                  paymentMethodMap[e.paymentMethodId] ?? e.paymentMethodId,
            })
        .toList();

    final expensesJson = jsonEncode(expenseList);

    // Optionally include summary in the prompt for AI
    String summaryText = '';
    if (summary != null) {
      final formattedTotal =
          CurrencyFormatService.formatCurrencyWithPreferences(
        summary.total,
        currencySymbol: currencySymbol,
        currencyFormat: currencyFormat,
      );

      final formattedAvgPerDay =
          CurrencyFormatService.formatCurrencyWithPreferences(
        summary.avgPerDay,
        currencySymbol: currencySymbol,
        currencyFormat: currencyFormat,
      );

      final formattedMostExp = summary.mostExp != null
          ? CurrencyFormatService.formatCurrencyWithPreferences(
              summary.mostExp!.value,
              currencySymbol: currencySymbol,
              currencyFormat: currencyFormat,
            )
          : 'N/A';

      summaryText =
          "\n\nSummary Data:\nTotal: $formattedTotal, Average per Day: $formattedAvgPerDay, Most Expensive: "
          '${summary.mostExp != null ? '${summary.mostExp!.description} ($formattedMostExp)' : 'N/A'}';
    } // Get user's preferred language or fallback to Portuguese
    final userLanguage = userPreferences?.language ?? 'pt';
    final languageMap = {
      'pt': 'Portuguese (Brazil)',
      'en': 'English',
      'es': 'Spanish',
    };
    final languageName = languageMap[userLanguage] ?? 'Portuguese (Brazil)';

    final prompt =
        """You are a personal finance assistant analyzing expense data. Please respond entirely in $languageName.

TASK: Analyze the following expenses and provide a comprehensive financial summary.

REQUIREMENTS:
- Write your entire response in $languageName
- Analyze spending patterns and identify where most money is being spent
- Highlight interesting trends, categories with high spending, or notable expenses
- Provide practical, actionable recommendations for improving spending habits
- Use a friendly, helpful, and encouraging tone
- Structure your response clearly with sections or bullet points
- Include specific insights about categories, payment methods, or time patterns if relevant

USER LANGUAGE: $languageName
CURRENCY FORMAT: $currencySymbol with format $currencyFormat

$summaryText

EXPENSE DATA:
$expensesJson

Please provide your analysis in $languageName:""";
    return await _aiService.analyzePrompt(prompt);
  }
}
