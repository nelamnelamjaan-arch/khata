import 'dart:io';

typedef PlatformImage = File;

PlatformImage platformImageFromPath(String path) => File(path);

PlatformImage platformImageFromXFilePath(String path) => File(path);
