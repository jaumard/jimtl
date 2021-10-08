import 'dart:convert';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';
import 'package:intl/src/intl_helpers.dart';
import 'package:intl_generator/generate_localized.dart';

final Map<String, List<String>> metaData = {};
// Flavor => Locale => sentences {flavor: {en: {test: message}}}
final Map<String, Map<String, Map<String, Message>>> _messages = {};

String _getString(
    String locale, String id, Message message, List<Object> args) {
  if (message is LiteralString) {
    return message.string;
  } else if (message is CompositeMessage) {
    final s = StringBuffer();
    message.pieces.forEach((element) {
      s.write(_getString(locale, id, element, args));
    });
    return s.toString();
  }
  if (message is VariableSubstitution) {
    final index = metaData[id]!.indexWhere(
        (key) => key.toLowerCase() == message.variableName.toLowerCase());
    if (index == -1 && args.length > 1) {
      throw StateError(
          'No meta data "placeholders_order" found for $id, be sure you generate your ARB with intl_generator or intl_flavors');
    }
    return index == -1 ? args.first.toString() : args[index].toString();
  } else if (message is Gender) {
    final index = metaData[id]!.indexWhere(
        (key) => key.toLowerCase() == message.mainArgument!.toLowerCase());
    return Intl.genderLogic(
      args[index].toString(),
      locale: locale,
      other: _getString(locale, id, message.other!, args),
      male: _getString(locale, id, message.male ?? message.other!, args),
      female: _getString(locale, id, message.female ?? message.other!, args),
    );
  } else if (message is Plural) {
    final index = metaData[id]!.indexWhere(
        (key) => key.toLowerCase() == message.mainArgument!.toLowerCase());
    return Intl.pluralLogic(
      args[index] as num,
      locale: locale,
      other: _getString(locale, id, message.other!, args),
      few: _getString(locale, id, message.few ?? message.other!, args),
      many: _getString(locale, id, message.many ?? message.other!, args),
      one: _getString(locale, id, message.one ?? message.other!, args),
      two: _getString(locale, id, message.two ?? message.other!, args),
      zero: _getString(locale, id, message.zero ?? message.other!, args),
    );
  } else {
    print('Unsupported type ${message.runtimeType}');
  }
  return '';
}

class CustomLookup extends MessageLookupByLibrary {
  final String localeName;
  final String flavorName;
  final String defaultLocaleName;
  final String defaultFlavorName;

  CustomLookup({
    required this.localeName,
    required this.flavorName,
    required this.defaultFlavorName,
    required this.defaultLocaleName,
  });

  @override
  Map<String, dynamic> get messages => throw UnimplementedError();

  @override
  String? lookupMessage(String? messageText, String? locale, String? name,
      List<Object>? args, String? meaning,
      {MessageIfAbsent? ifAbsent}) {
    // If passed null, use the default.
    final knownLocale = locale ?? localeName;

    final messages = _messages[flavorName]![knownLocale]!;
    final sentence = messages[name!];

    // sentence is not available in current locale, let's take the default one
    if (sentence == null) {
      final defaultMessages = _messages[defaultFlavorName]![knownLocale]!;
      final defaultSentence = defaultMessages[name];
      if (defaultSentence == null) {
        final defaultMessages =
            _messages[defaultFlavorName]![defaultLocaleName]!;
        final defaultSentence = defaultMessages[name];
        if (defaultSentence == null) {
          print('no message found for $name, default to $messageText');
          return messageText;
        }
        return _getString(
            knownLocale, name.toLowerCase(), defaultSentence, args ?? []);
      }
      return _getString(
          knownLocale, name.toLowerCase(), defaultSentence, args ?? []);
    }
    return _getString(knownLocale, name.toLowerCase(), sentence, args ?? []);
  }
}

abstract class RemoteTranslationsManager {
  /// Method called to download translations from a remote service for the given
  /// [locale] and [flavor].
  /// Return null if no updates are available or the ARB content if there is something to update
  Future<String?> download(String locale, String flavor);
}

/// use to update ARB data for give [locale] and [flavor]
/// It returns some content to save in memory
typedef IntlDataLoader = Future<String> Function(String locale, String flavor);

/// use to update ARB data for give [locale] and [flavor]
/// If it returns null, it mean no update is available
/// If it returns some content, it will update accordingly
typedef IntlUpdateDataLoader = Future<String?> Function(
    String locale, String flavor);

/// This is a message lookup mechanism that delegates to one of a collection
/// of individual [MessageLookupByLibrary] instances.
class CustomCompositeMessageLookup implements MessageLookup {
  final bool cacheLocale;

  /// A map from locale names to the corresponding lookups.
  final Map<String, MessageLookupByLibrary> availableMessages = Map();

  CustomCompositeMessageLookup({this.cacheLocale = true});

  /// Return true if we have a message lookup for [localeName].
  bool localeExists(localeName) => availableMessages.containsKey(localeName);

  /// The last locale in which we looked up messages.
  ///
  ///  If this locale matches the new one then we can skip looking up the
  ///  messages and assume they will be the same as last time.
  String? _lastLocale;

