// Accounts management screen
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/account.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/entity_crud_list.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/snackbar_helper.dart';
import '../utils/firebase_user_utils.dart';
import '../widgets/scaffold_with_drawer.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
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
      return StreamBuilder<List<Account>>(
        stream: _firestoreService.getAccounts(user.uid),
        builder: (context, snapshot) {
          final accounts = (snapshot.data ?? []);
          return ScaffoldWithDrawer(
            selected: 'accounts',
            titleKey: 'accounts',
            body: EntityCrudList<Account>(
              entities: accounts,
              labelText: 'account_name',
              getName: (acc) => acc.name,
              onAdd: (name) async {
                await _firestoreService.addAccount(
                    user.uid, Account(name: name));
              },
              onEdit: (acc, name) async {
                await _firestoreService.updateAccount(
                    user.uid, Account(id: acc.id, name: name));
              },
              onDelete: (acc) async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => ConfirmDeleteDialog(
                    content: 'are_you_sure_delete_account'.tr(),
                  ),
                );
                if (confirm == true && acc.id != null) {
                  await _firestoreService.deleteAccount(user.uid, acc.id!);
                  showAppSnackbar(context, 'account_deleted'.tr(),
                      backgroundColor: Colors.green);
                }
              },
              emptyText: 'no_accounts',
              addLabel: 'add',
              saveLabel: 'save',
              entityName: 'account',
            ),
          );
        },
      );
    });
    return result ??
        Scaffold(
          appBar: AppBar(title: Text('accounts'.tr())),
          body: Center(child: Text('login'.tr())),
        );
  }
}
