class UploadProgress {
  final int bytesSent;
  final int totalBytes;

  const UploadProgress({
    required this.bytesSent,
    required this.totalBytes,
  });

  double get percentage => totalBytes > 0 ? bytesSent / totalBytes : 0.0;
}
