const List<String> _videoExtensions = ['mp4', 'webm', 'mov'];

bool isVideoExtension(String? extension) {
  if (extension == null || extension.isEmpty) return false;
  return _videoExtensions.contains(extension.toLowerCase());
}

String getFileExtension(String url) {
  if (url.isEmpty) return '';
  final cleanUrl = url.split('?').first;
  final lastDot = cleanUrl.lastIndexOf('.');
  if (lastDot == -1 || lastDot == cleanUrl.length - 1) return '';
  return cleanUrl.substring(lastDot + 1).toLowerCase();
}

bool isVideoUrl(String url) {
  return isVideoExtension(getFileExtension(url));
}
