import 'dart:convert';
import '../models/expense.dart';
import '../models/category.dart';
import '../models/payment_method.dart';
import '../models/dashboard_summary.dart';
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
  }) async {
    if (expenses.isEmpty) {
      return 'No expenses to analyze.';
    }
    // Build lookup maps for category and payment method names
    final categoryMap = {for (var c in categories) c.id: c.name};
    final paymentMethodMap = {for (var p in paymentMethods) p.id: p.name};
    // Prepare a compact JSON list of expenses for the AI, using names
    final expenseList = expenses
        .map((e) => {
              'description': e.description,
              'value': e.value,
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
      summaryText =
          "\n\nSummary Data:\nTotal: R\$${summary.total.toStringAsFixed(2)}, Average per Month: 24${summary.avgPerMonth.toStringAsFixed(2)}, Most Expensive: "
          '${summary.mostExp != null ? '${summary.mostExp!.description} (R\$${summary.mostExp!.value.toStringAsFixed(2)})' : 'N/A'}';
    }
    final prompt =
        """Iterate over theses expenses and generate a summary for me about them, tell me where I've been spending more money and other highlights. Also provide me instructions on where I could improve my spending.\n\n$summaryText\n\nExpenses:\n$expensesJson""";
    return await _aiService.analyzePrompt(prompt);
  }
}
