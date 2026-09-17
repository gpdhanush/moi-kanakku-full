import 'package:flutter/material.dart';

/// Network image with decode-size limits to reduce memory use.
class MoiNetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const MoiNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
    this.loadingBuilder,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = memCacheWidth ??
        (width != null && width!.isFinite ? (width! * dpr).round() : 256);
    final cacheH = memCacheHeight ??
        (height != null && height!.isFinite ? (height! * dpr).round() : null);

    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      cacheWidth: cacheW,
      cacheHeight: cacheH,
      filterQuality: FilterQuality.medium,
      errorBuilder: errorBuilder,
      loadingBuilder: loadingBuilder,
    );
  }
}
