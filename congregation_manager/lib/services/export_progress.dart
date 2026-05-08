class ExportProgress {
  final int current;
  final int total;
  final String message;
  final String? detail;

  const ExportProgress({
    required this.current,
    required this.total,
    required this.message,
    this.detail,
  });

  double? get value {
    if (total <= 0) return null;
    return current.clamp(0, total) / total;
  }

  String? get countLabel {
    if (total <= 0) return null;
    return '${current.clamp(0, total)} of $total';
  }
}

typedef ExportProgressCallback = void Function(ExportProgress progress);
