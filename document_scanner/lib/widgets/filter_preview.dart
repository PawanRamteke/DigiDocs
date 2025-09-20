import 'dart:io';
import 'package:flutter/material.dart';
import '../models/document.dart';

class FilterPreview extends StatelessWidget {
  final File imageFile;
  final FilterType filterType;
  final double size;

  const FilterPreview({
    super.key,
    required this.imageFile,
    required this.filterType,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: _buildFilteredImage(),
      ),
    );
  }

  Widget _buildFilteredImage() {
    Widget imageWidget = Image.file(
      imageFile,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: Colors.grey[300],
        child: const Icon(Icons.image, size: 16),
      ),
    );

    // Apply color filter for preview
    return ColorFiltered(
      colorFilter: _getColorFilter(),
      child: imageWidget,
    );
  }

  ColorFilter _getColorFilter() {
    switch (filterType) {
      case FilterType.grayscale:
        return const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case FilterType.highContrast:
        return const ColorFilter.matrix([
          1.5, 0, 0, 0, -50,
          0, 1.5, 0, 0, -50,
          0, 0, 1.5, 0, -50,
          0, 0, 0, 1, 0,
        ]);
      case FilterType.original:
        return const ColorFilter.matrix([
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 1, 0,
        ]);
    }
  }
}
