import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

class FileService {
  static final FileService _instance = FileService._internal();
  factory FileService() => _instance;
  FileService._internal();

  Future<String> get _documentsPath async {
    final directory = await getApplicationDocumentsDirectory();
    final documentsDir = Directory(path.join(directory.path, 'documents'));
    if (!await documentsDir.exists()) {
      await documentsDir.create(recursive: true);
    }
    return documentsDir.path;
  }

  Future<String> get _thumbnailsPath async {
    final directory = await getApplicationDocumentsDirectory();
    final thumbnailsDir = Directory(path.join(directory.path, 'thumbnails'));
    if (!await thumbnailsDir.exists()) {
      await thumbnailsDir.create(recursive: true);
    }
    return thumbnailsDir.path;
  }

  Future<String> saveImageFile(
    File sourceFile,
    String documentId,
    String documentName,
  ) async {
    final documentsPath = await _documentsPath;
    final extension = path.extension(sourceFile.path).toLowerCase();
    final sanitizedName = _sanitizeFileName(documentName);
    final fileName = '${documentId}_$sanitizedName$extension';
    final filePath = path.join(documentsPath, fileName);
    
    await sourceFile.copy(filePath);
    return filePath;
  }

  Future<String> savePdfFile(
    List<int> pdfBytes,
    String documentId,
    String documentName,
  ) async {
    final documentsPath = await _documentsPath;
    final sanitizedName = _sanitizeFileName(documentName);
    final fileName = '${documentId}_$sanitizedName.pdf';
    final filePath = path.join(documentsPath, fileName);
    
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);
    return filePath;
  }

  Future<String> saveThumbnail(
    List<int> thumbnailBytes,
    String documentId,
  ) async {
    final thumbnailsPath = await _thumbnailsPath;
    final fileName = '${documentId}_thumb.jpg';
    final filePath = path.join(thumbnailsPath, fileName);
    
    final file = File(filePath);
    await file.writeAsBytes(thumbnailBytes);
    return filePath;
  }

  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Log error but don't throw - file might already be deleted
      debugPrint('Error deleting file $filePath: $e');
    }
  }

  Future<void> shareFile(String filePath, String fileName) async {
    final file = File(filePath);
    if (await file.exists()) {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Sharing document: $fileName',
      );
    } else {
      throw Exception('File not found: $filePath');
    }
  }

  Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }

  Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  Future<void> cleanupOrphanedFiles() async {
    // This method can be called periodically to clean up files
    // that are no longer referenced in the database
    try {
      // Clean up old temporary files if any
      final tempDir = await getTemporaryDirectory();
      final tempFiles = await tempDir.list().toList();
      for (final entity in tempFiles) {
        if (entity is File) {
          final stat = await entity.stat();
          final age = DateTime.now().difference(stat.modified);
          if (age.inDays > 1) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error during cleanup: $e');
    }
  }

  String _sanitizeFileName(String fileName) {
    // Remove or replace invalid characters for file names
    return fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .toLowerCase();
  }

  Future<String> createTempFile(String extension) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'temp_$timestamp$extension';
    return path.join(tempDir.path, fileName);
  }

  Future<File> saveFile(File sourceFile, String documentName) async {
    final documentsPath = await _documentsPath;
    final extension = path.extension(sourceFile.path).toLowerCase();
    final sanitizedName = _sanitizeFileName(documentName);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$sanitizedName$extension';
    final filePath = path.join(documentsPath, fileName);
    
    return await sourceFile.copy(filePath);
  }

  Future<File> saveTempPdfFile(List<int> pdfBytes) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'temp_$timestamp.pdf';
    final filePath = path.join(tempDir.path, fileName);
    
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);
    return file;
  }
}
