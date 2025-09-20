import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import '../controllers/document_controller.dart';
import '../models/document.dart';
import '../models/scan_result.dart';
import '../services/image_service.dart';
import '../widgets/filter_preview.dart';

class CropEnhanceScreen extends StatefulWidget {
  final ScanResult scanResult;
  final bool isMultiScanEdit;

  const CropEnhanceScreen({
    super.key,
    required this.scanResult,
    this.isMultiScanEdit = false,
  });

  @override
  State<CropEnhanceScreen> createState() => _CropEnhanceScreenState();
}

class _CropEnhanceScreenState extends State<CropEnhanceScreen> {
  late ScanResult _currentScanResult;
  late File _originalImageFile; // Keep track of original image
  final TextEditingController _nameController = TextEditingController();
  final DocumentController _controller = Get.find<DocumentController>();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _currentScanResult = widget.scanResult;
    _originalImageFile = widget.scanResult.imageFile; // Store original
    _nameController.text = 'Document ${DateTime.now().millisecondsSinceEpoch}';
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
        title: const Text('Crop & Enhance'),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : (widget.isMultiScanEdit ? _returnEditedImage : _saveDocument),
            child: _isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.isMultiScanEdit ? 'Done' : 'Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Image preview
              Container(
                height: MediaQuery.of(context).size.height * 0.45,
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _currentScanResult.imageFile,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Controls
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Document name input (only show for non-multi-scan edit)
                    if (!widget.isMultiScanEdit) ...[
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
                      const SizedBox(height: 16),
                    ],

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.crop,
                            label: 'Crop',
                            onPressed: _cropImage,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.rotate_right,
                            label: 'Rotate',
                            onPressed: _rotateImage,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Filter options
                    Text(
                      'Filters',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFilterOption(FilterType.original, 'Original'),
                          const SizedBox(width: 8),
                          _buildFilterOption(FilterType.grayscale, 'Grayscale'),
                          const SizedBox(width: 8),
                          _buildFilterOption(FilterType.highContrast, 'High Contrast'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Save options (only show for non-multi-scan edit)
                    if (!widget.isMultiScanEdit) ...[
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _isProcessing ? null : () => _saveAs(DocumentType.image),
                              icon: const Icon(Icons.image),
                              label: const Text('Save as Image'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _isProcessing ? null : () => _saveAs(DocumentType.pdf),
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('Save as PDF'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // For multi-scan edit, show a single done button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _isProcessing ? null : _returnEditedImage,
                          icon: const Icon(Icons.check),
                          label: const Text('Apply Changes'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: _isProcessing ? null : onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildFilterOption(FilterType filterType, String label) {
    final isSelected = _currentScanResult.appliedFilter == filterType;
    
    return GestureDetector(
      onTap: () => _applyFilter(filterType),
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilterPreview(
              imageFile: _originalImageFile,
              filterType: filterType,
              size: 40,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cropImage() async {
    if (_isProcessing) return;
    
    try {
      setState(() => _isProcessing = true);

      // Check if file exists before cropping
      if (!await _currentScanResult.imageFile.exists()) {
        _showError('Image file not found');
        return;
      }

      debugPrint('Starting crop with file: ${_currentScanResult.imageFile.path}');
      
      // Try ImageCropper first
      try {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: _currentScanResult.imageFile.path,
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 90,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Crop Document',
              toolbarColor: Colors.blue,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false,
              hideBottomControls: false,
              showCropGrid: true,
            ),
            IOSUiSettings(
              title: 'Crop Document',
              doneButtonTitle: 'Done',
              cancelButtonTitle: 'Cancel',
              minimumAspectRatio: 0.1,
            ),
          ],
        );

        debugPrint('Crop result: ${croppedFile?.path}');

        if (croppedFile != null && mounted) {
          final croppedImageFile = File(croppedFile.path);
          
          // Verify the cropped file exists
          if (await croppedImageFile.exists()) {
            setState(() {
              _originalImageFile = croppedImageFile; // Update original with cropped version
              _currentScanResult = _currentScanResult.copyWith(
                imageFile: croppedImageFile,
                isCropped: true,
              );
            });
          } else {
            _showError('Cropped image file was not created properly');
          }
        }
      } catch (cropError) {
        debugPrint('ImageCropper failed: $cropError');
        // Show a message that manual cropping is not available
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Crop feature is not available on this device. You can still apply filters and rotate the image.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Crop error: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        _showError('Failed to crop image: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _rotateImage() async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final imageService = ImageService();
      // Rotate the original image to maintain quality
      final rotatedOriginal = await imageService.rotateImage(_originalImageFile, 90);
      final newRotation = (_currentScanResult.rotation + 90) % 360;
      
      // Apply current filter to the rotated image
      final processedImage = await imageService.processImage(
        rotatedOriginal,
        filter: _currentScanResult.appliedFilter,
        rotation: 0, // Reset rotation since we physically rotated the image
      );
      
      setState(() {
        _originalImageFile = rotatedOriginal; // Update original
        _currentScanResult = _currentScanResult.copyWith(
          imageFile: processedImage,
          rotation: newRotation,
        );
      });
    } catch (e) {
      _showError('Failed to rotate image: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _applyFilter(FilterType filterType) async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      // Always start from the original image to avoid cumulative effects
      final imageService = ImageService();
      final processedImage = await imageService.processImage(
        _originalImageFile,
        filter: filterType,
        rotation: _currentScanResult.rotation,
      );
      
      setState(() {
        _currentScanResult = _currentScanResult.copyWith(
          imageFile: processedImage,
          appliedFilter: filterType,
        );
      });
    } catch (e) {
      _showError('Failed to apply filter: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _saveDocument() {
    _saveAs(DocumentType.image);
  }

  void _returnEditedImage() {
    // Return the edited scan result to the calling screen
    Navigator.of(context).pop(_currentScanResult);
  }

  Future<void> _saveAs(DocumentType documentType) async {
    final documentName = _nameController.text.trim();
    if (documentName.isEmpty) {
      _showError('Please enter a document name');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await     _controller.saveDocument(
      scanResult: _currentScanResult,
      name: documentName,
      type: documentType,
    );

      // Navigate back to home screen
      Navigator.of(context).popUntil((route) => route.isFirst);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
