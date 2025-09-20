import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../controllers/document_controller.dart';
import '../models/multi_scan_result.dart';
import '../models/scan_result.dart';
import 'camera_screen.dart';
import 'crop_enhance_screen.dart';

class MultiScanScreen extends StatefulWidget {
  final MultiScanResult? initialMultiScan;

  const MultiScanScreen({
    super.key,
    this.initialMultiScan,
  });

  @override
  State<MultiScanScreen> createState() => _MultiScanScreenState();
}

class _MultiScanScreenState extends State<MultiScanScreen> {
  final TextEditingController _nameController = TextEditingController();
  final DocumentController _controller = Get.find<DocumentController>();

  @override
  void initState() {
    super.initState();
    
    debugPrint('MultiScanScreen - initState called');
    debugPrint('MultiScanScreen - initialMultiScan is null: ${widget.initialMultiScan == null}');
    
    // Initialize with provided multi-scan or start a new one
    if (widget.initialMultiScan != null) {
      _nameController.text = widget.initialMultiScan!.documentName;
      debugPrint('MultiScanScreen - Using provided initialMultiScan');
    } else {
      _nameController.text = 'Document ${DateTime.now().millisecondsSinceEpoch}';
      debugPrint('MultiScanScreen - Starting new multi-scan');
      debugPrint('MultiScanScreen - currentMultiScan before startMultiScan: ${_controller.currentMultiScan.value?.scanResults.length}');
      
      // Only start new multi-scan if one doesn't exist
      if (_controller.currentMultiScan.value == null) {
        _controller.startMultiScan();
      } else {
        debugPrint('MultiScanScreen - MultiScan already exists, not starting new one');
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DigiDocs'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Obx(() {
        final currentMultiScan = _controller.currentMultiScan.value;
        final isProcessing = _controller.isProcessing;
        
        debugPrint('MultiScanScreen - Obx rebuilding, currentMultiScan is null: ${currentMultiScan == null}');
        if (currentMultiScan != null) {
          debugPrint('MultiScanScreen - Current scan results count in UI: ${currentMultiScan.scanResults.length}');
        }
 
        if (currentMultiScan == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Header with document name and page count
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Document name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.description),
                    ),
                  ),
                    const SizedBox(height: 8),
                    Obx(() => Text(
                      '${_controller.multiScanResults.length} ${_controller.multiScanResults.length == 1 ? 'page' : 'pages'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    )),
                ],
              ),
            ),

            // Pages list
            Expanded(
              child: Obx(() => _controller.multiScanResults.isEmpty
                  ? _buildEmptyState()
                  : _buildPagesList(_controller.multiScanResults.toList())),
            ),

            // Bottom actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isProcessing ? null : _captureImage,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Add Page'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: isProcessing ? null : _importFromGallery,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Import'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Obx(() => FilledButton(
                      onPressed: _controller.multiScanResults.isEmpty || isProcessing
                          ? null
                          : () => _saveDocument(),
                      child: isProcessing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save PDF'),
                    )),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.collections_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No pages yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add pages by capturing with camera or importing from gallery',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagesList(List<ScanResult> scanResults) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      onReorder: (oldIndex, newIndex) {
        _controller.reorderMultiScanImages(oldIndex, newIndex);
      },
      itemCount: scanResults.length,
      itemBuilder: (context, index) {
        final scanResult = scanResults[index];
        return _buildPageCard(scanResult, index, key: ValueKey(index));
      },
    );
  }

  Widget _buildPageCard(ScanResult scanResult, int index, {required Key key}) {
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: FileImage(scanResult.imageFile),
              fit: BoxFit.cover,
            ),
          ),
        ),
        title: Text('Page ${index + 1}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter: ${scanResult.appliedFilter.name}'),
            if (scanResult.rotation != 0)
              Text('Rotation: ${scanResult.rotation}°'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editImage(scanResult, index),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _removeImage(index),
            ),
            const Icon(Icons.drag_handle),
          ],
        ),
      ),
    );
  }

  void _captureImage() {
    debugPrint('MultiScanScreen - _captureImage called');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CameraScreen(isMultiScan: true),
      ),
    ).then((result) {
      debugPrint('MultiScanScreen - Returned from camera with result: $result');
      debugPrint('MultiScanScreen - Result is ScanResult: ${result is ScanResult}');
      debugPrint('MultiScanScreen - Mounted: $mounted');
      if (result is ScanResult && mounted) {
        debugPrint('MultiScanScreen - Adding image to multi-scan');
        _controller.addImageToMultiScan(result);
      }
    });
  }

  void _importFromGallery() {
    _controller.importMultipleFromGallery();
  }

  void _editImage(ScanResult scanResult, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CropEnhanceScreen(
          scanResult: scanResult,
          isMultiScanEdit: true,
        ),
      ),
    ).then((result) {
      if (result is ScanResult && mounted) {
        _controller.updateImageInMultiScan(index, result);
      }
    });
  }

  void _removeImage(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Page'),
        content: Text('Are you sure you want to remove page ${index + 1}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _controller.removeImageFromMultiScan(index);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _saveDocument() {
    final documentName = _nameController.text.trim();
    final docId = _nameController.text.split(" ").last ?? "";
    if (documentName.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a document name',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    _controller.saveMultiScanDocument(documentName, docId).then((_) {
      Navigator.of(context).pop();
    });
  }
}