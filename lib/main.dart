import 'package:chatbox_flutter/pages/home.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
import 'package:chatbox_flutter/data/chat_box_options.dart';
import 'package:flutter/material.dart';
import 'package:chatbox_flutter/constants.dart';
import 'package:flutter/foundation.dart';
import 'package:chatbox_flutter/themes/chat_box_theme_data.dart';
import 'package:flutter_gen/gen_l10n/chat_box_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:chatbox_flutter/routes.dart';
import 'package:dual_screen/dual_screen.dart';
void main() {
  runApp(const ChatBoxApp());
}

class ChatBoxApp extends StatelessWidget {
  const ChatBoxApp({
    super.key,
    this.initialRoute,
    this.isTestMode = false,});

  final String? initialRoute;
  final bool isTestMode;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ModelBinding(
        initialModel: ChatBoxOptions(
          themeMode: ThemeMode.dark,
          textScaleFactor: systemTextScaleFactorOption,
          customTextDirection: CustomTextDirection.localeBased,
          locale: null,
          timeDilation: timeDilation,
          platform: defaultTargetPlatform,
          isTestMode: isTestMode,

        ),
        child: Builder(
            builder:(context){
              final options = ChatBoxOptions.of(context);
              final hasHinge = MediaQuery.of(context).hinge?.bounds != null;
              return MaterialApp(
                restorationScopeId: 'rootChatBox',
                title: "ChatBox",
                debugShowCheckedModeBanner: false,
                themeMode: options.themeMode,
                theme: ChatBoxThemeData.lightThemeData.copyWith(
                  platform: options.platform,
                ),
                darkTheme: ChatBoxThemeData.darkThemeData.copyWith(
                  platform: options.platform,
                ),
                localizationsDelegates: const [
                  ...ChatBoxLocalizations.localizationsDelegates,
                  LocaleNamesLocalizationsDelegate()
                ],
                initialRoute: initialRoute,
                supportedLocales: ChatBoxLocalizations.supportedLocales,
                locale: options.locale,
                localeListResolutionCallback: (locales, supportedLocales) {
                  deviceLocale = locales?.first;
                  return basicLocaleListResolution(locales, supportedLocales);
                },
                onGenerateRoute: (settings) =>
                    RouteConfiguration.onGenerateRoute(settings, hasHinge),
              );
            }
        ));
  }
}
// class RootPage extends StatelessWidget {
//   const RootPage({
//     super.key,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return ApplyTextOptions(
//       child: SplashPage(
//         child: Backdrop(
//           isDesktop: false,
//         ),
//       ),
//     );
//   }
// }