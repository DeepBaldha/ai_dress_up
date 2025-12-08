import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import '../consts.dart';
import '../utils.dart';

enum PlaceholderType {
  lottie,
  shimmer,
}

class RetryingNetworkImage extends StatefulWidget {
  final String imageUrl;
  final String? identifier;
  final BoxFit fit;
  final PlaceholderType placeholderType;
  final Widget? customPlaceholder;
  final int? maxHeightDiskCache;
  final int? maxWidthDiskCache;
  final int? memCacheHeight;
  final int? memCacheWidth;

  const RetryingNetworkImage({
    Key? key,
    required this.imageUrl,
    this.identifier,
    this.fit = BoxFit.cover,
    this.placeholderType = PlaceholderType.lottie,
    this.customPlaceholder,
    this.maxHeightDiskCache = 400,
    this.maxWidthDiskCache = 300,
    this.memCacheHeight = 400,
    this.memCacheWidth = 300,
  }) : super(key: key);

  @override
  State<RetryingNetworkImage> createState() => _RetryingNetworkImageState();
}

class _RetryingNetworkImageState extends State<RetryingNetworkImage> {
  int _retryCount = 0;
  Key _imageKey = UniqueKey();

  void _retryLoad() {
    if (!mounted) return;
    setState(() {
      _retryCount++;
      _imageKey = UniqueKey();
      showLog('🔄 Retrying image load${widget.identifier != null ? ' for ${widget.identifier}' : ''} (attempt $_retryCount)');
    });
  }

  Widget _buildPlaceholder() {
    if (widget.customPlaceholder != null) {
      return widget.customPlaceholder!;
    }

    switch (widget.placeholderType) {
      case PlaceholderType.lottie:
        return Container(
          color: Colors.grey[900],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  '${defaultImagePath}loader.json',
                  width: 150.w,
                  height: 150.w,
                ),
                if (_retryCount > 0) ...[
                  10.verticalSpace,
                  Text(
                    'Loading... ($_retryCount)',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 30.sp,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      case PlaceholderType.shimmer:
        return Shimmer.fromColors(
          baseColor: Colors.grey[800]!,
          highlightColor: Colors.grey[600]!,
          child: Container(
            color: Colors.grey[800],
            child: _retryCount > 0
                ? Center(
              child: Text(
                'Loading... ($_retryCount)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            )
                : null,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      key: _imageKey,
      imageUrl: widget.imageUrl,
      fit: widget.fit,
      maxHeightDiskCache: widget.maxHeightDiskCache,
      maxWidthDiskCache: widget.maxWidthDiskCache,
      memCacheHeight: widget.memCacheHeight,
      memCacheWidth: widget.memCacheWidth,
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) {
        showLog('❌ Image error${widget.identifier != null ? ' for ${widget.identifier}' : ''}: $error');

        // Auto retry after 2 seconds
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            _retryLoad();
          }
        });

        return _buildPlaceholder();
      },
    );
  }
}