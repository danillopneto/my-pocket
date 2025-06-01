import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;

class ReceiptUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Uploads a receipt image to Firebase Storage
  /// Uses industry standard file organization: receipts/{userId}/{year}/{month}/{filename}
  /// Returns the download URL of the uploaded file
  static Future<String> uploadReceiptImage({
    required Uint8List imageBytes,
    required String originalFileName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final year = now.year.toString();
      final month = now.month.toString().padLeft(2, '0');

      // Generate unique filename to prevent collisions
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = path.extension(originalFileName).toLowerCase();
      final fileName = 'receipt_$timestamp$fileExtension';

      // Industry standard file organization structure
      final filePath = 'receipts/${user.uid}/$year/$month/$fileName';

      // Create reference to Firebase Storage
      final storageRef = _storage.ref().child(filePath);

      // Set metadata for better file management
      final metadata = SettableMetadata(
        contentType: _getContentType(fileExtension),
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': now.toIso8601String(),
          'originalFileName': originalFileName,
        },
      );

      // Upload the file
      final uploadTask = storageRef.putData(imageBytes, metadata);

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload receipt: $e');
    }
  }

  /// Delete a receipt image from Firebase Storage
  static Future<void> deleteReceiptImage(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete receipt: $e');
    }
  }

  /// Get all receipts for the current user
  static Future<List<String>> getUserReceiptUrls() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final receiptsRef = _storage.ref().child('receipts/${user.uid}');
      final result = await receiptsRef.listAll();

      List<String> urls = [];
      for (final item in result.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }

      return urls;
    } catch (e) {
      throw Exception('Failed to get user receipts: $e');
    }
  }

  /// Get content type based on file extension
  static String _getContentType(String extension) {
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  /// Validate file before upload
  static bool isValidReceiptFile(String fileName, int fileSizeBytes) {
    // Check file extension
    final extension = path.extension(fileName).toLowerCase();
    final allowedExtensions = [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
      '.pdf'
    ];

    if (!allowedExtensions.contains(extension)) {
      return false;
    }

    // Check file size (max 10MB)
    const maxSizeBytes = 10 * 1024 * 1024; // 10MB
    if (fileSizeBytes > maxSizeBytes) {
      return false;
    }

    return true;
  }

  /// Get storage usage for current user
  static Future<Map<String, dynamic>> getUserStorageInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final receiptsRef = _storage.ref().child('receipts/${user.uid}');
      final result = await receiptsRef.listAll();

      int totalFiles = 0;
      int totalSizeBytes = 0;

      for (final item in result.items) {
        final metadata = await item.getMetadata();
        totalFiles++;
        totalSizeBytes += metadata.size ?? 0;
      }

      return {
        'totalFiles': totalFiles,
        'totalSizeBytes': totalSizeBytes,
        'totalSizeMB': (totalSizeBytes / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      throw Exception('Failed to get storage info: $e');
    }
  }
}
