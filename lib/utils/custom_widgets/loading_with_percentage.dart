import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../consts.dart';
import '../utils.dart';

class LoadingProgressWidget extends StatefulWidget {
  final int percentage;
  final String? message1;
  final String? message2;

  const LoadingProgressWidget({
    super.key,
    required this.percentage,
    this.message1,
    this.message2,
  });

  @override
  State<LoadingProgressWidget> createState() => _LoadingProgressWidgetState();
}

class _LoadingProgressWidgetState extends State<LoadingProgressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _updateProgress();
  }

  @override
  void didUpdateWidget(LoadingProgressWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      _updateProgress();
    }
  }

  void _updateProgress() {
    final progress = widget.percentage / 100.0;

    _controller.stop();
    _controller.reset();

    const fixedDuration = Duration(seconds: 2);

    _controller.repeat(min: 0.0, max: progress, period: fixedDuration);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String mainText =
        widget.message1 ?? "${getTranslated(context)!.pleaseWait}...";

    final String subText =
        widget.message2 ??
        getTranslated(context)!.yourResultIsOnTheWayJustAFewMinutesToGo;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 80.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 100.w),
            child: Image.asset(
              width: double.infinity,
              '${defaultImagePath}loading_logo_image.png',
              fit: BoxFit.fill,
            ),
          ),
          150.verticalSpace,
          SizedBox(
            width: 500.w,
            height: 500.h,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 380.w,
                  height: 380.w,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Image.asset('${defaultImagePath}round_gif.gif'),
                  ),
                ),
                Lottie.asset(
                  '${defaultImagePath}round_line.json',
                  controller: _controller,
                  width: 550.w,
                  height: 550.h,
                  fit: BoxFit.contain,
                  onLoaded: (composition) {
                    _controller.duration = composition.duration;
                    _updateProgress();
                  },
                ),
                Text(
                  '${widget.percentage}%',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 50.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          40.verticalSpace,

          Text(
            '${getTranslated(context)!.processing}...',
            style: TextStyle(
              color: Colors.black,
              fontSize: 70.sp,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),

          20.verticalSpace,

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 80.w),
            child: Text(
              subText,
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xff7B7B7B), fontSize: 60.sp),
            ),
          ),
          250.verticalSpace,
          Container(
            height: 170.h,
            padding: EdgeInsets.symmetric(horizontal: 50.w),
            decoration: BoxDecoration(
              color: Color(0xffD8D8D8),
              borderRadius: BorderRadius.circular(150),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    getTranslated(context)!.hide,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Color(0xff7B7B7B), fontSize: 50.sp),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingProgressDialog {
  static bool _isDialogVisible = false;
  static GlobalKey<_LoadingProgressDialogContentState>? _contentKey;

  static void show(
    BuildContext context, {
    required int percentage,
    String? message1,
    String? message2,
  }) {
    if (_isDialogVisible) return;
    _isDialogVisible = true;
    _contentKey = GlobalKey<_LoadingProgressDialogContentState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black,
      builder: (context) {
        showLog('there is data');
        return PopScope(
          canPop: false,
          child: Scaffold(
            backgroundColor: Color(0xfff3f3f3),
            body: Stack(
              children: [
                /*Positioned.fill(
                  child: Image.asset(
                    '${defaultImagePath}loader_full_bg.png',
                    fit: BoxFit.cover,
                  ),
                ),*/
                Center(
                  child: _LoadingProgressDialogContent(
                    key: _contentKey,
                    initialPercentage: percentage,
                    initialMessage1: message1,
                    initialMessage2: message2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void update(
    BuildContext context,
    int percentage, {
    String? message1,
    String? message2,
  }) {
    if (!_isDialogVisible || _contentKey?.currentState == null) {
      if (!_isDialogVisible) {
        show(
          context,
          percentage: percentage,
          message1: message1,
          message2: message2,
        );
      }
      return;
    }

    _contentKey?.currentState?.updateContent(
      percentage: percentage,
      message1: message1,
      message2: message2,
    );
  }

  static void hide(BuildContext context) {
    if (_isDialogVisible) {
      _isDialogVisible = false;
      _contentKey = null;
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

/// StatefulWidget to allow in-place updates without rebuilding dialog
class _LoadingProgressDialogContent extends StatefulWidget {
  final int initialPercentage;
  final String? initialMessage1;
  final String? initialMessage2;

  const _LoadingProgressDialogContent({
    super.key,
    required this.initialPercentage,
    this.initialMessage1,
    this.initialMessage2,
  });

  @override
  State<_LoadingProgressDialogContent> createState() =>
      _LoadingProgressDialogContentState();
}

class _LoadingProgressDialogContentState
    extends State<_LoadingProgressDialogContent> {
  late int _percentage;
  late String? _message1;
  late String? _message2;

  @override
  void initState() {
    super.initState();
    _percentage = widget.initialPercentage;
    _message1 = widget.initialMessage1;
    _message2 = widget.initialMessage2;
  }

  void updateContent({
    required int percentage,
    String? message1,
    String? message2,
  }) {
    setState(() {
      _percentage = percentage;
      _message1 = message1;
      _message2 = message2;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LoadingProgressWidget(
      percentage: _percentage,
      message1: _message1,
      message2: _message2,
    );
  }
}
