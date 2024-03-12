import 'dart:collection';

import 'package:chatbox_flutter/widgets/SinglePickerWidget.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/chat_box_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:chatbox_flutter/constants.dart';
import 'package:chatbox_flutter/data/chat_box_options.dart';
import 'package:chatbox_flutter/layout/adaptive.dart';
import 'package:chatbox_flutter/pages/about.dart' as about;
import 'package:chatbox_flutter/pages/settings/settings_list_item.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/cupertino.dart';
import 'SettingsOptionsDialog.dart' as settingsOptions;

import '../../widgets/CommWidget.dart';

enum _ExpandableSetting {
  textScale,
  textDirection,
  locale,
  platform,
  theme,
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with TickerProviderStateMixin {
  _ExpandableSetting? _expandedSettingId;
  final List<String> _tabs = [
    'Tab 1',
    'Tab 2',
    'Tab 3',
  ];

  void onTapSetting(_ExpandableSetting settingId) {
    setState(() {
      if (_expandedSettingId == settingId) {
        _expandedSettingId = null;
      } else {
        _expandedSettingId = settingId;
      }
    });
  }

  void _closeSettingId(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      setState(() {
        _expandedSettingId = null;
      });
    }
  }

  final PageController _pageController = PageController();
  late TabController tabController;


  @override
  void initState() {
    super.initState();
    tabController= TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    tabController.dispose();
  }

  /// Given a [Locale], returns a [DisplayOption] with its native name for a
  /// title and its name in the currently selected locale for a subtitle. If the
  /// native name can't be determined, it is omitted. If the locale can't be
  /// determined, the locale code is used.
  DisplayOption _getLocaleDisplayOption(BuildContext context, Locale? locale) {
    final localeCode = locale.toString();
    final localeName = LocaleNames.of(context)!.nameOf(localeCode);
    if (localeName != null) {
      final localeNativeName =
          LocaleNamesLocalizationsDelegate.nativeLocaleNames[localeCode];
      return localeNativeName != null
          ? DisplayOption(localeNativeName, subtitle: localeName)
          : DisplayOption(localeName);
    } else {
      // gsw, fil, and es_419 aren't in flutter_localized_countries' dataset
      // so we handle them separately
      switch (localeCode) {
        case 'gsw':
          return DisplayOption('Schwiizertüütsch', subtitle: 'Swiss German');
        case 'fil':
          return DisplayOption('Filipino', subtitle: 'Filipino');
        case 'es_419':
          return DisplayOption(
            'español (Latinoamérica)',
            subtitle: 'Spanish (Latin America)',
          );
      }
    }

    return DisplayOption(localeCode);
  }

  /// Create a sorted — by native name – map of supported locales to their
  /// intended display string, with a system option as the first element.
  LinkedHashMap<Locale, DisplayOption> _getLocaleOptions() {
    var localeOptions = LinkedHashMap.of({
      systemLocaleOption: DisplayOption(
        ChatBoxLocalizations.of(context)!.settingsSystemDefault +
            (deviceLocale != null
                ? ' - ${_getLocaleDisplayOption(context, deviceLocale).title}'
                : ''),
      ),
    });
    var supportedLocales =
        List<Locale>.from(ChatBoxLocalizations.supportedLocales);
    supportedLocales.removeWhere((locale) => locale == deviceLocale);

    final displayLocales = Map<Locale, DisplayOption>.fromIterable(
      supportedLocales,
      value: (dynamic locale) =>
          _getLocaleDisplayOption(context, locale as Locale?),
    ).entries.toList()
      ..sort((l1, l2) => compareAsciiUpperCase(l1.value.title, l2.value.title));

    localeOptions.addAll(LinkedHashMap.fromEntries(displayLocales));
    return localeOptions;
  }

  void showSettingsOptionsDialog<K, V>(
      LinkedHashMap<K, V> optionsMap, var selectOptions, Function onChanged) {
    // if (isDisplayDesktop(context)) {
    settingsOptions.showSettingsOptionsDialog(
      context: context,
      optionsMap: optionsMap,
      selectOptions: selectOptions,
      onChanged: onChanged,
    );
    // } else {
    //   showBottomSheetDialog(optionsMap, selectOptions, onChanged);
    // }
  }

