import 'package:ride_on/app/app_localizations.dart';
import 'package:ride_on/app/register_cubits.dart';
import 'package:ride_on/presentation/cubits/localizations_cubit.dart';
import 'package:ride_on/presentation/screens/Splash/initial_screen.dart';
import 'package:ride_on/core/extensions/workspace.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:location/location.dart';
import 'package:provider/provider.dart';
import 'core/extensions/helper/push_notifications.dart';
import 'core/services/ride_audio_recorder_service.dart';
import 'core/utils/theme/project_color.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Hive.initFlutter();
  await Hive.openBox('appBox');
  await Hive.openBox('lanBox');
  await initializeNotifications();
  await setupPushNotifications();
  await _ensureLocationServiceEnabledOnStart();
  await RideAudioRecorderService.instance.requestMicrophonePermissionOnStart();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  FlutterError.onError = (FlutterErrorDetails details) {};
  runApp(
    MultiBlocProvider(
      providers: [
        ...RegisterCubits().providers,
        ChangeNotifierProvider(create: (_) => ColorNotifires()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          context.read<LanguageCubit>().loadCurrentLanguage();
          return BlocBuilder<LanguageCubit, LanguageState>(
            builder: (context, state) {
              if (state is LanguageLoader) {
                appLocale = Locale(state.language ?? "en");
              }
              return MaterialApp(
                navigatorKey: navigatorKey,
                builder: BotToastInit(),
                theme: ThemeData(
                  fontFamily: 'Gilroy Regular',
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: themeColor,
                    primary: themeColor,
                    secondary: themeColor2,
                  ),
                  appBarTheme: const AppBarTheme(
                    foregroundColor: Colors.white,
                    iconTheme: IconThemeData(color: Colors.white),
                    titleTextStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Gilroy Regular',
                    ),
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      iconColor: Colors.white,
                    ),
                  ),
                  filledButtonTheme: FilledButtonThemeData(
                    style: FilledButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                supportedLocales: const [
                  Locale('en', 'US'),
                  Locale('ar', 'AR'),
                ],
                locale: appLocale,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                debugShowCheckedModeBanner: false,
                home: const InitialScreen(),
              );
            },
          );
        },
      ),
    ),
  );
}

Future<void> _ensureLocationServiceEnabledOnStart() async {
  try {
    final location = Location();
    final isServiceEnabled = await location.serviceEnabled();
    if (!isServiceEnabled) {
      await location.requestService();
    }
  } catch (_) {}
}
