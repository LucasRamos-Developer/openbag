import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Widget para selecionar e exibir uma imagem
class ImagePickerCard extends StatelessWidget {
  final String label;
  final File? imageFile;
  final ValueChanged<File?> onImageSelected;
  final VoidCallback? onRemove;

  const ImagePickerCard({
    super.key,
    required this.label,
    this.imageFile,
    required this.onImageSelected,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  Icons.image,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const Spacer(),
                if (imageFile != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: onRemove ?? () => onImageSelected(null),
                    tooltip: 'Remover imagem',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),

          // Preview area
          InkWell(
            onTap: _pickImage,
            child: Container(
              height: 200,
              color: Colors.grey[100],
              child: imageFile != null
                  ? Stack(
                      children: [
                        Image.file(
                          imageFile!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: _buildFileSizeBadge(),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Toque para selecionar',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Max 5MB • JPG, PNG, WEBP, GIF',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileSizeBadge() {
    if (imageFile == null) return const SizedBox.shrink();

    final sizeInBytes = imageFile!.lengthSync();
    final sizeInMB = sizeInBytes / (1024 * 1024);
    final sizeText = sizeInMB >= 1
        ? '${sizeInMB.toStringAsFixed(1)} MB'
        : '${(sizeInBytes / 1024).toStringAsFixed(0)} KB';

    final isTooBig = sizeInMB > 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isTooBig ? Colors.red : Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        sizeText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        
        // Verificar tamanho do arquivo
        final sizeInBytes = await file.length();
        final sizeInMB = sizeInBytes / (1024 * 1024);

        if (sizeInMB > 5) {
          // TODO: Mostrar erro ao usuário
          print('Imagem muito grande! Tamanho máximo: 5MB');
          return;
        }

        // Verificar extensão
        final extension = pickedFile.path.split('.').last.toLowerCase();
        const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'gif'];
        
        if (!allowedExtensions.contains(extension)) {
          print('Formato não permitido! Use: JPG, PNG, WEBP ou GIF');
          return;
        }

        onImageSelected(file);
      }
    } catch (e) {
      print('Erro ao selecionar imagem: $e');
    }
  }
}
