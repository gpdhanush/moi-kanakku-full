import 'package:flutter/material.dart';

enum ImagePickerAction { gallery, camera, delete }

class ImagePickerBottomSheet extends StatelessWidget {
  final String title;
  final String galleryLabel;
  final String cameraLabel;
  final String deleteLabel;
  final String permissionsMessage;
  final bool canUseGallery;
  final bool canUseCamera;
  final bool showDelete;

  const ImagePickerBottomSheet({
    super.key,
    required this.title,
    required this.galleryLabel,
    required this.cameraLabel,
    required this.deleteLabel,
    required this.permissionsMessage,
    required this.canUseGallery,
    required this.canUseCamera,
    this.showDelete = false,
  });

  static Future<ImagePickerAction?> show({
    required BuildContext context,
    required String title,
    required String galleryLabel,
    required String cameraLabel,
    required String deleteLabel,
    required String permissionsMessage,
    required bool canUseGallery,
    required bool canUseCamera,
    bool showDelete = false,
  }) {
    return showModalBottomSheet<ImagePickerAction?>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ImagePickerBottomSheet(
        title: title,
        galleryLabel: galleryLabel,
        cameraLabel: cameraLabel,
        deleteLabel: deleteLabel,
        permissionsMessage: permissionsMessage,
        canUseGallery: canUseGallery,
        canUseCamera: canUseCamera,
        showDelete: showDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final options = <Widget>[];

    if (showDelete) {
      options.add(
        _buildOption(
          context,
          icon: Icons.delete_outline_rounded,
          label: deleteLabel,
          color: Colors.redAccent,
          onTap: () => Navigator.pop(context, ImagePickerAction.delete),
        ),
      );
    }
    if (canUseGallery) {
      options.add(
        _buildOption(
          context,
          icon: Icons.photo_library_outlined,
          label: galleryLabel,
          color: colorScheme.primary,
          onTap: () => Navigator.pop(context, ImagePickerAction.gallery),
        ),
      );
    }
    if (canUseCamera) {
      options.add(
        _buildOption(
          context,
          icon: Icons.camera_alt_outlined,
          label: cameraLabel,
          color: colorScheme.primary,
          onTap: () => Navigator.pop(context, ImagePickerAction.camera),
        ),
      );
    }

    return SafeArea(
      child: Container(
        constraints: const BoxConstraints(minHeight: 360),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 22,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    color: colorScheme.onPrimary,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (options.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
                child: Text(
                  permissionsMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                ),
              )
            else
              ...options,
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(5),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
