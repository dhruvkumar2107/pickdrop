import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  await dotenv.load(fileName: '.env');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    debugPrint('Firebase initialization skipped or failed in local demo mode.');
  }

  if (EnvConfig.isFirebaseConfigured) {
    try {
      await NotificationService().initialize();
    } catch (_) {
      debugPrint('Notification initialization skipped in local demo mode.');
    }
  }

  runApp(const ProviderScope(child: PickDropApp()));
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
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('kn'),
      ],
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
            child: MediaQuery(
              data: frameMedia,
              child: content,
            ),
          ),
        );
      },
    );
  }
}