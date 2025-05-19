import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class DrawerNavItem {
  final String route;
  final String labelKey;
  final IconData icon;
  final String? selectedKey;
  final List<DrawerNavItem>? children;
  final bool isExpansion;

  const DrawerNavItem({
    required this.route,
    required this.labelKey,
    required this.icon,
    this.selectedKey,
    this.children,
    this.isExpansion = false,
  });
}

final List<DrawerNavItem> drawerNavItems = [
  DrawerNavItem(
    route: '/dashboard',
    labelKey: 'dashboard',
    icon: Icons.dashboard,
    selectedKey: 'dashboard',
  ),
  DrawerNavItem(
    route: '',
    labelKey: 'expenses_control',
    icon: Icons.account_balance_wallet,
    isExpansion: true,
    children: [
      DrawerNavItem(
        route: '/expenses',
        labelKey: 'add_expense',
        icon: Icons.add_chart,
        selectedKey: 'expenses',
      ),
      DrawerNavItem(
        route: '/expenses-list',
        labelKey: 'expenses_list',
        icon: Icons.list,
        selectedKey: 'expenses-list',
      ),
      DrawerNavItem(
        route: '/categories',
        labelKey: 'categories',
        icon: Icons.category,
        selectedKey: 'categories',
      ),
      DrawerNavItem(
        route: '/paymentMethods',
        labelKey: 'payment_methods',
        icon: Icons.account_balance_wallet,
        selectedKey: 'paymentMethods',
      ),
      DrawerNavItem(
        route: '/bulk-add-expenses',
        labelKey: 'bulk_paste',
        icon: Icons.paste,
        selectedKey: 'bulk-add-expenses',
      ),
    ],
  ),
];

const DrawerNavItem settingsNavItem = DrawerNavItem(
  route: '/settings',
  labelKey: 'settings',
  icon: Icons.settings,
  selectedKey: 'settings',
);

class AppDrawer extends StatelessWidget {
  final String selected;
  const AppDrawer({super.key, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              color: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              height: 64,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    'images/logo_x32.png',
                    height: 32,
                    width: 32,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'app_title'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Main navigation items
            ...drawerNavItems.map((item) => _buildNavItem(context, item)),
            Spacer(),
            // Divider before settings
            const Divider(),
            // Settings at the bottom
            _buildNavItem(context, settingsNavItem),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, DrawerNavItem item) {
    if (item.isExpansion && item.children != null) {
      return ExpansionTile(
        leading: Icon(item.icon),
        title: Text(item.labelKey.tr()),
        initiallyExpanded: item.children!.any((c) => c.selectedKey == selected),
        children: item.children!
            .map((child) => _buildNavItem(context, child))
            .toList(),
      );
    } else {
      return ListTile(
        leading: Icon(item.icon),
        title: Text(item.labelKey.tr()),
        selected: item.selectedKey == selected,
        onTap: () {
          if (item.route.isNotEmpty &&
              ModalRoute.of(context)?.settings.name != item.route) {
            Navigator.pushReplacementNamed(context, item.route);
          }
        },
      );
    }
  }
}