  void showBottomSheetDialog<K, V>(
      LinkedHashMap<K, V> optionsMap, var selectOptions, Function onChanged) {
    final local = ChatBoxLocalizations.of(context)!;
    var selItem;
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadiusDirectional.only(
                topStart: Radius.circular(16), topEnd: Radius.circular(16))),
        builder: (builder) {
          return SafeArea(
              child: Column(children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CommWidget.buttonWidget(
                    title: local.dialogCancel,
                    textStyle: const TextStyle(color: Colors.black),
                    callback: () {
                      Navigator.of(context).pop();
                    }),
                Expanded(child: Container()),
                CommWidget.buttonWidget(
                    title: local.sure,
                    textStyle: const TextStyle(color: Colors.black),
                    callback: () {
                      onChanged(selItem);
                      Navigator.of(context).pop();
                    })
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SinglePickerWidget(
                    optionsMap: optionsMap,
                    onChanged: (item) {
                      selItem = item;
                    },
                    value: selectOptions)
              ],
            )
          ]));
        });
  }

  @override
  Widget build(BuildContext context) {
    final themes = Theme.of(context);
    final colorScheme = themes.colorScheme;
    final appbarTheme = themes.appBarTheme;
    final options = ChatBoxOptions.of(context);
    final isDesktop = isDisplayDesktop(context);
    final localizations = ChatBoxLocalizations.of(context)!;
    final textScalingData = LinkedHashMap.of({
      systemTextScaleFactorOption: DisplayOption(
        localizations.settingsSystemDefault,
      ),
      0.8: DisplayOption(
        localizations.settingsTextScalingSmall,
      ),
      1.0: DisplayOption(
        localizations.settingsTextScalingNormal,
      ),
      2.0: DisplayOption(
        localizations.settingsTextScalingLarge,
      ),
      3.0: DisplayOption(
        localizations.settingsTextScalingHuge,
      ),
    });
    final textDirectionData = LinkedHashMap.of({
      CustomTextDirection.localeBased: DisplayOption(
        localizations.settingsTextDirectionLocaleBased,
      ),
      CustomTextDirection.ltr: DisplayOption(
        localizations.settingsTextDirectionLTR,
      ),
      CustomTextDirection.rtl: DisplayOption(
        localizations.settingsTextDirectionRTL,
      ),
    });
    final platformData = LinkedHashMap.of({
      TargetPlatform.android: DisplayOption('Android'),
      TargetPlatform.iOS: DisplayOption('iOS'),
      TargetPlatform.macOS: DisplayOption('macOS'),
      TargetPlatform.linux: DisplayOption('Linux'),
      TargetPlatform.windows: DisplayOption('Windows'),
    });
    final themesData = LinkedHashMap.of({
      ThemeMode.system: DisplayOption(
        localizations.settingsSystemDefault,
      ),
      ThemeMode.dark: DisplayOption(
        localizations.settingsDarkTheme,
      ),
      ThemeMode.light: DisplayOption(
        localizations.settingsLightTheme,
      ),
    });
    return Scaffold(
        appBar: AppBar(
          title: Text(localizations.settingsTitle,
              style: themes.appBarTheme.titleTextStyle),
          iconTheme: themes.appBarTheme.iconTheme,
          actionsIconTheme: themes.appBarTheme.actionsIconTheme,
          titleTextStyle: themes.appBarTheme.titleTextStyle,
          bottom: TabBar(
            // controller: DefaultTabController.maybeOf(context),
            tabs: _tabs.map((String tab) {
              return Tab(text: tab);
            }).toList(),
            onTap: (index) {
              _pageController.jumpToPage(index);
            },
          ),
        ),
        body: PageView.builder(
          controller: _pageController,
          itemCount: _tabs.length,
          itemBuilder: (context, index) {
            return Center(
              child: Text(
                _tabs[index],
                style: TextStyle(fontSize: 24.0),
              ),
            );
          },
          onPageChanged: (index) {
            tabController.animateTo(index);
          },
        )

        // Material(
        //   color: colorScheme.background,
        //   child: Padding(
        //     padding: isDesktop
        //         ? EdgeInsets.zero
        //         : const EdgeInsets.only(
        //             bottom: galleryHeaderHeight,
        //           ),
        // child: ListView(
        //   children: [
        //     const SizedBox(height: 12),
        //     SettingsListItem(
        //       optionsMap: textScalingData,
        //       title: localizations.settingsTextScaling,
        //       selectedOption: options.textScaleFactor(
        //         context,
        //         useSentinel: true,
        //       ),
        //       onTapSetting: () {
        //         showSettingsOptionsDialog(
        //             textScalingData,
        //             options.textScaleFactor(
        //               context,
        //               useSentinel: true,
        //             ), (newTextScale) {
        //           ChatBoxOptions.update(
        //             context,
        //             options.copyWith(textScaleFactor: newTextScale),
        //           );
        //         });
        //       },
        //       isExpanded: false,
        //     ),
        //     const SizedBox(height: 12),
        //     SettingsListItem(
        //       optionsMap: textDirectionData,
        //       title: localizations.settingsTextDirection,
        //       selectedOption: options.customTextDirection,
        //       onTapSetting: () {
        //         showSettingsOptionsDialog(
        //             textDirectionData, options.customTextDirection,
        //             (newTextDirection) {
        //           ChatBoxOptions.update(
        //             context,
        //             options.copyWith(customTextDirection: newTextDirection),
        //           );
        //         });
        //       },
        //       isExpanded: false,
        //     ),
        //     const SizedBox(height: 12),
        //     SettingsListItem(
        //       optionsMap: _getLocaleOptions(),
        //       title: localizations.settingsLocale,
        //       selectedOption: options.locale == deviceLocale
        //           ? systemLocaleOption
        //           : options.locale,
        //       onTapSetting: () {
        //         showSettingsOptionsDialog(
        //             _getLocaleOptions(),
        //             options.locale == deviceLocale
        //                 ? systemLocaleOption
        //                 : options.locale, (newLocale) {
        //           if (newLocale == systemLocaleOption) {
        //             newLocale = deviceLocale;
        //           }
        //           ChatBoxOptions.update(
        //             context,
        //             options.copyWith(locale: newLocale),
        //           );
        //         });
        //       },
        //       isExpanded: false,
        //     ),
        //     const SizedBox(height: 12),
        //     SettingsListItem(
        //       optionsMap: platformData,
        //       title: localizations.settingsPlatformMechanics,
        //       selectedOption: options.platform,
        //       onTapSetting: () {
        //         showSettingsOptionsDialog(platformData, options.platform,
        //             (newPlatform) {
        //           ChatBoxOptions.update(
        //             context,
        //             options.copyWith(platform: newPlatform),
        //           );
        //         });
        //       },
        //       isExpanded: false,
        //     ),
        //     const SizedBox(height: 12),
        //     SettingsListItem(
        //       optionsMap: themesData,
        //       title: localizations.settingsTheme,
        //       selectedOption: options.themeMode,
        //       onTapSetting: () {
        //         showSettingsOptionsDialog(themesData, options.themeMode,
        //             (newThemeMode) {
        //           ChatBoxOptions.update(
        //             context,
        //             options.copyWith(themeMode: newThemeMode),
        //           );
        //         });
        //       },
        //       isExpanded: false,
        //     ),
        //     const SizedBox(height: 12),
        //     ToggleSetting(
        //       text: ChatBoxLocalizations.of(context)!.settingsSlowMotion,
        //       value: options.timeDilation != 1.0,
        //       onChanged: (isOn) => ChatBoxOptions.update(
        //         context,
        //         options.copyWith(timeDilation: isOn ? 5.0 : 1.0),
        //       ),
        //     )
        //   ],
        // ),
        // ),
        // ),
        );
  }
}