  /// Caches the last messages that we found
  MessageLookupByLibrary? _lastLookup;

  /// Look up the message with the given [name] and [locale] and return the
  /// translated version with the values in [args] interpolated.  If nothing is
  /// found, return the result of [ifAbsent] or [messageText].
  String? lookupMessage(String? messageText, String? locale, String? name,
      List<Object>? args, String? meaning,
      {MessageIfAbsent? ifAbsent}) {
    // If passed null, use the default.
    var knownLocale = locale ?? Intl.getCurrentLocale();
    var messages = (knownLocale == _lastLocale)
        ? _lastLookup
        : _lookupMessageCatalog(knownLocale);
    // If we didn't find any messages for this locale, use the original string,
    // faking interpolations if necessary.
    if (messages == null) {
      return ifAbsent == null ? messageText : ifAbsent(messageText, args);
    }
    return messages.lookupMessage(messageText, locale, name, args, meaning,
        ifAbsent: ifAbsent);
  }

  /// Find the right message lookup for [locale].
  MessageLookupByLibrary? _lookupMessageCatalog(String locale) {
    var verifiedLocale = Intl.verifiedLocale(locale, localeExists,
        onFailure: (locale) => locale);
    _lastLocale = locale;
    _lastLookup = availableMessages[verifiedLocale];
    return _lastLookup;
  }

  /// If we do not already have a locale for [localeName] then
  /// [findLocale] will be called and the result stored as the lookup
  /// mechanism for that locale.
  void addLocale(String localeName, Function findLocale) {
    if (localeExists(localeName) && cacheLocale) return;
    var canonical = Intl.canonicalizedLocale(localeName);
    var newLocale = findLocale(canonical);
    if (newLocale != null) {
      availableMessages[localeName] = newLocale;
      availableMessages[canonical] = newLocale;
      // If there was already a failed lookup for [newLocale], null the cache.
      if (_lastLocale == newLocale) {
        _lastLocale = null;
        _lastLookup = null;
      }
    }
  }
}

/// Delegate to manage locales and flavors
class IntlDelegate {
  static const defaultFlavorName = 'default';

  // Default locale of your app, this will be use to fallback to this locale
  final String defaultLocale;

  // Default flavor of your app, this will be use to fallback to this flavor
  final String defaultFlavor;

  // Callback to load the ARB data depending on a locale and flavor
  final IntlDataLoader dataLoader;

  // Callback to remote load the ARB data depending on a locale and flavor
  final IntlUpdateDataLoader? updateDataLoader;

  /// Callback to create your Localization file, it will be called when needed by Flutter
  final void Function(dynamic err, dynamic stack)? onError;

  //final List<String> supportedFlavors;
  String _currentFlavor = defaultFlavorName;

  /// Construct a delegate to manage locales and flavors with a remote manager
  /// That will allow to use external manager to manage OTA cache and download of ARB files.
  /// See jimtl_localazy as example
  IntlDelegate.withRemoteManager({
    required this.dataLoader,
    required this.defaultLocale,
    required RemoteTranslationsManager localizationManager,
    this.defaultFlavor = defaultFlavorName,
    this.onError,
    //this.supportedFlavors = const [],
  }) : updateDataLoader = ((String locale, String flavor) async {
          try {
            return localizationManager.download(locale, flavor);
          } catch (ex, stack) {
            print(ex);
            print(stack);
            return null;
          }
        }) {
    initializeInternalMessageLookup(() => CustomCompositeMessageLookup());
  }

  /// Construct an object that deal with locales and flavors in order to give you the correct translations
  /// depending on the loaded locales, the current locale and flavor.
  IntlDelegate({
    required this.dataLoader,
    required this.defaultLocale,
    this.updateDataLoader,
    this.defaultFlavor = defaultFlavorName,
    bool cacheLocale = true,
    this.onError,
    //this.supportedFlavors = const [],
  }) {
    initializeInternalMessageLookup(
        () => CustomCompositeMessageLookup(cacheLocale: cacheLocale));
  }

  /// Get translated sentence by id/name
  /// Returns translated sentence or null if not found
  String? get(String id,
      {String? locale, List<Object>? args, String fallback = ''}) {
    return Intl.message(fallback, name: id, locale: locale, args: args);
  }

  /// this method will trigger [updateDataLoader] for the needed locales and flavors
  /// You can use this method to trigger remote download of ARBs files for example
  /// Returns true if translations have been updated, false otherwise
  Future<bool> askForUpdate() async {
    var updated = false;
    if (updateDataLoader != null) {
      final currentLocale = Intl.defaultLocale!;
      final data = await updateDataLoader!(defaultLocale, defaultFlavor);
      if (data != null) {
        try {
          _parseMetaData(data);
          updated = true;
        } catch (e, stack) {
          onError?.call(e, stack);
        }
      }
      if (currentLocale != defaultLocale) {
        final data = await updateDataLoader!(currentLocale, defaultFlavor);
        if (data != null) {
          try {
            _loadLocale(currentLocale, data);
            updated = true;
          } catch (e, stack) {
            onError?.call(e, stack);
          }
        }
      }
      if (_currentFlavor != defaultFlavor) {
        final data = await updateDataLoader!(currentLocale, _currentFlavor);
        if (data != null) {
          try {
            _loadLocale(currentLocale, data, flavor: _currentFlavor);
            updated = true;
          } catch (e, stack) {
            onError?.call(e, stack);
          }
        }
      }
    }
    return updated;
  }

