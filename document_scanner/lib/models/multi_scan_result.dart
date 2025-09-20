import 'document.dart';
import 'scan_result.dart';

class MultiScanResult {
  final List<ScanResult> scanResults;
  final String documentName;
  final FilterType globalFilter;

  const MultiScanResult({
    required this.scanResults,
    required this.documentName,
    this.globalFilter = FilterType.original,
  });

  MultiScanResult copyWith({
    List<ScanResult>? scanResults,
    String? documentName,
    FilterType? globalFilter,
  }) {
    return MultiScanResult(
      scanResults: scanResults ?? this.scanResults,
      documentName: documentName ?? this.documentName,
      globalFilter: globalFilter ?? this.globalFilter,
    );
  }

  MultiScanResult addScanResult(ScanResult scanResult) {
    print('MultiScanResult - addScanResult called, current count: ${scanResults.length}');
    final newScanResults = [...scanResults, scanResult];
    print('MultiScanResult - new count will be: ${newScanResults.length}');
    return copyWith(
      scanResults: newScanResults,
    );
  }

  MultiScanResult removeScanResult(int index) {
    if (index >= 0 && index < scanResults.length) {
      final newList = List<ScanResult>.from(scanResults);
      newList.removeAt(index);
      return copyWith(scanResults: newList);
    }
    return this;
  }

  MultiScanResult updateScanResult(int index, ScanResult updatedScanResult) {
    if (index >= 0 && index < scanResults.length) {
      final newList = List<ScanResult>.from(scanResults);
      newList[index] = updatedScanResult;
      return copyWith(scanResults: newList);
    }
    return this;
  }

  MultiScanResult reorderScanResults(int oldIndex, int newIndex) {
    if (oldIndex >= 0 && oldIndex < scanResults.length && 
        newIndex >= 0 && newIndex < scanResults.length) {
      final newList = List<ScanResult>.from(scanResults);
      final item = newList.removeAt(oldIndex);
      newList.insert(newIndex, item);
      return copyWith(scanResults: newList);
    }
    return this;
  }

  bool get isEmpty => scanResults.isEmpty;
  bool get isNotEmpty => scanResults.isNotEmpty;
  int get length => scanResults.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MultiScanResult &&
          runtimeType == other.runtimeType &&
          documentName == other.documentName;

  @override
  int get hashCode => documentName.hashCode;
}
