import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/document.dart';

class DocumentCard extends StatelessWidget {
  final Document document;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final VoidCallback onShare;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document thumbnail or icon
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: _buildThumbnail(context),
              ),
            ),
            // Document info
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Document name
                  Flexible(
                    child: Text(
                      document.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Document type and date
                  Flexible(
                    child: Row(
                      children: [
                        Icon(
                          document.type == DocumentType.pdf
                              ? Icons.picture_as_pdf
                              : Icons.image,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            DateFormat('MMM dd, yyyy').format(document.createdAt),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildActionButton(
                        context,
                        icon: Icons.share,
                        onPressed: onShare,
                      ),
                      _buildActionButton(
                        context,
                        icon: Icons.edit,
                        onPressed: onRename,
                      ),
                      _buildActionButton(
                        context,
                        icon: Icons.delete,
                        onPressed: onDelete,
                        isDestructive: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    if (document.thumbnailPath != null && File(document.thumbnailPath!).existsSync()) {
      return Image.file(
        File(document.thumbnailPath!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultThumbnail(context),
      );
    } else {
      return _buildDefaultThumbnail(context);
    }
  }

  Widget _buildDefaultThumbnail(BuildContext context) {
    return Center(
      child: Icon(
        document.type == DocumentType.pdf
            ? Icons.picture_as_pdf_outlined
            : Icons.image_outlined,
        size: 48,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        icon: Icon(
          icon,
          size: 16,
          color: isDestructive
              ? Theme.of(context).colorScheme.error
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
