import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:ai_dress_up/utils/shared_preference_utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ai_dress_up/utils/global_variables.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ai_dress_up/view/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ai_dress_up/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );


  await SharedPreferenceUtils.init();
  await Firebase.initializeApp().whenComplete(() {});
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void setLocale(BuildContext context, Locale locale) {
    _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    state.setLocale(locale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((callback) async {
      showLog('Local is : ${GlobalVariables.languageCode}');
      GlobalVariables.languageCode =
          await SharedPreferenceUtils.getString("locale") ?? 'en';
      setLocale(Locale(GlobalVariables.languageCode));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1290, 2796),
      child: GetMaterialApp(
        locale: _locale,
        themeMode: ThemeMode.light,
        theme: ThemeData(fontFamily: 'Gabarito'),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SplashScreen(),
      ),
    );
  }
}
