sealed class UploadFileSource {
  const UploadFileSource();
}

class FileBytes extends UploadFileSource {
  final List<int> bytes;
  const FileBytes(this.bytes);
}

class FilePath extends UploadFileSource {
  final String path;
  const FilePath(this.path);
}

class UploadFile {
  final String fieldName;
  final String filename;
  final UploadFileSource source;
  final String? mimeType;

  const UploadFile({
    required this.fieldName,
    required this.filename,
    required this.source,
    this.mimeType,
  });
}
