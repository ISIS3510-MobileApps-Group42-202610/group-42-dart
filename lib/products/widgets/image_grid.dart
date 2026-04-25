import 'dart:io';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../models/product_dto.dart';
import 'image_tile.dart';

class ImageGrid extends StatelessWidget {
  final List<ProductImageDto> existingImages;
  final List<File> newFiles;
  final VoidCallback onAddTap;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onRemoveNew;

  const ImageGrid({
    required this.existingImages,
    required this.newFiles,
    required this.onAddTap,
    required this.onRemoveExisting,
    required this.onRemoveNew,
  });

  @override
  Widget build(BuildContext context) {
    final totalCount = existingImages.length + newFiles.length;

    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Imagenes que ya estan en el backend
          for (var i = 0; i < existingImages.length; i++)
            ImageTile(
              key: ValueKey('existing-${existingImages[i].id}'),
              child: Image.network(
                existingImages[i].url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image_outlined, color: Colors.grey),
              ),
              onRemove: () => onRemoveExisting(existingImages[i].id),
            ),

          // Archivos locales
          for (var i = 0; i < newFiles.length; i++)
            ImageTile(
              key: ValueKey('new-$i'),
              child: Image.file(newFiles[i], fit: BoxFit.cover),
              onRemove: () => onRemoveNew(i),
            ),

          // Boton para añadir imagenes, no mas de 4
          if (totalCount < 4)
            GestureDetector(
              onTap: onAddTap,
              child: Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      color: AppColors.primaryBlue,
                      size: 28,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add photo',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w600,
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
}
