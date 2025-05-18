import 'firestore_service.dart';
import '../utils/firebase_user_utils.dart';

/// Generic entity data provider for categories and paymentMethods.
class EntityDataProvider<T> {
  final FirestoreService firestoreService;
  final String entityType; // 'categories' or 'paymentMethods'

  EntityDataProvider(
      {required this.firestoreService, required this.entityType});

  Future<List<T>> fetchEntities() async {
    return await withCurrentUserAsync((user) async {
          if (entityType == 'categories') {
            final cats = await firestoreService.getCategories(user.uid).first;
            cats.sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            return cats as List<T>;
          } else if (entityType == 'paymentMethods') {
            final accs =
                await firestoreService.getPaymentMethods(user.uid).first;
            accs.sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            return accs as List<T>;
          }
          return <T>[];
        }) ??
        <T>[];
  }
}
