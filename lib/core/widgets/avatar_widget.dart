import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final String initials;
  final double size;
  final VoidCallback? onTap;

  const AvatarWidget({
    super.key,
    this.imageUrl,
    required this.initials,
    this.size = 48,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(color: AppColors.muted, width: 1),
      ),
      child:
          imageUrl != null && imageUrl!.isNotEmpty
              ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  placeholder:
                      (context, url) => Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontSize: size * 0.35,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                  errorWidget:
                      (context, url, error) => Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontSize: size * 0.35,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                      ),
                ),
              )
              : Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: size * 0.35,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }
}
