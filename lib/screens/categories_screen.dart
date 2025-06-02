// Categories management screen
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/category.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/entity_crud_list.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/snackbar_helper.dart';
import '../utils/firebase_user_utils.dart';
import '../widgets/scaffold_with_drawer.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = withCurrentUser<Widget>((user) {
      return StreamBuilder<List<Category>>(
        stream: _firestoreService.getCategories(user.uid),
        builder: (context, snapshot) {
          final categories = snapshot.data ?? [];
          return ScaffoldWithDrawer(
            selected: 'categories',
            titleKey: 'categories',
            body: EntityCrudList<Category>(
              entities: categories,
              labelText: 'category_name',
              getName: (cat) => cat.name,
              onAdd: (name) async {
                await _firestoreService.addCategory(
                    user.uid, Category(name: name));
              },
              onEdit: (cat, name) async {
                await _firestoreService.updateCategory(
                    user.uid, Category(id: cat.id, name: name));
              },
              onDelete: (cat) async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => ConfirmDeleteDialog(
                    content: 'are_you_sure_delete_category'.tr(),
                  ),
                );
                if (confirm == true && cat.id != null) {
                  await _firestoreService.deleteCategory(user.uid, cat.id!);
                  showAppSnackbar(context, 'category_deleted'.tr(),
                      backgroundColor: Colors.green);
                }
              },
              emptyText: 'no_categories',
              addLabel: 'add',
              saveLabel: 'save',
              entityName: 'category',
            ),
          );
        },
      );
    });
    return result ??
        Scaffold(
          appBar: AppBar(title: Text('categories'.tr())),
          body: Center(child: Text('login'.tr())),
        );
  }
}
