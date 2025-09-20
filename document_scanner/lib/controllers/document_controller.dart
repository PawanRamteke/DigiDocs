import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../models/document.dart';
import '../models/scan_result.dart';
import '../models/multi_scan_result.dart';
import '../services/database_service.dart';
import '../services/file_service.dart';
import '../services/image_service.dart';
import '../services/pdf_service.dart';

class DocumentController extends GetxController {
  final DatabaseService _databaseService;
  final FileService _fileService;
  final ImageService _imageService;
  final PdfService _pdfService;

  DocumentController({
    required DatabaseService databaseService,
    required FileService fileService,
    required ImageService imageService,
    required PdfService pdfService,
  })  : _databaseService = databaseService,
        _fileService = fileService,
        _imageService = imageService,
        _pdfService = pdfService;

  // Observable states
  final RxList<Document> _documents = <Document>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxString _searchQuery = ''.obs;
  final Rx<ScanResult?> _importedScanResult = Rx<ScanResult?>(null);
  final Rx<MultiScanResult?> currentMultiScan = Rx<MultiScanResult?>(null);
  final RxList<ScanResult> _multiScanResults = <ScanResult>[].obs;
  final RxBool _isProcessing = false.obs;

  // Getters
  List<Document> get documents => _documents.toList();
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  String get searchQuery => _searchQuery.value;
  ScanResult? get importedScanResult => _importedScanResult.value;
  MultiScanResult? get currentMultiScanValue => currentMultiScan.value;
  RxList<ScanResult> get multiScanResults => _multiScanResults;
  bool get isProcessing => _isProcessing.value;

  @override
  void onInit() {
    super.onInit();
    loadDocuments();
  }

