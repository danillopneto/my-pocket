import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web/web.dart' as web;

class FileViewerDialog extends StatelessWidget {
  final String fileUrl;
  final String? fileName;

  const FileViewerDialog({
    super.key,
    required this.fileUrl,
    this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  fileName ?? 'file_viewer'.tr(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    // Download button
                    IconButton(
                      onPressed: () => _downloadFile(context),
                      icon: const Icon(Icons.download),
                      tooltip: 'download_file'.tr(),
                    ),
                    // Close button
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      tooltip: 'close'.tr(),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            // File content
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildFileContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileContent(BuildContext context) {
    // Check if it's an image file
    if (_isImageFile(fileUrl)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          fileUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'file_error'.tr(),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
        ),
      );
    } else if (_isPdfFile(fileUrl)) {
      // For PDF files, show a message to open in new tab on web
      if (kIsWeb) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.picture_as_pdf,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'PDF Document',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                fileName ?? 'document.pdf',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _openInNewTab(fileUrl),
                icon: const Icon(Icons.open_in_new),
                label: Text('Open in New Tab'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _downloadFile(context),
                icon: const Icon(Icons.download),
                label: Text('download_file'.tr()),
              ),
            ],
          ),
        );
      } else {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.picture_as_pdf,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'PDF Document',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                fileName ?? 'document.pdf',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _downloadFile(context),
                icon: const Icon(Icons.download),
                label: Text('download_file'.tr()),
              ),
            ],
          ),
        );
      }
    } else {
      // For other file types, show a generic file icon and download option
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.insert_drive_file,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'File',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              fileName ?? 'document',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _downloadFile(context),
              icon: const Icon(Icons.download),
              label: Text('download_file'.tr()),
            ),
          ],
        ),
      );
    }
  }

  bool _isImageFile(String url) {
    final lowercaseUrl = url.toLowerCase();
    return lowercaseUrl.contains('.jpg') ||
        lowercaseUrl.contains('.jpeg') ||
        lowercaseUrl.contains('.png') ||
        lowercaseUrl.contains('.gif') ||
        lowercaseUrl.contains('.webp') ||
        lowercaseUrl.contains('.bmp');
  }

  bool _isPdfFile(String url) {
    return url.toLowerCase().contains('.pdf');
  }

  void _downloadFile(BuildContext context) {
    if (kIsWeb) {
      // For web, use web.window.open to trigger download
      web.window.open(fileUrl, '_blank');
    } else {
      // For mobile platforms, you might want to use a package like url_launcher
      // or file downloader package
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download functionality not implemented for mobile'),
        ),
      );
    }
  }

  void _openInNewTab(String url) {
    if (kIsWeb) {
      web.window.open(url, '_blank');
    }
  }
}
