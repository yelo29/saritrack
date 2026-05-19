import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickAndCompressImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Compress image to under 200KB
      final compressedFile = await _compressImage(image);

      // Save to app directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${appDir.path}/$fileName';
      
      await File(compressedFile.path).copy(savedPath);
      
      return savedPath;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  static Future<XFile> _compressImage(XFile image) async {
    final filePath = image.path;
    
    // Compress image
    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      filePath,
      '${filePath}_compressed.jpg',
      quality: 85,
      minWidth: 300,
      minHeight: 300,
    );

    // Check if file size is still too large
    if (compressedFile != null) {
      final fileSize = await File(compressedFile.path).length();
      if (fileSize > 200 * 1024) {
        // Further compress if still too large
        return await _compressFurther(compressedFile);
      }
      return compressedFile;
    }

    return image;
  }

  static Future<XFile> _compressFurther(XFile image) async {
    return await FlutterImageCompress.compressAndGetFile(
      image.path,
      '${image.path}_further.jpg',
      quality: 70,
      minWidth: 200,
      minHeight: 200,
    ) ?? image;
  }

  static Future<void> deleteImage(String? path) async {
    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error deleting image: $e');
      }
    }
  }
}
