// PaymentMethods management screen
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../models/payment-method.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/entity_crud_list.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/snackbar_helper.dart';
import '../utils/firebase_user_utils.dart';
import '../widgets/scaffold_with_drawer.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
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
      return StreamBuilder<List<PaymentMethod>>(
        stream: _firestoreService.getPaymentMethods(user.uid),
        builder: (context, snapshot) {
          final paymentMethods = (snapshot.data ?? []);
          return ScaffoldWithDrawer(
            selected: 'paymentMethods',
            titleKey: 'paymentMethods',
            body: EntityCrudList<PaymentMethod>(
              entities: paymentMethods,
              labelText: 'payment_method_name',
              getName: (acc) => acc.name,
              onAdd: (name) async {
                await _firestoreService.addPaymentMethod(
                    user.uid, PaymentMethod(name: name));
              },
              onEdit: (acc, name) async {
                await _firestoreService.updatePaymentMethod(
                    user.uid, PaymentMethod(id: acc.id, name: name));
              },
              onDelete: (acc) async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => ConfirmDeleteDialog(
                    content: 'are_you_sure_delete_payment_method'.tr(),
                  ),
                );
                if (confirm == true && acc.id != null) {
                  await _firestoreService.deletePaymentMethod(
                      user.uid, acc.id!);
                  showAppSnackbar(context, 'payment_method_deleted'.tr(),
                      backgroundColor: Colors.green);
                }
              },
              emptyText: 'no_payment_methods',
              addLabel: 'add',
              saveLabel: 'save',
              entityName: 'payment_method',
            ),
          );
        },
      );
    });
    return result ??
        Scaffold(
          appBar: AppBar(title: Text('paymentMethods'.tr())),
          body: Center(child: Text('login'.tr())),
        );
  }
}
