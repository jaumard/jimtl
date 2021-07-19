import 'package:flutter/widgets.dart';
import 'package:flutter_jimtl/flutter_jimtl.dart';
import 'package:jimtl/jimtl.dart';
import 'package:intl/src/locale/locale_parser.dart';

/// use to update ARB data for give [locale] and [flavor]
/// It returns some content to save in memory
typedef FlutterIntlDataLoader = Future<String> Function(Locale locale, String flavor);

/// use to update ARB data for give [locale] and [flavor]
/// If it returns null, it mean no update is available
/// If it returns some content, it will update accordingly
typedef FlutterIntlUpdateDataLoader = Future<String?> Function(Locale locale, String flavor);

Locale _parseLocale(String locale) {
  final parser = LocaleParser(locale);
  final newLocale = parser.toLocale()!;
  return Locale.fromSubtags(languageCode: newLocale.languageCode, countryCode: newLocale.countryCode, scriptCode: newLocale.scriptCode);
}

class TranslationsDelegate<T> extends LocalizationsDelegate<T> {
  final String currentFlavor;
  final Locale? overrideCurrentLocale;
  final IntlDelegate _delegate;
  final List<Locale> supportedLocales;
  final T Function() translationsBuilder;
  final VoidCallback? onTranslationsUpdated;

  TranslationsDelegate({
    required Locale defaultLocale,
    this.currentFlavor = IntlDelegate.defaultFlavorName,
    this.overrideCurrentLocale,
    String defaultFlavor = IntlDelegate.defaultFlavorName,
    required FlutterIntlDataLoader dataLoader,
    FlutterIntlUpdateDataLoader? updateDataLoader,
    required this.translationsBuilder,
    this.onTranslationsUpdated,
    //List<String> supportedFlavors = const [],
    this.supportedLocales = const [],
  }) : _delegate = IntlDelegate(
          defaultLocale: defaultLocale.toString(),
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

  @override
  bool isSupported(Locale locale) {
    return supportedLocales.contains(locale);
  }

  void _askForUpdate() async {
    if (await _delegate.askForUpdate()) {
      onTranslationsUpdated?.call();
    }
  }

  @override
  Future<T> load(Locale locale) async {
    await _delegate.load(overrideCurrentLocale?.toString() ?? locale.toString(), currentFlavor: currentFlavor);
    _askForUpdate();
    return translationsBuilder();
  }

  @override
  bool shouldReload(covariant TranslationsDelegate<T> old) {
    return old.currentFlavor != currentFlavor;
  }
}
