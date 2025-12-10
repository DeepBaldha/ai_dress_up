import 'package:ai_dress_up/utils/consts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../view/video_result_screen.dart';
import '../../view_model/background_video_provider.dart';
import '../utils.dart';

class BackgroundTaskWidget extends ConsumerWidget {
  const BackgroundTaskWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taskState = ref.watch(backgroundTaskProvider);

    if (!taskState.hasActiveTask && !taskState.isCompleted) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 50.w),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildLeadingIcon(taskState),

          /*SizedBox(width: 30.w),

          Expanded(child: _buildContent(context, taskState)),

          SizedBox(width: 30.w),

          // Action button
          _buildActionButton(context, ref, taskState),*/
        ],
      ),
    );
  }

  Widget _buildLeadingIcon(BackgroundTaskState taskState) {
    if (taskState.isCompleted) {
      return Icon(Icons.check_circle, color: Colors.green, size: 0.sp);
    } else if (taskState.hasFailed) {
      return Icon(Icons.error, color: Colors.red, size: 60.sp);
    } else {
      return SizedBox(
        width: 270.w,
        height: 270.w,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              '${defaultImagePath}bg_task_icon.png',
              fit: BoxFit.fill,
              height: 250.w,
              width: 250.w,
            ),
            SizedBox(
              width: 250.w,
              height: 250.w,
              child: CircularProgressIndicator(
                value: taskState.progress / 100,
                strokeWidth: 15.w,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            Text(
              '${taskState.progress}%',
              style: TextStyle(
                fontSize: 40.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildContent(BuildContext context, BackgroundTaskState taskState) {
    String title;
    String subtitle;

    if (taskState.isCompleted) {
      title = getTranslated(context)!.videoReady;
      subtitle = taskState.videoModel?.title ?? 'Your video is ready to view';
    } else if (taskState.hasFailed) {
      title = getTranslated(context)!.failed;
      subtitle = taskState.errorMessage ?? 'Something went wrong';
    } else if (taskState.status == 'downloading') {
      title = '${getTranslated(context)!.downloadingVideo}...';
      subtitle = '${taskState.progress}% ${getTranslated(context)!.complete}';
    } else {
      title = '${getTranslated(context)!.processing}...';
      subtitle =
          '${taskState.videoModel?.title ?? "Video"} - ${taskState.progress}%';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 32.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 8.h),
        Text(
          subtitle,
          style: TextStyle(fontSize: 26.sp, color: Colors.grey.shade600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    BackgroundTaskState taskState,
  ) {
    if (taskState.isCompleted) {
      // Show "View" button
      return ElevatedButton(
        onPressed: () => _viewResult(context, ref, taskState),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 25.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        child: Text(
          getTranslated(context)!.view,
          style: TextStyle(fontSize: 30.sp, fontWeight: FontWeight.w600),
        ),
      );
    } else if (taskState.hasFailed) {
      // Show "Dismiss" button
      return TextButton(
        onPressed: () => ref.read(backgroundTaskProvider.notifier).clearTask(),
        style: TextButton.styleFrom(
          foregroundColor: Colors.red,
          padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h),
        ),
        child: Text(
          getTranslated(context)!.dismiss,
          style: TextStyle(fontSize: 28.sp),
        ),
      );
    } else {
      // Show "Cancel" button (optional)
      return TextButton(
        onPressed: () => _showCancelDialog(context, ref),
        style: TextButton.styleFrom(
          foregroundColor: Colors.grey,
          padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h),
        ),
        child: Text(
          getTranslated(context)!.cancel,
          style: TextStyle(fontSize: 28.sp),
        ),
      );
    }
  }

  Future<void> _viewResult(
    BuildContext context,
    WidgetRef ref,
    BackgroundTaskState taskState,
  ) async {
    if (taskState.localVideoPath == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoResultScreen(
          video: taskState.localVideoPath!,
          title: taskState.videoModel?.title ?? 'Generated Video',
          autoSave: true,
          from: 'background',
        ),
      ),
    );

    ref.read(backgroundTaskProvider.notifier).clearTask();
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(getTranslated(context)!.cancelTask),
        content: Text(getTranslated(context)!.cancelTaskMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(getTranslated(context)!.no),
          ),
          TextButton(
            onPressed: () {
              ref.read(backgroundTaskProvider.notifier).cancelTask();
              Navigator.pop(context);
            },
            child: Text(
              getTranslated(context)!.yes,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
