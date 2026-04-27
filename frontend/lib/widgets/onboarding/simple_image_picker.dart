import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Widget simples de upload de imagem com estilo de input
class SimpleImagePicker extends StatelessWidget {
  final String label;
  final File? imageFile;
  final ValueChanged<File?> onImageSelected;

  const SimpleImagePicker({
    super.key,
    required this.label,
    this.imageFile,
    required this.onImageSelected,
  });

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      onImageSelected(File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withOpacity(0.87),
              ),
            ),
          ),
        
        // Campo de upload
        InkWell(
          onTap: _pickImage,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Ícone de upload
                Icon(
                  Icons.cloud_upload_outlined,
                  color: colorScheme.onSurface.withOpacity(0.56),
                  size: 24,
                ),
                const SizedBox(width: 12),
                
                // Texto
                Expanded(
                  child: Text(
                    imageFile != null
                        ? imageFile!.path.split('/').last
                        : 'Upload file',
                    style: TextStyle(
                      fontSize: 16,
                      color: imageFile != null
                          ? colorScheme.onSurface.withOpacity(0.87)
                          : colorScheme.onSurface.withOpacity(0.56),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // Ícone de remover (se tiver arquivo)
                if (imageFile != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => onImageSelected(null),
                    child: Icon(
                      Icons.close,
                      color: colorScheme.onSurface.withOpacity(0.56),
                      size: 20,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