class Header extends StatelessWidget {
  const Header({super.key, required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: EdgeInsets.only(
          top: isDisplayDesktop(context) ? 63 : 15,
          bottom: isDisplayDesktop(context) ? 21 : 11,
        ),
        child: SelectableText(
          text,
          style: Theme.of(context).textTheme.headlineMedium!.apply(
                color: color,
                fontSizeDelta:
                    isDisplayDesktop(context) ? desktopDisplay1FontDelta : 0,
              ),
        ),
      ),
    );
  }
}

class SettingsAbout extends StatelessWidget {
  const SettingsAbout({super.key});

  @override
  Widget build(BuildContext context) {
    return _SettingsLink(
      title: ChatBoxLocalizations.of(context)!.settingsAbout,
      icon: Icons.info_outline,
      onTap: () {
        about.showAboutDialog(context: context);
      },
    );
  }
}

class SettingsFeedback extends StatelessWidget {
  const SettingsFeedback({super.key});

  @override
  Widget build(BuildContext context) {
    return _SettingsLink(
      title: ChatBoxLocalizations.of(context)!.settingsFeedback,
      icon: Icons.feedback,
      onTap: () async {
        final url =
            Uri.parse('https://github.com/flutter/gallery/issues/new/choose/');
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        }
      },
    );
  }
}