  /// Init Intl with the [currentLocale] and [currentFlavor],
  /// it will call [dataLoader] to load the locale data needed to do the translations
  Future<void> load(String currentLocale,
      {String currentFlavor = defaultFlavorName}) async {
    Intl.defaultLocale = currentLocale;
    this._currentFlavor = currentFlavor;
    await initializeDateFormatting(Intl.defaultLocale);

    try {
      final data = await dataLoader(defaultLocale, defaultFlavor);
      _parseMetaData(data);
      if (currentFlavor != defaultFlavor && currentLocale != defaultLocale) {
        final data = await dataLoader(defaultLocale, currentFlavor);
        _loadLocale(defaultLocale, data, flavor: currentFlavor);
      }

      if (currentLocale != defaultLocale) {
        final data = await dataLoader(currentLocale, defaultFlavor);
        _loadLocale(currentLocale, data, flavor: defaultFlavor);
      }
      if (currentFlavor != defaultFlavor) {
        final data = await dataLoader(currentLocale, currentFlavor);
        _loadLocale(currentLocale, data, flavor: currentFlavor);
      }
    } catch (e, stack) {
      onError?.call(e, stack);
    }

    messageLookup.addLocale(
        defaultLocale,
        (locale) => CustomLookup(
              localeName: locale,
              flavorName: currentFlavor,
              defaultFlavorName: defaultFlavor,
              defaultLocaleName: defaultLocale,
            ));
    messageLookup.addLocale(
        currentLocale,
        (locale) => CustomLookup(
              localeName: locale,
              flavorName: currentFlavor,
              defaultFlavorName: defaultFlavor,
              defaultLocaleName: defaultLocale,
            ));
  }

  void _parseMetaData(String arbContent) {
    final enArbData = jsonDecode(arbContent);
    enArbData.forEach((String id, messageData) {
      if (id.startsWith('@@')) {
        return;
      }
      if (id.startsWith('@')) {
        if (messageData.containsKey('placeholders_order')) {
          metaData[id.substring(1).toLowerCase()] =
              messageData['placeholders_order']!.cast<String>();
        } else if (messageData.containsKey('placeholders')) {
          metaData[id.substring(1).toLowerCase()] =
              Map.from(messageData['placeholders']!)
                  .keys
                  .cast<String>()
                  .toList();
        } else {
          throw StateError(
              'No metadata in ARB for $id, metadata are used to know arguments order, it\'s mandatory');
        }
      }
    });
    _loadLocale(defaultLocale, arbContent);
  }

  /// Load the content of the ARB for the given [locale] and [flavor]
  /// You don't need to call this method yourself except if you need to load translations of locale
  /// that are not part of your [load] call
  void _loadLocale(String locale, String arbContent, {String? flavor}) {
    flavor ??= defaultFlavor;
    final arbData = jsonDecode(arbContent);

    Map<String, Message> messages = {};

    arbData.forEach((id, messageData) {
      TranslatedMessage? message =
          _recreateIntlObjects(id, messageData, arbData['@$id'] ?? {});
      if (message != null) {
        messages[message.id] = message.translated!;
      }
    });
    if (!_messages.containsKey(flavor)) {
      _messages[flavor] = {};
    }
    if (_messages[flavor]!.containsKey(locale)) {
      _messages[flavor]![locale]!.addAll(messages);
    } else {
      _messages[flavor]![locale] = messages;
    }
  }
}

/// Regenerate the original IntlMessage objects from the given [data]. For
/// things that are messages, we expect [id] not to start with "@" and
/// [data] to be a String. For metadata we expect [id] to start with "@"
/// and [data] to be a Map or null. For metadata we return null.
_BasicTranslatedMessage? _recreateIntlObjects(String id, data, Map metaData) {
  if (id.startsWith("@")) return null;
  if (data == null) return null;
  var parsed = _pluralAndGenderParser.parse(data).value;
  if (parsed is LiteralString && parsed.string.isEmpty) {
    parsed = _plainParser.parse(data).value;
  }
  return _BasicTranslatedMessage(id, parsed, metaData);
}

/// A TranslatedMessage that just uses the name as the id and knows how to look
/// up its original messages in our [messages].
class _BasicTranslatedMessage extends TranslatedMessage {
  Map metaData;

  _BasicTranslatedMessage(String name, translated, this.metaData)
      : super(name, translated);

  List<MainMessage> get originalMessages => (super.originalMessages.isEmpty)
      ? _findOriginals()
      : super.originalMessages;

  // We know that our [id] is the name of the message, which is used as the
  //key in [messages].
  List<MainMessage> _findOriginals() => originalMessages = [];
}

final _pluralAndGenderParser = IcuParser().message;
final _plainParser = IcuParser().nonIcuMessage;
