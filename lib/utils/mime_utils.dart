String audioMimeTypeForPath(String filePath) {
  final dotIndex = filePath.lastIndexOf('.');
  if (dotIndex == -1 || dotIndex == filePath.length - 1) {
    return 'audio/*';
  }

  final ext = filePath.substring(dotIndex + 1).toLowerCase();
  switch (ext) {
    case 'flac':
      return 'audio/flac';
    case 'm4a':
      return 'audio/mp4';
    case 'mp3':
      return 'audio/mpeg';
    case 'ogg':
      return 'audio/ogg';
    case 'wav':
      return 'audio/wav';
    case 'aac':
      return 'audio/aac';
    default:
      return 'audio/*';
  }
}
