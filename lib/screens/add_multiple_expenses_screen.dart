import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/scaffold_with_drawer.dart';

class AddMultipleExpensesScreen extends StatefulWidget {
  const AddMultipleExpensesScreen({super.key});

  @override
  State<AddMultipleExpensesScreen> createState() =>
      _AddMultipleExpensesScreenState();
}

class _AddMultipleExpensesScreenState extends State<AddMultipleExpensesScreen> {
  @override
  Widget build(BuildContext context) {
    return ScaffoldWithDrawer(
      selected: 'expenses',
      titleKey: 'add_multiple_expenses',
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_box_outlined,
                size: 120,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: (0.6 * 255).toDouble()),
              ),
              const SizedBox(height: 24),
              Text(
                'add_multiple_expenses'.tr(),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'This feature will allow you to add multiple expenses at once.\nComing soon!',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32)
            ],
          ),
        ),
      ),
    );
  }
}
