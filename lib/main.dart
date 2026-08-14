import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import "firebase_options.dart";
import "config/app_config.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import 'config/app_routes.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _configurePhotoPicker();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

/// Points Android's image picking at the system photo picker.
///
/// Without this the plugin falls back to `ACTION_GET_CONTENT`, which opens the
/// file browser — a document list the user has to back out of rather than a
/// gallery they can cancel. The flag lives on the platform implementation, so
/// setting it once here covers every picker in the app. Other platforms leave
/// the instance untouched.
void _configurePhotoPicker() {
  final picker = ImagePickerPlatform.instance;
  if (picker is ImagePickerAndroid) {
    picker.useAndroidPhotoPicker = true;
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: ref.watch(routerProvider),
      title: "WeGather",
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
      onGenerateTitle: (context) => AppLocalizations.of(context)!.title,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        scaffoldBackgroundColor: Colors.transparent,
      ),
      builder: (context, child) {
        return Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppConfig.appBackgroundGradient,
                ),
              ),
            ),
            child!,
          ],
        );
      },
      // Remove the home: property - Go Router handles this now
    );
  }
}
