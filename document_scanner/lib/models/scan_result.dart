import 'dart:io';
import 'document.dart';

class ScanResult {
  final File imageFile;
  final FilterType appliedFilter;
  final double rotation;
  final bool isCropped;

  const ScanResult({
    required this.imageFile,
    this.appliedFilter = FilterType.original,
    this.rotation = 0.0,
    this.isCropped = false,
  });

  ScanResult copyWith({
    File? imageFile,
    FilterType? appliedFilter,
    double? rotation,
    bool? isCropped,
  }) {
    return ScanResult(
      imageFile: imageFile ?? this.imageFile,
      appliedFilter: appliedFilter ?? this.appliedFilter,
      rotation: rotation ?? this.rotation,
      isCropped: isCropped ?? this.isCropped,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanResult &&
          runtimeType == other.runtimeType &&
          imageFile.path == other.imageFile.path;

  @override
  int get hashCode => imageFile.path.hashCode;
}
