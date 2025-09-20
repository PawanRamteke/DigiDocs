import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../models/document.dart';
import 'file_service.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final FileService _fileService = FileService();

  Future<File> processImage(
    File imageFile,
    {FilterType filter = FilterType.original, double rotation = 0.0}
  ) async {
    try {
      // Read the image
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Apply rotation if needed
      if (rotation != 0.0) {
        final rotationRadians = rotation * (3.14159 / 180);
        image = img.copyRotate(image, angle: rotationRadians);
      }

      // Apply filters
      switch (filter) {
        case FilterType.grayscale:
          image = img.grayscale(image);
          break;
        case FilterType.highContrast:
          image = img.contrast(image, contrast: 150);
          image = img.adjustColor(image, brightness: 1.1);
          break;
        case FilterType.original:
          // No filter applied
          break;
      }

      // Encode the processed image
      final processedBytes = img.encodeJpg(image, quality: 90);
      
      // Save to temporary file
      final tempPath = await _fileService.createTempFile('.jpg');
      final processedFile = File(tempPath);
      await processedFile.writeAsBytes(processedBytes);
      
      return processedFile;
    } catch (e) {
      throw Exception('Failed to process image: $e');
    }
  }

  Future<String> createThumbnail(File imageFile, String documentId) async {
    try {
      // Read the image
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Failed to decode image for thumbnail');
      }

      // Create thumbnail (200x200 max, maintaining aspect ratio)
      img.Image thumbnail = img.copyResize(
        image,
        width: 200,
        height: 200,
        maintainAspect: true,
      );

      // Encode as JPEG with lower quality for smaller file size
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: 70);
      
      // Save thumbnail
      return await _fileService.saveThumbnail(thumbnailBytes, documentId);
    } catch (e) {
      throw Exception('Failed to create thumbnail: $e');
    }
  }

  Future<File> cropImage(File imageFile, Rect cropRect) async {
    try {
      // Read the image
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Failed to decode image for cropping');
      }

      // Apply crop
      img.Image croppedImage = img.copyCrop(
        image,
        x: cropRect.left.round(),
        y: cropRect.top.round(),
        width: cropRect.width.round(),
        height: cropRect.height.round(),
      );

      // Encode the cropped image
      final croppedBytes = img.encodeJpg(croppedImage, quality: 90);
      
      // Save to temporary file
      final tempPath = await _fileService.createTempFile('.jpg');
      final croppedFile = File(tempPath);
      await croppedFile.writeAsBytes(croppedBytes);
      
      return croppedFile;
    } catch (e) {
      throw Exception('Failed to crop image: $e');
    }
  }

  Future<File> rotateImage(File imageFile, double degrees) async {
    try {
      // Read the image
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Failed to decode image for rotation');
      }

      // Apply rotation
      final rotationRadians = degrees * (3.14159 / 180);
      img.Image rotatedImage = img.copyRotate(image, angle: rotationRadians);

      // Encode the rotated image
      final rotatedBytes = img.encodeJpg(rotatedImage, quality: 90);
      
      // Save to temporary file
      final tempPath = await _fileService.createTempFile('.jpg');
      final rotatedFile = File(tempPath);
      await rotatedFile.writeAsBytes(rotatedBytes);
      
      return rotatedFile;
    } catch (e) {
      throw Exception('Failed to rotate image: $e');
    }
  }

  Future<Size> getImageDimensions(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Failed to decode image for dimensions');
      }

      return Size(image.width.toDouble(), image.height.toDouble());
    } catch (e) {
      throw Exception('Failed to get image dimensions: $e');
    }
  }

  Future<bool> isValidImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      return image != null;
    } catch (e) {
      return false;
    }
  }

  Future<File> enhanceDocumentImage(File imageFile) async {
    try {
      // Read the image
      final imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Failed to decode image for enhancement');
      }

      // Apply document-specific enhancements
      // 1. Increase contrast
      image = img.contrast(image, contrast: 120);
      
      // 2. Adjust brightness slightly
      image = img.adjustColor(image, brightness: 1.05);
      
      // 3. Sharpen the image
      image = img.convolution(image, filter: [
        0, -1, 0,
        -1, 5, -1,
        0, -1, 0
      ]);

      // Encode the enhanced image
      final enhancedBytes = img.encodeJpg(image, quality: 95);
      
      // Save to temporary file
      final tempPath = await _fileService.createTempFile('.jpg');
      final enhancedFile = File(tempPath);
      await enhancedFile.writeAsBytes(enhancedBytes);
      
      return enhancedFile;
    } catch (e) {
      throw Exception('Failed to enhance image: $e');
    }
  }
}
