import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Widget compacto de upload de imagem (56px altura)
class CompactImagePicker extends StatefulWidget {
  final String label;
  final File? imageFile;
  final ValueChanged<File?> onImageSelected;

  const CompactImagePicker({
    super.key,
    required this.label,
    this.imageFile,
    required this.onImageSelected,
  });

  @override
  State<CompactImagePicker> createState() => _CompactImagePickerState();
}

class _CompactImagePickerState extends State<CompactImagePicker> {
  Uint8List? _webImage;
  String? _fileName;

  String _getCleanFileName(String name) {
    // Se o nome parece ser um UUID/hash (contém hífens e é longo), usar nome genérico
    if (name.contains('-') && name.length > 30) {
      // Tentar pegar extensão do path original
      final ext = name.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(ext)) {
        return 'logo.$ext';
      }
      return 'logo.jpg';
    }
    return name;
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
        if (kIsWeb) {
          // Para web, usar bytes
          final bytes = await pickedFile.readAsBytes();
          final sizeInMB = bytes.length / (1024 * 1024);
          
          if (sizeInMB > 5) {
            return;
          }
          
          setState(() {
            _webImage = bytes;
            _fileName = _getCleanFileName(pickedFile.name);
          });
          widget.onImageSelected(File(pickedFile.path));
        } else {
          // Para mobile/desktop, usar File
          final file = File(pickedFile.path);
          final sizeInBytes = await file.length();
          final sizeInMB = sizeInBytes / (1024 * 1024);

          if (sizeInMB > 5) {
            return;
          }

          setState(() {
            _fileName = _getCleanFileName(pickedFile.name);
          });
          widget.onImageSelected(file);
        }
      }
    } catch (e) {
      debugPrint('Erro ao selecionar imagem: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        if (widget.label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withOpacity(0.87),
              ),
            ),
          ),
        
        // Campo de upload
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: _pickImage,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 117,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F8),
                borderRadius: BorderRadius.circular(8),
              ),
            child: widget.imageFile != null || _webImage != null
                ? Row(
                    children: [
                      // Ícone de arquivo
                      Icon(
                        Icons.insert_drive_file_outlined,
                        color: colorScheme.onSurface.withOpacity(0.56),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      
                      // Nome do arquivo
                      Expanded(
                        child: Text(
                          _fileName ?? widget.imageFile?.path.split('/').last ?? 'image.jpg',
                          style: TextStyle(
                            fontSize: 16,
                            color: colorScheme.onSurface.withOpacity(0.87),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      // Botão de remover
                      const SizedBox(width: 8),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _webImage = null;
                              _fileName = null;
                            });
                            widget.onImageSelected(null);
                          },
                          child: Icon(
                            Icons.close,
                            color: colorScheme.onSurface.withOpacity(0.56),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          color: colorScheme.onSurface.withOpacity(0.56),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upload file',
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onSurface.withOpacity(0.56),
                              ),
                            ),
                            Text(
                              'Max 5MB • JPG, PNG, WEBP, GIF',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withOpacity(0.38),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
