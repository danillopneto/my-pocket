import '../services/firestore_service.dart';
import '../utils/firebase_user_utils.dart';

class MigrationService {
  final FirestoreService _firestoreService = FirestoreService();

  // Run all available migrations for the current user
  Future<void> runMigrationsIfNeeded() async {
    try {
      await withCurrentUserAsync((user) async {
        print('Checking migrations for user: ${user.uid}');

        // Check and run itemNames migration
        final needsItemNamesMigration =
            await _firestoreService.isMigrationNeeded(user.uid);

        if (needsItemNamesMigration) {
          print('Running itemNames migration...');
          await _firestoreService.migrateExpenseItemNames(user.uid);
          print('ItemNames migration completed');
        } else {
          print('ItemNames migration not needed');
        }
      });
    } catch (e) {
      print('Error running migrations: $e');
      // Don't rethrow - migrations should not break the app
    }
  }

  // Run migration in background without blocking the UI
  void runMigrationsInBackground() {
    Future.delayed(const Duration(seconds: 2), () {
      runMigrationsIfNeeded();
    });
  }
}
