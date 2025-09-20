import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'file_service.dart';

class PdfService {
  static final PdfService _instance = PdfService._internal();
  factory PdfService() => _instance;
  PdfService._internal();

  final FileService _fileService = FileService();

  Future<String> createPdfFromImage(
    File imageFile,
    String documentId,
    String documentName,
  ) async {
    try {
      // Create a new PDF document
      final pdf = pw.Document();

      // Read and process the image
      final imageBytes = await imageFile.readAsBytes();
      final image = pw.MemoryImage(imageBytes);

      // Get image dimensions for proper scaling
      img.Image? decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        throw Exception('Failed to decode image for PDF creation');
      }

      final imageWidth = decodedImage.width.toDouble();
      final imageHeight = decodedImage.height.toDouble();

      // Calculate scaling to fit A4 page
      final double a4Width = PdfPageFormat.a4.width;
      final double a4Height = PdfPageFormat.a4.height;
      const double margin = 40.0;
      
      final availableWidth = a4Width - (2 * margin);
      final availableHeight = a4Height - (2 * margin);
      
      double scaleX = availableWidth / imageWidth;
      double scaleY = availableHeight / imageHeight;
      double scale = scaleX < scaleY ? scaleX : scaleY;
      
      final scaledWidth = imageWidth * scale;
      final scaledHeight = imageHeight * scale;

      // Add page with image
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(margin),
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Container(
                width: scaledWidth,
                height: scaledHeight,
                child: pw.Image(
                  image,
                  fit: pw.BoxFit.contain,
                ),
              ),
            );
          },
        ),
      );

      // Generate PDF bytes
      final pdfBytes = await pdf.save();

      // Save PDF file
      return await _fileService.savePdfFile(pdfBytes, documentId, documentName);
    } catch (e) {
      throw Exception('Failed to create PDF: $e');
    }
  }

  Future<File> createPdfFromImages(List<File> imageFiles) async {
    try {
      if (imageFiles.isEmpty) {
        throw Exception('No images provided for PDF creation');
      }

      // Create a new PDF document
      final pdf = pw.Document();

      for (final imageFile in imageFiles) {
        // Read and process each image
        final imageBytes = await imageFile.readAsBytes();
        final image = pw.MemoryImage(imageBytes);

        // Get image dimensions for proper scaling
        img.Image? decodedImage = img.decodeImage(imageBytes);
        if (decodedImage == null) {
          continue; // Skip invalid images
        }

        final imageWidth = decodedImage.width.toDouble();
        final imageHeight = decodedImage.height.toDouble();

        // Calculate scaling to fit A4 page
        final double a4Width = PdfPageFormat.a4.width;
        final double a4Height = PdfPageFormat.a4.height;
        const double margin = 40.0;
        
        final availableWidth = a4Width - (2 * margin);
        final availableHeight = a4Height - (2 * margin);
        
        double scaleX = availableWidth / imageWidth;
        double scaleY = availableHeight / imageHeight;
        double scale = scaleX < scaleY ? scaleX : scaleY;
        
        final scaledWidth = imageWidth * scale;
        final scaledHeight = imageHeight * scale;

        // Add page with image
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(margin),
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Container(
                  width: scaledWidth,
                  height: scaledHeight,
                  child: pw.Image(
                    image,
                    fit: pw.BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        );
      }

      // Generate PDF bytes
      final pdfBytes = await pdf.save();

      // Save PDF file to temporary location
      return await _fileService.saveTempPdfFile(pdfBytes);
    } catch (e) {
      throw Exception('Failed to create PDF from images: $e');
    }
  }

  Future<String> createPdfFromMultipleImages(
    List<File> imageFiles,
    String documentId,
    String documentName,
  ) async {
    try {
      if (imageFiles.isEmpty) {
        throw Exception('No images provided for PDF creation');
      }

      // Create a new PDF document
      final pdf = pw.Document();

      for (final imageFile in imageFiles) {
        // Read and process each image
        final imageBytes = await imageFile.readAsBytes();
        final image = pw.MemoryImage(imageBytes);

        // Get image dimensions for proper scaling
        img.Image? decodedImage = img.decodeImage(imageBytes);
        if (decodedImage == null) {
          continue; // Skip invalid images
        }

        final imageWidth = decodedImage.width.toDouble();
        final imageHeight = decodedImage.height.toDouble();

        // Calculate scaling to fit A4 page
        final double a4Width = PdfPageFormat.a4.width;
        final double a4Height = PdfPageFormat.a4.height;
        const double margin = 40.0;
        
        final availableWidth = a4Width - (2 * margin);
        final availableHeight = a4Height - (2 * margin);
        
        double scaleX = availableWidth / imageWidth;
        double scaleY = availableHeight / imageHeight;
        double scale = scaleX < scaleY ? scaleX : scaleY;
        
        final scaledWidth = imageWidth * scale;
        final scaledHeight = imageHeight * scale;

        // Add page with image
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(margin),
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Container(
                  width: scaledWidth,
                  height: scaledHeight,
                  child: pw.Image(
                    image,
                    fit: pw.BoxFit.contain,
                  ),
                ),
              );
            },
          ),
        );
      }

      // Generate PDF bytes
      final pdfBytes = await pdf.save();

      // Save PDF file
      return await _fileService.savePdfFile(pdfBytes, documentId, documentName);
    } catch (e) {
      throw Exception('Failed to create PDF from multiple images: $e');
    }
  }

  Future<List<int>> getPdfBytes(String pdfFilePath) async {
    try {
      final file = File(pdfFilePath);
      if (!await file.exists()) {
        throw Exception('PDF file not found: $pdfFilePath');
      }
      return await file.readAsBytes();
    } catch (e) {
      throw Exception('Failed to read PDF bytes: $e');
    }
  }

  Future<int> getPdfPageCount(String pdfFilePath) async {
    try {
      // This is a simplified implementation
      // In a real app, you might want to use a PDF parsing library
      final file = File(pdfFilePath);
      if (!await file.exists()) {
        throw Exception('PDF file not found: $pdfFilePath');
      }
      
      // For now, assume single page PDFs created by this service
      return 1;
    } catch (e) {
      throw Exception('Failed to get PDF page count: $e');
    }
  }

  Future<bool> isValidPdf(String pdfFilePath) async {
    try {
      final file = File(pdfFilePath);
      if (!await file.exists()) {
        return false;
      }

      final bytes = await file.readAsBytes();
      // Check PDF header
      if (bytes.length < 4) return false;
      
      final header = String.fromCharCodes(bytes.take(4));
      return header == '%PDF';
    } catch (e) {
      return false;
    }
  }
}
