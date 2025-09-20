import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:intl/intl.dart';
import '../controllers/document_controller.dart';
import '../models/document.dart';
import '../widgets/pdf_viewer.dart';

class DocumentDetailScreen extends StatelessWidget {
  final Document document;

  const DocumentDetailScreen({
    super.key,
    required this.document,
  });

  @override
  Widget build(BuildContext context) {
    final DocumentController controller = Get.find<DocumentController>();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(document.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareDocument(controller),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, controller, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'rename',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Rename'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Document preview
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: _buildDocumentPreview(context),
            ),
          ),
          
          // Document info
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Name', document.name),
                const SizedBox(height: 8),
                _buildInfoRow('Type', document.type.name.toUpperCase()),
                const SizedBox(height: 8),
                _buildInfoRow('Size', _formatFileSize(document.fileSize)),
                const SizedBox(height: 8),
                _buildInfoRow('Created', _formatDate(document.createdAt)),
                const SizedBox(height: 8),
                _buildInfoRow('Modified', _formatDate(document.updatedAt)),
                if (document.appliedFilter != FilterType.original) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('Filter', document.appliedFilter.name),
                ],
                if (document.rotation != 0) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow('Rotation', '${document.rotation}°'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentPreview(BuildContext context) {
    final file = File(document.filePath);
    
    if (!file.existsSync()) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.white54,
            ),
            SizedBox(height: 16),
            Text(
              'File not found',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    if (document.type == DocumentType.pdf) {
      // For PDF files, show a clickable preview that opens the PDF viewer
      return GestureDetector(
        onTap: () => _openPdfViewer(context),
        child: Container(
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.picture_as_pdf,
                  size: 80,
                  color: Colors.white70,
                ),
                const SizedBox(height: 20),
                const Text(
                  'PDF Document',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Tap to View PDF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // For image files, use PhotoView
      return PhotoView(
        imageProvider: FileImage(file),
        backgroundDecoration: const BoxDecoration(
          color: Colors.black,
        ),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 3,
        initialScale: PhotoViewComputedScale.contained,
        heroAttributes: PhotoViewHeroAttributes(tag: document.id),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy - HH:mm').format(date);
  }

  void _openPdfViewer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PdfViewer(
          filePath: document.filePath,
          fileName: document.name,
        ),
      ),
    );
  }

  void _shareDocument(DocumentController controller) {
    controller.shareDocument(document.id);
  }

  void _handleMenuAction(BuildContext context, DocumentController controller, String action) {
    switch (action) {
      case 'rename':
        _showRenameDialog(context, controller);
        break;
      case 'delete':
        _showDeleteDialog(context, controller);
        break;
    }
  }

  void _showRenameDialog(BuildContext context, DocumentController controller) {
    final textController = TextEditingController(text: document.name);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Document name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newName = textController.text.trim();
              if (newName.isNotEmpty && newName != document.name) {
                Navigator.of(context).pop();
                controller.renameDocument(document.id, newName);
                // Pop back to home screen to see updated name
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, DocumentController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${document.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              controller.deleteDocument(document.id);
              // Pop back to home screen
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}