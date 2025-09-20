import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import '../models/document.dart';
import '../models/scan_result.dart';
import '../services/image_service.dart';
import 'crop_enhance_screen.dart';

class CameraScreen extends StatefulWidget {
  final bool isMultiScan;

  const CameraScreen({
    super.key,
    this.isMultiScan = false,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isCapturing = false;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _setupCamera(_selectedCameraIndex);
      }
    } catch (e) {
      _showError('Failed to initialize camera: $e');
    }
  }

  Future<void> _setupCamera(int cameraIndex) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    _controller = CameraController(
      _cameras[cameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      _showError('Failed to setup camera: $e');
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile image = await _controller!.takePicture();
      final File imageFile = File(image.path);
      
      // Auto-crop the image to the document frame
      final croppedImage = await _cropToDocumentFrame(imageFile);

      final scanResult = ScanResult(
        imageFile: croppedImage,
        appliedFilter: FilterType.original,
        rotation: 0.0,
        isCropped: true,
      );

      if (mounted) {
        if (widget.isMultiScan) {
          // For multi-scan, return the scan result
          debugPrint('CameraScreen - Returning scan result for multi-scan');
          Navigator.of(context).pop(scanResult);
        } else {
          // For single scan, navigate to crop/enhance screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => CropEnhanceScreen(scanResult: scanResult),
            ),
          );
        }
      }
    } catch (e) {
      _showError('Failed to capture image: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<File> _cropToDocumentFrame(File originalImage) async {
    try {
      // Get image dimensions
      final imageService = ImageService();
      final imageSize = await imageService.getImageDimensions(originalImage);
      
      // Calculate the crop area based on the overlay frame
      // The frame is 80% width and 60% height of the screen, centered
      
      // Calculate the actual image dimensions and crop area
      final imageWidth = imageSize.width;
      final imageHeight = imageSize.height;
      
      // Calculate crop rectangle (center the crop area)
      final cropX = (imageWidth - (imageWidth * 0.8)) / 2;
      final cropY = (imageHeight - (imageHeight * 0.6)) / 2;
      final cropWidth = imageWidth * 0.8;
      final cropHeight = imageHeight * 0.6;
      
      // Use the ImageService to crop the image
      final croppedImage = await imageService.cropImage(
        originalImage,
        Rect.fromLTWH(cropX, cropY, cropWidth, cropHeight),
      );
      
      return croppedImage;
    } catch (e) {
      // If cropping fails, return the original image
      return originalImage;
    }
  }

  void _switchCamera() async {
    if (_cameras.length <= 1) return;

    setState(() {
      _isInitialized = false;
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    });

    await _setupCamera(_selectedCameraIndex);
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_cameras.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
              onPressed: _switchCamera,
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Camera preview
          if (_isInitialized && _controller != null)
            Positioned.fill(
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Camera overlay with guidelines
          if (_isInitialized)
            Positioned.fill(
              child: CustomPaint(
                painter: CameraOverlayPainter(),
              ),
            ),

          // Capture button and controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Flash toggle (if available)
                  IconButton(
                    icon: const Icon(Icons.flash_auto, color: Colors.white, size: 32),
                    onPressed: () {
                      // Flash toggle functionality can be added here
                    },
                  ),
                  
                  // Capture button
                  GestureDetector(
                    onTap: _captureImage,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                      ),
                      child: _isCapturing
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              color: Colors.black,
                              size: 32,
                            ),
                    ),
                  ),
                  
                  // Gallery button
                  IconButton(
                    icon: const Icon(Icons.photo_library, color: Colors.white, size: 32),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Instructions
          Positioned(
            top: MediaQuery.of(context).padding.top + 80,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Position the document within the frame and tap to capture',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CameraOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw document frame guidelines
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.8,
      height: size.height * 0.6,
    );

    // Draw corner brackets
    const cornerLength = 20.0;
    
    // Top-left corner
    canvas.drawLine(
      Offset(rect.left, rect.top + cornerLength),
      Offset(rect.left, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerLength, rect.top),
      paint,
    );
    
    // Top-right corner
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.top),
      Offset(rect.right, rect.top),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerLength),
      paint,
    );
    
    // Bottom-left corner
    canvas.drawLine(
      Offset(rect.left, rect.bottom - cornerLength),
      Offset(rect.left, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerLength, rect.bottom),
      paint,
    );
    
    // Bottom-right corner
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.bottom),
      Offset(rect.right, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right, rect.bottom - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