  // Load documents
  Future<void> loadDocuments() async {
    try {
      _isLoading.value = true;
      _error.value = '';
      
      final documents = await _databaseService.getAllDocuments();
      _documents.assignAll(documents);
      _searchQuery.value = '';
    } catch (e) {
      _error.value = 'Failed to load documents: $e';
      debugPrint('Error loading documents: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // Search documents
  Future<void> searchDocuments(String query) async {
    try {
      _isLoading.value = true;
      _error.value = '';
      
      final documents = await _databaseService.searchDocuments(query);
      _documents.assignAll(documents);
      _searchQuery.value = query;
    } catch (e) {
      _error.value = 'Search failed: $e';
      debugPrint('Error searching documents: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // Save document
  Future<void> saveDocument({
    required ScanResult scanResult,
    required String name,
    required DocumentType type,
  }) async {
    try {
      _isProcessing.value = true;
      _error.value = '';

      late final String filePath;
      late final String thumbnailPath;

      // Generate unique document ID
      final documentId = DateTime.now().millisecondsSinceEpoch.toString();
      
      if (type == DocumentType.pdf) {
        // Generate PDF
        filePath = await _pdfService.createPdfFromImage(
          scanResult.imageFile,
          documentId,
          name,
        );
        
        // Create thumbnail from the image
        thumbnailPath = await _imageService.createThumbnail(
          scanResult.imageFile,
          documentId,
        );
      } else {
        // Save as image
        filePath = await _fileService.saveImageFile(
          scanResult.imageFile,
          documentId,
          name,
        );
        
        // Create thumbnail
        thumbnailPath = await _imageService.createThumbnail(
          scanResult.imageFile,
          documentId,
        );
      }

      // Get file size
      final fileSize = await _fileService.getFileSize(filePath);

      // Create document record
      final document = Document(
        id: '',
        name: name,
        filePath: filePath,
        thumbnailPath: thumbnailPath,
        type: type,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        fileSize: fileSize,
        appliedFilter: scanResult.appliedFilter,
        rotation: scanResult.rotation,
      );

      // Save to database
      await _databaseService.insertDocument(document);
      
      // Reload documents
      await loadDocuments();
      
      Get.snackbar(
        'Success',
        'Document saved successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _error.value = 'Failed to save document: $e';
      debugPrint('Error saving document: $e');
      Get.snackbar(
        'Error',
        'Failed to save document: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isProcessing.value = false;
    }
  }

  // Delete document
  Future<void> deleteDocument(String documentId) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      await _databaseService.deleteDocument(documentId);
      await loadDocuments();
      
      Get.snackbar(
        'Success',
        'Document deleted',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _error.value = 'Failed to delete document: $e';
      debugPrint('Error deleting document: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  // Rename document
  Future<void> renameDocument(String documentId, String newName) async {
    try {
      _isProcessing.value = true;
      _error.value = '';

      await _databaseService.updateDocumentFields(documentId, {'name': newName});
      await loadDocuments();
      
      Get.snackbar(
        'Success',
        'Document renamed successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _error.value = 'Failed to rename document: $e';
      debugPrint('Error renaming document: $e');
    } finally {
      _isProcessing.value = false;
    }
  }

  // Share document
  Future<void> shareDocument(String documentId) async {
    try {
      _isProcessing.value = true;
      _error.value = '';

      // Get document and share its file
      final documents = await _databaseService.getAllDocuments();
      final document = documents.firstWhereOrNull((doc) => doc.id == documentId);
      if (document == null) {
        throw Exception('Document not found');
      }
      await _shareFile(document.filePath);
    } catch (e) {
      _error.value = 'Failed to share document: $e';
      debugPrint('Error sharing document: $e');
    } finally {
      _isProcessing.value = false;
    }
  }

  // Import from gallery
  Future<void> importFromGallery() async {
    try {
      _isProcessing.value = true;
      _error.value = '';

      final imageFile = await _pickImageFromGallery();
      if (imageFile != null) {
        _importedScanResult.value = ScanResult(
          imageFile: imageFile,
          appliedFilter: FilterType.original,
          rotation: 0,
          isCropped: false,
        );
      }
    } catch (e) {
      _error.value = 'Failed to import image: $e';
      debugPrint('Error importing from gallery: $e');
    } finally {
      _isProcessing.value = false;
    }
  }

  // Multi-scan methods
  void startMultiScan() {
    debugPrint('DocumentController - startMultiScan called');
    debugPrint('DocumentController - Stack trace: ${StackTrace.current}');
    
    // Clear the reactive list
    _multiScanResults.clear();
    
    currentMultiScan.value = MultiScanResult(
      scanResults: <ScanResult>[],
      documentName: 'Document',
    );
    debugPrint('DocumentController - MultiScan started with empty list');
  }

  void addImageToMultiScan(ScanResult scanResult) {
    debugPrint('DocumentController - addImageToMultiScan called');
    debugPrint('DocumentController - ScanResult imageFile path: ${scanResult.imageFile.path}');
    
    // Add to the reactive list
    _multiScanResults.add(scanResult);
    debugPrint('DocumentController - Added to reactive list, count: ${_multiScanResults.length}');
    
    // Update the MultiScanResult object
    if (currentMultiScan.value != null) {
      currentMultiScan.value = MultiScanResult(
        scanResults: _multiScanResults.toList(),
        documentName: currentMultiScan.value!.documentName,
        globalFilter: currentMultiScan.value!.globalFilter,
      );
      debugPrint('DocumentController - Updated MultiScanResult, count: ${currentMultiScan.value!.scanResults.length}');
    } else {
      debugPrint('DocumentController - currentMultiScan is null, cannot update');
    }
  }

  void removeImageFromMultiScan(int index) {
    if (index >= 0 && index < _multiScanResults.length) {
      _multiScanResults.removeAt(index);
      // Update MultiScanResult object
      if (currentMultiScan.value != null) {
        currentMultiScan.value = MultiScanResult(
          scanResults: _multiScanResults.toList(),
          documentName: currentMultiScan.value!.documentName,
          globalFilter: currentMultiScan.value!.globalFilter,
        );
      }
    }
  }

  void updateImageInMultiScan(int index, ScanResult updatedScanResult) {
    if (index >= 0 && index < _multiScanResults.length) {
      _multiScanResults[index] = updatedScanResult;
      // Update MultiScanResult object
      if (currentMultiScan.value != null) {
        currentMultiScan.value = MultiScanResult(
          scanResults: _multiScanResults.toList(),
          documentName: currentMultiScan.value!.documentName,
          globalFilter: currentMultiScan.value!.globalFilter,
        );
      }
    }
  }

  void reorderMultiScanImages(int oldIndex, int newIndex) {
    if (oldIndex >= 0 && oldIndex < _multiScanResults.length && 
        newIndex >= 0 && newIndex < _multiScanResults.length) {
      final item = _multiScanResults.removeAt(oldIndex);
      _multiScanResults.insert(newIndex, item);
      // Update MultiScanResult object
      if (currentMultiScan.value != null) {
        currentMultiScan.value = MultiScanResult(
          scanResults: _multiScanResults.toList(),
          documentName: currentMultiScan.value!.documentName,
          globalFilter: currentMultiScan.value!.globalFilter,
        );
      }
    }
  }

  Future<void> saveMultiScanDocument(String documentName, String id) async {
    if (_multiScanResults.isEmpty) {
      _error.value = 'No images to save';
      return;
    }

    try {
      _isProcessing.value = true;
      _error.value = '';

      debugPrint('DocumentController - saveMultiScanDocument: ${_multiScanResults.length} images to save');

      // Generate unique document ID
      final documentId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create multi-page PDF
      final filePath = await _pdfService.createPdfFromMultipleImages(
        _multiScanResults.map((sr) => sr.imageFile).toList(),
        documentId,
        documentName,
      );

      // Create thumbnail from first image
      final thumbnailPath = await _imageService.createThumbnail(
        _multiScanResults.first.imageFile,
        documentId,
      );

      // Get file size
      final fileSize = await _fileService.getFileSize(filePath);

      // Create document record
      final document = Document(
        id: id,
        name: documentName,
        filePath: filePath,
        thumbnailPath: thumbnailPath,
        type: DocumentType.pdf,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        fileSize: fileSize,
        appliedFilter: FilterType.original,
        rotation: 0,
      );

      // Save to database
      await _databaseService.insertDocument(document);

      // Clear multi-scan state
      clearCurrentMultiScan();

      // Reload documents
      await loadDocuments();

      Get.snackbar(
        'Success',
        'Document saved successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      _error.value = 'Failed to save document: $e';
      debugPrint('Error saving document: $e');
      Get.snackbar(
        'Error',
        'Failed to save document: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isProcessing.value = false;
    }
  }

  Future<void> importMultipleFromGallery() async {
    try {
      _isProcessing.value = true;
      _error.value = '';

      final imageFiles = await _pickMultipleImagesFromGallery();
      if (imageFiles.isNotEmpty) {
        debugPrint('DocumentController - importMultipleFromGallery: ${imageFiles.length} images selected');
        
        // Add all images to reactive list
        for (final file in imageFiles) {
          final scanResult = ScanResult(
            imageFile: file,
            appliedFilter: FilterType.original,
            rotation: 0,
            isCropped: false,
          );
          _multiScanResults.add(scanResult);
        }
        
        debugPrint('DocumentController - Added ${_multiScanResults.length} images to reactive list');
        
        // Update MultiScanResult object
        currentMultiScan.value = MultiScanResult(
          scanResults: _multiScanResults.toList(),
          documentName: 'Imported Document',
        );
        
        debugPrint('DocumentController - Updated MultiScanResult with ${currentMultiScan.value!.scanResults.length} images');
      }
    } catch (e) {
      _error.value = 'Failed to import images: $e';
      debugPrint('Error importing multiple images: $e');
    } finally {
      _isProcessing.value = false;
    }
  }

  // Clear states
  void clearImportedScanResult() {
    _importedScanResult.value = null;
  }

  void clearCurrentMultiScan() {
    _multiScanResults.clear();
    currentMultiScan.value = null;
  }

  void clearError() {
    _error.value = '';
  }

  // Helper methods for image picking and sharing
  Future<File?> _pickImageFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return null;
    }
  }

  Future<List<File>> _pickMultipleImagesFromGallery() async {
    try {
      final picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      
      return images.map((xfile) => File(xfile.path)).toList();
    } catch (e) {
      debugPrint('Error picking multiple images from gallery: $e');
      Get.snackbar(
        'Error',
        'Failed to pick images: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return [];
    }
  }

  Future<void> _shareFile(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)]);
    } catch (e) {
      debugPrint('Error sharing file: $e');
      Get.snackbar(
        'Error',
        'Failed to share file: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