class SettingsAttribution extends StatelessWidget {
  const SettingsAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = isDisplayDesktop(context);
    final verticalPadding = isDesktop ? 0.0 : 28.0;
    return MergeSemantics(
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: isDesktop ? 24 : 32,
          end: isDesktop ? 0 : 32,
          top: verticalPadding,
          bottom: verticalPadding,
        ),
        child: SelectableText(
          ChatBoxLocalizations.of(context)!.settingsAttribution,
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
          textAlign: isDesktop ? TextAlign.end : TextAlign.start,
        ),
      ),
    );
  }
}

class _SettingsLink extends StatelessWidget {
  final String title;
  final IconData? icon;
  final GestureTapCallback? onTap;

  const _SettingsLink({
    required this.title,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = isDisplayDesktop(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : 32,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: colorScheme.onSecondary.withOpacity(0.5),
              size: 24,
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: 16,
                  top: 12,
                  bottom: 12,
                ),
                child: Text(
                  title,
                  style: textTheme.titleSmall!.apply(
                    color: colorScheme.onSecondary,
                  ),
                  textAlign: isDesktop ? TextAlign.end : TextAlign.start,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsListItem<T> extends StatefulWidget {
  const SettingsListItem({
    super.key,
    required this.optionsMap,
    required this.title,
    required this.selectedOption,
    required this.onTapSetting,
    required this.isExpanded,
  });

  final LinkedHashMap<T, DisplayOption> optionsMap;
  final String title;
  final T selectedOption;
  final bool isExpanded;
  final Function onTapSetting;

  @override
  State<SettingsListItem<T?>> createState() => _SettingsListItemState<T?>();
}

class _SettingsListItemState<T> extends State<SettingsListItem<T?>>
    with SingleTickerProviderStateMixin {
  static const _expandDuration = Duration(milliseconds: 150);

  // For ease of use. Correspond to the keys and values of `widget.optionsMap`.
  late Iterable<T?> _options;
  late Iterable<DisplayOption> _displayOptions;
  late AnimationController _controller;
  late Animation<double> _headerChevronRotation;

  @override
  void initState() {
    super.initState();
    _options = widget.optionsMap.keys;
    _displayOptions = widget.optionsMap.values;
    _controller = AnimationController(duration: _expandDuration, vsync: this);
    _headerChevronRotation =
        Tween<double>(begin: 0, end: 0.5).animate(_controller);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SettingItem(
      margin: settingItemHeaderMargin,
      padding: const EdgeInsets.all(16),
      borderRadius: settingItemBorderRadius,
      chevronRotation: _headerChevronRotation,
      title: widget.title,
      subtitle: widget.optionsMap[widget.selectedOption]?.title ?? '',
      onTap: () => widget.onTapSetting(),
    );
  }
}

class SettingItem extends StatelessWidget {
  const SettingItem({
    this.margin,
    required this.padding,
    required this.borderRadius,
    required this.chevronRotation,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final String title;
  final String subtitle;
  final Animation<double> chevronRotation;
  final GestureTapCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
        container: true,
        child: Container(
          margin: margin,
          child: Material(
            shape: RoundedRectangleBorder(borderRadius: borderRadius),
            color: colorScheme.secondary,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: padding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: textTheme.titleMedium!.apply(
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall!.apply(
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: 8,
                      end: 24,
                    ),
                    child: RotationTransition(
                      turns: chevronRotation,
                      child: const Icon(Icons.arrow_drop_down),
                    ),
                  )
                ],
              ),
            ),
          ),
        ));
  }
}
