import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

class ImageUploadCropper {
  const ImageUploadCropper._();

  static Future<File?> crop({
    required BuildContext context,
    required String imagePath,
    required String title,
    double? aspectRatioX,
    double? aspectRatioY,
    int compressQuality = 100,
  }) async {
    try {
      final primary = Theme.of(context).colorScheme.primary;
      final cropper = await ImageCropper().cropImage(
        sourcePath: imagePath,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: compressQuality,
        aspectRatio: aspectRatioX != null && aspectRatioY != null
            ? CropAspectRatio(ratioX: aspectRatioX, ratioY: aspectRatioY)
            : null,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: title,
            statusBarLight: true,
            activeControlsWidgetColor: primary,
            toolbarColor: primary,
            navBarLight: false,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: aspectRatioX == 16 && aspectRatioY == 9
                ? CropAspectRatioPreset.ratio16x9
                : CropAspectRatioPreset.square,
            lockAspectRatio: false,
            aspectRatioPresets: const [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio16x9,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.original,
            ],
          ),
          IOSUiSettings(
            title: title,
            aspectRatioLockEnabled: false,
            aspectRatioPresets: const [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio16x9,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.original,
            ],
          ),
        ],
      );
      return cropper == null ? null : File(cropper.path);
    } catch (_) {
      return File(imagePath);
    }
  }
}
