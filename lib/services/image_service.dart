import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../widgets/receipt_preview.dart';

class ImageService {
  static final ImagePicker _picker = ImagePicker();

  /// Picks an image from the gallery and saves it to the app's documents directory.
  static Future<String?> pickAndSaveReceipt() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (image == null) return null;
    return await _saveImageToLocalDirectory(image);
  }
  
  /// Captures an image with the camera and saves it to the app's documents directory.
  static Future<String?> pickFromCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    
    if (image == null) return null;
    return await _saveImageToLocalDirectory(image);
  }
  
  static Future<String> _saveImageToLocalDirectory(XFile image) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedPath = path.join(directory.path, fileName);
    
    final File savedImage = await File(image.path).copy(savedPath);
    return savedImage.path;
  }
  
  /// Deletes a receipt image from local storage.
  static Future<void> deleteReceipt(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) return;
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting receipt: $e');
    }
  }
  
  /// Displays the full-screen receipt preview dialog.
  static Future<String?> showReceiptPreview(BuildContext context, String imagePath) async {
    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ReceiptPreviewDialog(imagePath: imagePath),
    );
  }
}
