import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import 'controllers/document_controller.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'services/file_service.dart';
import 'services/image_service.dart';
import 'services/pdf_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Request necessary permissions
  await _requestPermissions();
  
  // Initialize GetX controller with dependencies
  Get.put(DocumentController(
    databaseService: DatabaseService(),
    fileService: FileService(),
    imageService: ImageService(),
    pdfService: PdfService(),
  ));
  
  runApp(const DocumentScannerApp());
}

Future<void> _requestPermissions() async {
  await [
    Permission.camera,
    Permission.storage,
    Permission.manageExternalStorage,
  ].request();
}

class DocumentScannerApp extends StatelessWidget {
  const DocumentScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
        title: 'DigiDocs',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            shape: CircleBorder(),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            shape: CircleBorder(),
          ),
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      );
  }
}
