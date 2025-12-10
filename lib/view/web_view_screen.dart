import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/consts.dart';
import '../utils/custom_widgets/deep_press_unpress.dart';
import '../utils/firebase_analytics_service.dart';
import 'package:flutter/material.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen(
      {super.key, required this.url, required this.title, required this.log});
  final String url;
  final String title;
  final String log;

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewController webController;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    startTimer();
    WidgetsBinding.instance.addPostFrameCallback((callback) {
      FirebaseAnalyticsService.logEvent(eventName: "${widget.log}_SCREEN");
    });
    webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..enableZoom(true)
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> startTimer() async {
    await Future.delayed(const Duration(seconds: 5));
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Expanded(
                flex: 2,
                child: NewDeepPressUnpress(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Image.asset(
                    height: 100.w,
                    '${defaultImagePath}back.png',
                  ),
                ),
              ),
              Expanded(
                flex: 11,
                child: Center(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 70.sp,
                    ),
                  ),
                ),
              ),
              const Expanded(flex: 2, child: SizedBox(width: 0)),
            ],
          ),
        ),
        body: Stack(
          children: [
            if (isLoading)
              Center(
                  child: Lottie.asset(
                    height: 300.h,
                    '${defaultImagePath}loader.json',
                  )),
            WebViewWidget(controller: webController),
          ],
        ),
      ),
    );
  }
}