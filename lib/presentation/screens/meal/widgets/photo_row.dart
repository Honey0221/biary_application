import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/meal_record_photo.dart';

class PhotoRow extends StatelessWidget {
  final List<MealRecordPhoto> photos;

  const PhotoRow({super.key, required this.photos});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              photos[i].photoUrl,
              width: 100, height: 100,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 100, height: 100,
                color: AppColors.surfaceMuted,
                child: const Icon(
                  LucideIcons.imageOff,
                  color: AppColors.grayCaption
                )
              )
            )
          );
        }
      )
    );
  }
}