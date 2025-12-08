import 'dart:io';
import 'package:ai_dress_up/utils/custom_widgets/deep_press_unpress.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/consts.dart';
import '../utils/firebase_analytics_service.dart';
import '../utils/utils.dart';
import '../view_model/image_result_provider.dart';
import 'image_result_full_screen.dart';

class ImageResultHistoryScreen extends ConsumerStatefulWidget {
  const ImageResultHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ImageResultHistoryScreen> createState() =>
      _ImageResultHistoryScreenState();
}

class _ImageResultHistoryScreenState
    extends ConsumerState<ImageResultHistoryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(imageResultProvider).loadImages());
    WidgetsBinding.instance.addPostFrameCallback((callback) {
      FirebaseAnalyticsService.logEvent(
        eventName: 'IMAGE_CREATION_LIST_SCREEN',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageNotifier = ref.watch(imageResultProvider);
    return Builder(
      builder: (context) {
        final provider = ref.watch(imageResultProvider);
        if (provider.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            await provider.loadImages();
          },
          child: _buildGrid(context, imageNotifier),
        );
      },
    );
  }

  /*@override
  Widget build(BuildContext context) {
    final imageNotifier = ref.watch(imageResultProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: imageNotifier.isEmpty
          ? _buildEmptyState()
          : _buildGrid(context, imageNotifier),
    );
  }*/


  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('${defaultImagePath}creation_empty.png', height: 750.h),
        50.verticalSpace,
        Text(
          getTranslated(context)!.thereIsNoItemHere,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 70.sp),
        ),
        20.verticalSpace,
        Text(
          getTranslated(context)!.beginYourImageAndVideoMagicToday,
          style: TextStyle(color: Color(0xff949494)),
        ),
        200.verticalSpace,
      ],
    );
  }

  Widget _buildGrid(BuildContext context, ImageResultNotifier imageNotifier) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        itemCount: imageNotifier.imageCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        itemBuilder: (_, index) {
          final item = imageNotifier.images[index];

          return NewDeepPressUnpress(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImageResultFullScreen(
                    imagePath: item.imagePath,
                    autoSave: false,
                    from: 'history',
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(50.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50.r),
                child: Image.file(
                  File(item.imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white54),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
