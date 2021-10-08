import 'package:flutter/widgets.dart';
import 'package:flutter_jimtl/flutter_jimtl.dart';
import 'package:intl/src/locale/locale_parser.dart';
import 'package:jimtl/jimtl.dart';

/// use to update ARB data for give [locale] and [flavor]
/// It returns some content to save in memory
typedef FlutterIntlDataLoader = Future<String> Function(
    Locale locale, String flavor);

/// use to update ARB data for give [locale] and [flavor]
/// If it returns null, it mean no update is available
/// If it returns some content, it will update accordingly
typedef FlutterIntlUpdateDataLoader = Future<String?> Function(
    Locale locale, String flavor);

Locale _parseLocale(String locale) {
  final parser = LocaleParser(locale);
  final newLocale = parser.toLocale()!;
  return Locale.fromSubtags(
      languageCode: newLocale.languageCode,
      countryCode: newLocale.countryCode,
      scriptCode: newLocale.scriptCode);
}

/// LocalizationsDelegate that allow you to load ARB files on the fly
class TranslationsDelegate<T> extends LocalizationsDelegate<T> {
  /// Current flavor of your app
  final String currentFlavor;

  /// Locale to use instead of the one given by the system
  final Locale? overrideCurrentLocale;

  /// Supported locales of your app
  final List<Locale> supportedLocales;

  /// Callback to create your Localization file, it will be called when needed by Flutter
  final T Function() translationsBuilder;

  /// Callback to create your Localization file, it will be called when needed by Flutter
  final void Function(dynamic err, dynamic stack)? onError;

  /// Callback that will be called when translations are updated, it means you need to rebuild your app in order to see those
  final VoidCallback? onTranslationsUpdated;
  final IntlDelegate _delegate;

  /// Construct an object that will manage the localized strings of your app
  /// You're in change of instantiate your localization class file with [translationsBuilder]
  TranslationsDelegate({
    required Locale defaultLocale,
    this.currentFlavor = IntlDelegate.defaultFlavorName,
    this.overrideCurrentLocale,
    this.onError,
    String defaultFlavor = IntlDelegate.defaultFlavorName,
    required FlutterIntlDataLoader dataLoader,
    FlutterIntlUpdateDataLoader? updateDataLoader,
    required this.translationsBuilder,
    this.onTranslationsUpdated,
    //List<String> supportedFlavors = const [],
    this.supportedLocales = const [],
  }) : _delegate = IntlDelegate(
          defaultLocale: defaultLocale.toString(),
          onError: onError,
          dataLoader: (locale, flavor) {
            return dataLoader(_parseLocale(locale), flavor);
          },
          updateDataLoader: (locale, flavor) {
            if (updateDataLoader == null) {
              return Future.value(null);
            }
            return updateDataLoader(_parseLocale(locale), flavor);
          },
          defaultFlavor: defaultFlavor,
          //supportedFlavors: supportedFlavors,
        );

  TranslationsDelegate.withRemoteManager({
    required Locale defaultLocale,
    this.currentFlavor = IntlDelegate.defaultFlavorName,
    this.overrideCurrentLocale,
    String defaultFlavor = IntlDelegate.defaultFlavorName,
    required FlutterIntlDataLoader dataLoader,
    required RemoteTranslationsManager localizationManager,
    required this.translationsBuilder,
    this.onError,
    this.onTranslationsUpdated,
    //List<String> supportedFlavors = const [],
    this.supportedLocales = const [],
  }) : _delegate = IntlDelegate.withRemoteManager(
          defaultLocale: defaultLocale.toString(),
          onError: onError,
          dataLoader: (locale, flavor) {
            return dataLoader(_parseLocale(locale), flavor);
          },
          localizationManager: localizationManager,
          defaultFlavor: defaultFlavor,
          //supportedFlavors: supportedFlavors,
        );

  @override
  bool isSupported(Locale locale) {
    return supportedLocales.contains(locale);
  }

  String? get(String id, {String? locale, List<Object>? args, String fallback = ''}) {
    return _delegate.get(id, locale: locale, args: args, fallback: fallback);
  }

  void _askForUpdate() async {
    try {
      if (await _delegate.askForUpdate()) {
        onTranslationsUpdated?.call();
      }
    } catch (e, stack) {
      this.onError?.call(e, stack);
    }
  }

  @override
  Future<T> load(Locale locale) async {
    await _delegate.load(overrideCurrentLocale?.toString() ?? locale.toString(),
        currentFlavor: currentFlavor);
    _askForUpdate();
    return translationsBuilder();
  }

  @override
  bool shouldReload(covariant TranslationsDelegate<T> old) {
    return old.currentFlavor != currentFlavor;
  }
}
