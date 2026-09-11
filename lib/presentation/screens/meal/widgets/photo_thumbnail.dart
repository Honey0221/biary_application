import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PhotoThumbnail extends StatelessWidget {
  final Widget image;
  final VoidCallback onRemove;

  const PhotoThumbnail._({
    required this.image, required this.onRemove
  });

  factory PhotoThumbnail.local({
    required String path,
    required VoidCallback onRemove
  }) => PhotoThumbnail._(
    image: Image.file(File(path),
      width: 80, height: 80, fit: BoxFit.cover
    ), onRemove: onRemove
  );

  factory PhotoThumbnail.network({
    required String url,
    required VoidCallback onRemove
  }) => PhotoThumbnail._(
    image: Image.network(url,
      width: 80, height: 80, fit: BoxFit.cover
    ), onRemove: onRemove
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: image
        ),
        Positioned(
          top: 2, right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20, height: 20,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle
              ),
              child: const Icon(LucideIcons.x, size: 12, color: Colors.white)
            )
          )
        )
      ]
    );
  }
}