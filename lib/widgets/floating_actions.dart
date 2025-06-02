import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class FloatingActions extends StatefulWidget {
  const FloatingActions({super.key});

  @override
  State<FloatingActions> createState() => _FloatingActionsState();
}

class _FloatingActionsState extends State<FloatingActions>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _onActionSelected(VoidCallback action) {
    // Close the menu first
    _toggleExpanded();
    // Execute the action after a short delay to allow animation to complete
    Future.delayed(const Duration(milliseconds: 100), action);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Action buttons (shown when expanded)
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.scale(
              scale: _animation.value,
              child: Opacity(
                opacity: _animation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Add Multiple Expenses button
                    if (_isExpanded) ...[
                      _buildActionButton(
                        icon: Icons.add_box,
                        label: 'add_multiple_expenses'.tr(),
                        onPressed: () => _onActionSelected(() =>
                            Navigator.pushNamed(context, '/add-expenses')),
                      ),
                      const SizedBox(height: 12),
                      // Add Expense button
                      _buildActionButton(
                        icon: Icons.add,
                        label: 'add_expense'.tr(),
                        onPressed: () => _onActionSelected(
                            () => Navigator.pushNamed(context, '/add-expense')),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
        // Main FAB
        FloatingActionButton(
          onPressed: _toggleExpanded,
          tooltip: _isExpanded ? 'close'.tr() : 'open'.tr(),
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0, // 45 degrees when expanded
            duration: const Duration(milliseconds: 250),
            child: Icon(_isExpanded ? Icons.close : Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(24),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
