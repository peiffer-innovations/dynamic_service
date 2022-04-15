class RemoteFile {
  RemoteFile({
    required this.contentType,
    required this.data,
  });

  final String contentType;
  final List<int> data;
}
