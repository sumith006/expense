import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/neobrutal_theme.dart';

class ProfileAvatar extends StatefulWidget {
  final String? photoPath;
  final String userInitials;
  final Function(String path) onPhotoSelected;

  const ProfileAvatar({
    super.key,
    this.photoPath,
    required this.userInitials,
    required this.onPhotoSelected,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        // Save the image to app documents directory without cropping
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'profile_photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedPath = '${appDir.path}/$fileName';
        
        final File imageFile = File(pickedFile.path);
        final savedFile = await imageFile.copy(savedPath);
        
        if (mounted) {
          widget.onPhotoSelected(savedFile.path);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showImageSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: NeoBrutalTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'CHANGE PROFILE PHOTO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: NeoBrutalTheme.primary.withValues(alpha: 0.1),
                        borderRadius: NeoBrutalTheme.radiusMedium,
                        border: Border.all(
                          color: NeoBrutalTheme.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.camera_alt_rounded,
                            color: NeoBrutalTheme.primary,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'CAMERA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: NeoBrutalTheme.secondary.withValues(alpha: 0.1),
                        borderRadius: NeoBrutalTheme.radiusMedium,
                        border: Border.all(
                          color: NeoBrutalTheme.secondary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.image_rounded,
                            color: NeoBrutalTheme.secondary,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'GALLERY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showImageSourceBottomSheet,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white24,
                width: 2,
              ),
              image: widget.photoPath != null
                  ? DecorationImage(
                      image: FileImage(File(widget.photoPath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: widget.photoPath == null
                ? Container(
                    decoration: BoxDecoration(
                      gradient: NeoBrutalTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.userInitials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: NeoBrutalTheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: NeoBrutalTheme.background, width: 2),
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
