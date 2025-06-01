// Storage cleanup utilities for orphaned files
import '../services/receipt_upload_service.dart';
import '../services/firestore_service.dart';
import '../utils/firebase_user_utils.dart';

class StorageCleanupService {
  static final FirestoreService _firestoreService = FirestoreService();

  /// Find and clean up orphaned receipt images
  /// This method compares all receipt URLs in storage with active expenses
  /// and removes any images that are no longer referenced
  static Future<Map<String, dynamic>> cleanupOrphanedReceipts() async {
    try {
      return await withCurrentUserAsync<Map<String, dynamic>>((user) async {
            // Get all receipt URLs from storage
            final allReceiptUrls =
                await ReceiptUploadService.getUserReceiptUrls();

            // Get all active expenses
            final expensesStream = _firestoreService.getExpenses(user.uid);
            final expenses = await expensesStream.first;

            // Get all receipt URLs that are still in use
            final activeReceiptUrls = expenses
                .where((expense) =>
                    expense.receiptImageUrl != null &&
                    expense.receiptImageUrl!.isNotEmpty)
                .map((expense) => expense.receiptImageUrl!)
                .toSet();

            // Find orphaned URLs
            final orphanedUrls = allReceiptUrls
                .where((url) => !activeReceiptUrls.contains(url))
                .toList();

            // Delete orphaned images
            int deletedCount = 0;
            List<String> errors = [];

            for (final url in orphanedUrls) {
              try {
                await ReceiptUploadService.deleteReceiptImage(url);
                deletedCount++;
              } catch (e) {
                errors.add('Failed to delete $url: $e');
              }
            }

            return {
              'totalReceiptsInStorage': allReceiptUrls.length,
              'activeReceipts': activeReceiptUrls.length,
              'orphanedReceipts': orphanedUrls.length,
              'deletedOrphanedReceipts': deletedCount,
              'errors': errors,
            };
          }) ??
          {'error': 'User not authenticated'};
    } catch (e) {
      return {'error': 'Failed to cleanup orphaned receipts: $e'};
    }
  }

  /// Get storage usage statistics
  static Future<Map<String, dynamic>> getStorageUsageStats() async {
    try {
      return await withCurrentUserAsync<Map<String, dynamic>>((user) async {
            final storageInfo = await ReceiptUploadService.getUserStorageInfo();
            final receiptUrls = await ReceiptUploadService.getUserReceiptUrls();

            // Get active expenses count
            final expensesStream = _firestoreService.getExpenses(user.uid);
            final expenses = await expensesStream.first;
            final expensesWithReceipts = expenses
                .where((expense) =>
                    expense.receiptImageUrl != null &&
                    expense.receiptImageUrl!.isNotEmpty)
                .length;

            return {
              ...storageInfo,
              'totalReceiptUrls': receiptUrls.length,
              'expensesWithReceipts': expensesWithReceipts,
              'potentialOrphans': receiptUrls.length - expensesWithReceipts,
            };
          }) ??
          {'error': 'User not authenticated'};
    } catch (e) {
      return {'error': 'Failed to get storage stats: $e'};
    }
  }
}
