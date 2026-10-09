/// VIT-AP Sports — Image utilities.
///
/// Compress images before uploading to Supabase Storage (free tier optimization).
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class ImageUtils {
  ImageUtils._();

  static final ImagePicker _picker = ImagePicker();

  /// Max upload size in bytes (1MB)
  static const int maxUploadSize = 1024 * 1024;

  /// Pick an image from gallery and compress it.
  static Future<Uint8List?> pickAndCompressImage({
    ImageSource source = ImageSource.gallery,
    int maxWidth = 512,
    int maxHeight = 512,
    int quality = 75,
  }) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: maxWidth.toDouble(),
      maxHeight: maxHeight.toDouble(),
    );

    if (picked == null) return null;

    return compressFile(
      File(picked.path),
      quality: quality,
    );
  }

  /// Compress a file to JPEG with given quality.
  static Future<Uint8List?> compressFile(
    File file, {
    int quality = 75,
    int minWidth = 256,
    int minHeight = 256,
  }) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: quality,
      minWidth: minWidth,
      minHeight: minHeight,
      format: CompressFormat.jpeg,
    );

    return result;
  }
}
