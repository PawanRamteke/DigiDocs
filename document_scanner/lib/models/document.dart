enum DocumentType { image, pdf }

enum FilterType { original, grayscale, highContrast }

class Document {
  final String id;
  final String name;
  final String filePath;
  final String? thumbnailPath;
  final DocumentType type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int fileSize;
  final FilterType appliedFilter;
  final double rotation;

  const Document({
    required this.id,
    required this.name,
    required this.filePath,
    this.thumbnailPath,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    required this.fileSize,
    this.appliedFilter = FilterType.original,
    this.rotation = 0.0,
  });

  Document copyWith({
    String? id,
    String? name,
    String? filePath,
    String? thumbnailPath,
    DocumentType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? fileSize,
    FilterType? appliedFilter,
    double? rotation,
  }) {
    return Document(
      id: id ?? this.id,
      name: name ?? this.name,
      filePath: filePath ?? this.filePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fileSize: fileSize ?? this.fileSize,
      appliedFilter: appliedFilter ?? this.appliedFilter,
      rotation: rotation ?? this.rotation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'filePath': filePath,
      'thumbnailPath': thumbnailPath,
      'type': type.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'fileSize': fileSize,
      'appliedFilter': appliedFilter.name,
      'rotation': rotation,
    };
  }

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      name: json['name'],
      filePath: json['filePath'],
      thumbnailPath: json['thumbnailPath'],
      type: DocumentType.values.firstWhere((e) => e.name == json['type']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
      fileSize: json['fileSize'],
      appliedFilter: FilterType.values.firstWhere(
        (e) => e.name == json['appliedFilter'],
        orElse: () => FilterType.original,
      ),
      rotation: json['rotation'] ?? 0.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Document &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
