import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/document_controller.dart';
import '../models/document.dart';
import '../widgets/document_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/search_bar_widget.dart';
import 'document_detail_screen.dart';
import 'multi_scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DocumentController _controller = Get.find<DocumentController>();
  bool _isSearching = false;
  bool _isGridView = true; // true for grid, false for list

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? SearchBarWidget(
                controller: _searchController,
                onChanged: (query) {
                  if (query.isEmpty) {
                    _controller.loadDocuments();
                  } else {
                    _controller.searchDocuments(query);
                  }
                },
                onClear: () {
                  _searchController.clear();
                  _controller.loadDocuments();
                },
              )
            : const Text('DigiDocs'),
        actions: [
          if (!_isSearching)
            IconButton(
              icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
              tooltip: _isGridView ? 'Switch to List View' : 'Switch to Grid View',
              onPressed: () {
                setState(() {
                  _isGridView = !_isGridView;
                });
              },
            ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _controller.loadDocuments();
                }
              });
            },
          ),
        ],
      ),
      body: Obx(() {

        if (_controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (_controller.documents.isEmpty) {
          return _buildEmptyStateWithActions(_controller.searchQuery);
        }

        return RefreshIndicator(
          onRefresh: () async {
            await _controller.loadDocuments();
          },
          child: CustomScrollView(
            slivers: [
              if (_controller.searchQuery.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Found ${_controller.documents.length} document(s) for "${_controller.searchQuery}"',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: _isGridView
                    ? _buildGridView()
                    : _buildListView(),
              ),
            ],
          ),
        );
      }),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _startMultiScan(),
              icon: const Icon(Icons.document_scanner),
              label: const Text('Scan Document'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateWithActions(String? searchQuery) {
    if (searchQuery != null && searchQuery.isNotEmpty) {
      // Show regular empty state for search results
      return EmptyState(
        title: 'No documents found',
        subtitle: 'Try adjusting your search terms',
        icon: Icons.search_off,
      );
    }

    // Show empty state with action buttons for no documents
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.document_scanner_outlined,
              size: 120,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No documents yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use the scan button below to start creating documents',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView() {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final document = _controller.documents[index];
          return DocumentCard(
            document: document,
            onTap: () => _openDocument(document),
            onDelete: () => _deleteDocument(document),
            onRename: () => _renameDocument(document),
            onShare: () => _shareDocument(document),
          );
        },
        childCount: _controller.documents.length,
      ),
    );
  }

  Widget _buildListView() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final document = _controller.documents[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: _buildListThumbnail(document),
                ),
                title: Text(
                  document.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          document.type == DocumentType.pdf
                              ? Icons.picture_as_pdf
                              : Icons.image,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          document.type.name.toUpperCase(),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatFileSize(document.fileSize),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(document.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => _handleListItemAction(document, value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'share',
                      child: ListTile(
                        leading: Icon(Icons.share),
                        title: Text('Share'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'rename',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Rename'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Delete', style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
                onTap: () => _openDocument(document),
              ),
            ),
          );
        },
        childCount: _controller.documents.length,
      ),
    );
  }

  Widget _buildListThumbnail(Document document) {
    if (document.thumbnailPath != null && File(document.thumbnailPath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(document.thumbnailPath!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultListThumbnail(document),
        ),
      );
    } else {
      return _buildDefaultListThumbnail(document);
    }
  }

  Widget _buildDefaultListThumbnail(Document document) {
    return Center(
      child: Icon(
        document.type == DocumentType.pdf
            ? Icons.picture_as_pdf_outlined
            : Icons.image_outlined,
        size: 32,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleListItemAction(Document document, String action) {
    switch (action) {
      case 'share':
        _shareDocument(document);
        break;
      case 'rename':
        _renameDocument(document);
        break;
      case 'delete':
        _deleteDocument(document);
        break;
    }
  }

  void _startMultiScan() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MultiScanScreen(),
      ),
    );
  }

  void _openDocument(Document document) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DocumentDetailScreen(document: document),
      ),
    );
  }

  void _deleteDocument(Document document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${document.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _controller.deleteDocument(document.id);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _renameDocument(Document document) {
    final controller = TextEditingController(text: document.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Document'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Document name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != document.name) {
                Navigator.of(context).pop();
                _controller.renameDocument(document.id, newName);
              } else {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _shareDocument(Document document) {
    _controller.shareDocument(document.id);
  }
}
