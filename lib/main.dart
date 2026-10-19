import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'config/env/env_config.dart';
import 'config/firebase/firebase_options.dart';
import 'config/router/app_router.dart';
import 'core/constants/colors.dart';
import 'core/constants/dimensions.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'shared/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? bootstrapError;
  try {
    await dotenv.load(fileName: '.env');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (EnvConfig.useFirebaseEmulators) {
      final host = EnvConfig.emulatorHost;
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
      FirebaseFunctions.instanceFor(
        region: EnvConfig.functionsRegion,
      ).useFunctionsEmulator(host, 5001);
    }
    await NotificationService().initialize();
  } catch (error) {
    bootstrapError = error;
  }

  runApp(
    ProviderScope(
      child: bootstrapError == null
          ? const PickDropApp()
          : BootstrapFailureApp(error: bootstrapError),
    ),
  );
}

class PickDropApp extends ConsumerWidget {
  const PickDropApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'PickDrop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      locale: locale,
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final content = MediaQuery(
          data: media.copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child ?? const SizedBox.shrink(),
        );

        if (!kIsWeb || media.size.width <= AppDimensions.phoneFrameWidth) {
          return content;
        }

        final frameWidth = AppDimensions.phoneFrameWidth;
        final frameHeight =
            media.size.height - (AppDimensions.phoneFrameMargin * 2);
        final frameMedia = media.copyWith(
          size: Size(frameWidth, frameHeight),
          padding: EdgeInsets.zero,
          viewPadding: EdgeInsets.zero,
          viewInsets: EdgeInsets.zero,
          systemGestureInsets: EdgeInsets.zero,
          textScaler: const TextScaler.linear(1.0),
        );

        return Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          alignment: Alignment.center,
          child: Container(
            width: frameWidth,
            height: frameHeight,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimensions.radiusXl),
              border: Border.all(color: AppColors.outlineVariant),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withValues(alpha: 0.35),
                  blurRadius: 40,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: MediaQuery(data: frameMedia, child: content),
          ),
        );
      },
    );
  }
}

class BootstrapFailureApp extends StatelessWidget {
  const BootstrapFailureApp({super.key, required this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48),
              const SizedBox(height: 16),
              const Text(
                'PickDrop is not configured',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
        'Copy .env.example to .env, configure a Firebase project, then restart the app.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
