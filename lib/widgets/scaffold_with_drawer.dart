import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'drawer_widget.dart';

/// A reusable Scaffold widget with AppDrawer and AppBar.
class ScaffoldWithDrawer extends StatelessWidget {
  final String selected;
  final String titleKey;
  final Widget body;
  final List<Widget>? actions;
  final FloatingActionButton? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final bool? resizeToAvoidBottomInset;
  final Color? backgroundColor;

  const ScaffoldWithDrawer({
    super.key,
    required this.selected,
    required this.titleKey,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.resizeToAvoidBottomInset,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titleKey.tr()),
        actions: actions,
      ),
      drawer: AppDrawer(selected: selected),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: body,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      bottomSheet: bottomSheet,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: backgroundColor,
    );
  }
}
