import 'package:flutter/material.dart';
import 'package:moi/app_configs/app_images.dart';
import 'package:moi/app_utils/app_widgets/moi_network_image.dart';

/// Circular user avatar that falls back to a gender placeholder when the
/// network image is missing (404) and optionally notifies so callers can
/// clear a stale URL from storage.
class MoiUserAvatar extends StatefulWidget {
  final String imageUrl;
  final String? gender;
  final double size;
  final VoidCallback? onImageMissing;

  const MoiUserAvatar({
    super.key,
    required this.imageUrl,
    this.gender,
    this.size = 48,
    this.onImageMissing,
  });

  @override
  State<MoiUserAvatar> createState() => _MoiUserAvatarState();
}

class _MoiUserAvatarState extends State<MoiUserAvatar> {
  bool _failed = false;

  @override
  void didUpdateWidget(covariant MoiUserAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _failed = false;
    }
  }

  Widget _placeholder() {
    return Image.asset(
      AppImages.profileForGender(widget.gender),
      fit: BoxFit.cover,
      width: widget.size,
      height: widget.size,
    );
  }

  void _handleMissing() {
    if (_failed) return;
    setState(() => _failed = true);
    widget.onImageMissing?.call();
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.imageUrl.trim();
    if (url.isEmpty || _failed) {
      return _placeholder();
    }

    return MoiNetworkImage(
      url: url,
      fit: BoxFit.cover,
      width: widget.size,
      height: widget.size,
      errorBuilder: (context, error, stackTrace) {
        // Only treat 404 as permanently missing — other errors may be transient.
        final is404 = error is NetworkImageLoadException &&
            error.statusCode == 404;
        if (is404) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _handleMissing();
          });
        }
        return _placeholder();
      },
    );
  }
}
