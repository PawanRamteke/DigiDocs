# DigiDocs App

A comprehensive Flutter application for scanning, enhancing, and managing documents using the device camera or gallery imports.

## Features

### Core Functionality
- **Document Scanning**: Use device camera to capture documents with visual guidelines
- **Gallery Import**: Import existing images from device gallery
- **Image Enhancement**: Apply filters (Original, Grayscale, High Contrast)
- **Crop & Rotate**: Crop documents to desired boundaries and rotate as needed
- **Multiple Export Formats**: Save as high-quality images (JPEG/PNG) or PDF documents

### Document Management
- **Local Storage**: Secure local storage with SQLite database
- **Search Functionality**: Search documents by name
- **Document Preview**: View documents with zoom capability
- **Metadata Display**: File size, creation date, applied filters, and rotation info
- **Document Actions**: Rename, delete, and share documents
- **Thumbnail Generation**: Automatic thumbnail creation for quick browsing

### User Interface
- **Material 3 Design**: Modern, clean UI following latest Material Design guidelines
- **Dark/Light Theme**: Automatic theme switching based on system preferences
- **Responsive Layout**: Optimized for different screen sizes
- **Grid View**: Documents displayed in an attractive grid layout
- **Search Interface**: Integrated search with real-time filtering

## Architecture

### State Management
- **BLoC Pattern**: Clean separation of business logic and UI using flutter_bloc
- **Event-Driven**: Reactive state management with proper event handling
- **Equatable**: Immutable state objects for better performance

### Project Structure
```
lib/
├── bloc/              # BLoC state management
│   ├── document_bloc.dart
│   ├── document_event.dart
│   └── document_state.dart
├── models/            # Data models
│   ├── document.dart
│   └── scan_result.dart
├── screens/           # UI screens
│   ├── home_screen.dart
│   ├── camera_screen.dart
│   ├── crop_enhance_screen.dart
│   └── document_detail_screen.dart
├── services/          # Business logic services
│   ├── database_service.dart
│   ├── file_service.dart
│   ├── image_service.dart
│   └── pdf_service.dart
├── widgets/           # Reusable UI components
│   ├── document_card.dart
│   ├── empty_state.dart
│   ├── filter_preview.dart
│   └── search_bar_widget.dart
└── main.dart         # App entry point
```

### Services Layer
- **DatabaseService**: SQLite database operations for document metadata
- **FileService**: File system operations and cleanup
- **ImageService**: Image processing, filtering, and enhancement
- **PdfService**: PDF generation from images

## Dependencies

### Core Dependencies
- `flutter_bloc` - State management
- `equatable` - Value equality
- `camera` - Camera functionality
- `image_picker` - Gallery imports
- `image_cropper` - Image cropping
- `image` - Image processing
- `pdf` - PDF generation
- `sqflite` - Local database
- `path_provider` - File system paths
- `permission_handler` - Runtime permissions
- `share_plus` - Document sharing
- `photo_view` - Image viewing with zoom
- `intl` - Date formatting
- `uuid` - Unique identifiers

## Setup Instructions

### Prerequisites
- Flutter SDK (3.8.1 or later)
- Dart SDK
- Android Studio / VS Code
- iOS development tools (for iOS deployment)

### Installation
1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Platform Configuration

#### Android
- Minimum SDK: API 21 (Android 5.0)
- Permissions: Camera, Storage access
- Features: Camera hardware requirement

#### iOS
- Minimum iOS: 12.0
- Permissions: Camera usage, Photo library access
- Privacy descriptions included in Info.plist

## Usage Guide

### Scanning Documents
1. Tap the camera button on the home screen
2. Position the document within the guide frame
3. Tap the capture button
4. Proceed to crop and enhance screen

### Enhancing Documents
1. Adjust crop boundaries if needed
2. Apply rotation (90° increments)
3. Select filter (Original, Grayscale, High Contrast)
4. Choose export format (Image or PDF)
5. Enter document name and save

### Managing Documents
- **View**: Tap document card to open detail view
- **Search**: Use search icon to find documents by name
- **Share**: Use share button in document detail or card actions
- **Rename**: Use edit action in document detail or card menu
- **Delete**: Use delete action with confirmation dialog

## Performance Considerations

### Image Processing
- Optimized image compression (90% quality for documents)
- Thumbnail generation (200x200px max)
- Efficient memory management with temporary file cleanup

### Database Operations
- Indexed queries for fast search
- Batch operations for better performance
- Connection pooling with singleton pattern

### UI Responsiveness
- Asynchronous operations with loading states
- Lazy loading for large document collections
- Efficient grid rendering with proper disposal

## Security & Privacy

### Local Storage
- All documents stored locally on device
- No cloud synchronization or external uploads
- SQLite database with proper data isolation

### Permissions
- Runtime permission requests
- Graceful handling of permission denials
- Clear privacy descriptions for users

## Future Enhancements

### Potential Features
- OCR text extraction from documents
- Multi-page PDF support
- Cloud storage integration
- Document templates
- Batch processing
- Advanced image filters
- Document organization with folders
- Export to various formats (Word, etc.)

### Technical Improvements
- Background processing for large files
- Image quality optimization based on content
- Machine learning for automatic document detection
- Backup and restore functionality

## Contributing

### Code Style
- Follow Dart/Flutter conventions
- Use meaningful variable and function names
- Add comments for complex logic
- Maintain consistent file structure

### Testing
- Write unit tests for services
- Add widget tests for UI components
- Integration tests for critical flows
- Performance testing for image operations

## License

This project is created for demonstration purposes. Feel free to use and modify according to your needs.

## Support

For issues or questions:
1. Check the documentation
2. Review error logs
3. Test on different devices
4. Verify permissions are granted

---

Built with ❤️ using Flutter and Material 3 Design