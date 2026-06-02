/// Web placeholder — receipt OCR is mobile-only.
class PlatformImage {
  const PlatformImage(this.path);
  final String path;
}

PlatformImage platformImageFromPath(String path) => PlatformImage(path);

PlatformImage platformImageFromXFilePath(String path) => PlatformImage(path);
