import 'dart:convert';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';
import 'package:intl/src/intl_helpers.dart';
import 'package:intl_generator/generate_localized.dart';

final Map<String, List<String>> metaData = {};
// Flavor => Locale => sentences {flavor: {en: {test: message}}}
final Map<String, Map<String, Map<String, Message>>> _messages = {};

String _getString(String locale, String id, Message message, List<Object> args) {
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
    final index = metaData[id]!.indexWhere((key) => key.toLowerCase() == message.variableName.toLowerCase());
    if (index == -1 && args.length > 1) {
      throw StateError('No meta data "placeholders_order" found for $id, be sure you generate your ARB with intl_generator or intl_flavors');
    }
    return index == -1 ? args.first.toString() : args[index].toString();
  } else if (message is Gender) {
    final index = metaData[id]!.indexWhere((key) => key.toLowerCase() == message.mainArgument!.toLowerCase());
    return Intl.genderLogic(
      args[index].toString(),
      locale: locale,
      other: _getString(locale, id, message.other!, args),
      male: _getString(locale, id, message.male ?? message.other!, args),
      female: _getString(locale, id, message.female ?? message.other!, args),
    );
  } else if (message is Plural) {
    final index = metaData[id]!.indexWhere((key) => key.toLowerCase() == message.mainArgument!.toLowerCase());
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
  String? lookupMessage(String? messageText, String? locale, String? name, List<Object>? args, String? meaning, {MessageIfAbsent? ifAbsent}) {
    // If passed null, use the default.
    final knownLocale = locale ?? localeName;

    final messages = _messages[flavorName]![knownLocale]!;
    final sentence = messages[name!];

    // sentence is not available in current locale, let's take the default one
    if (sentence == null) {
      final defaultMessages = _messages[defaultFlavorName]![knownLocale]!;
      final defaultSentence = defaultMessages[name];
      if (defaultSentence == null) {
        final defaultMessages = _messages[defaultFlavorName]![defaultLocaleName]!;
        final defaultSentence = defaultMessages[name];
        if (defaultSentence == null) {
          print('no message found for $name, default to $messageText');
          return messageText;
        }
        return _getString(knownLocale, name.toLowerCase(), defaultSentence, args ?? []);
      }
      return _getString(knownLocale, name.toLowerCase(), defaultSentence, args ?? []);
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
typedef IntlUpdateDataLoader = Future<String?> Function(String locale, String flavor);

class IntlDelegate {
  static const defaultFlavorName = 'default';
  final String defaultLocale;
  final String defaultFlavor;
  final IntlDataLoader dataLoader;
  final IntlUpdateDataLoader? updateDataLoader;

  //final List<String> supportedFlavors;
  String currentFlavor = defaultFlavorName;

  /*
  IntlDelegate.withRemoteManager({
    required this.dataLoader,
    required this.defaultLocale,
    required RemoteTranslationsManager localizationManager,
    this.defaultFlavor = defaultFlavorName,
    //this.supportedFlavors = const [],
  }): updateDataLoader = localizationManager.download {
    initializeInternalMessageLookup(() => CompositeMessageLookup());
  }*/

  IntlDelegate({
    required this.dataLoader,
    required this.defaultLocale,
    this.updateDataLoader,
    this.defaultFlavor = defaultFlavorName,
    //this.supportedFlavors = const [],
  }) {
    initializeInternalMessageLookup(() => CompositeMessageLookup());
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
        _parseMetaData(data);
        updated = true;
      }
      if (currentLocale != defaultLocale) {
        final data = await updateDataLoader!(currentLocale, defaultFlavor);
        if (data != null) {
          loadLocale(currentLocale, data);
          updated = true;
        }
      }
      if (currentFlavor != defaultFlavor) {
        final data = await updateDataLoader!(currentLocale, currentFlavor);
        if (data != null) {
          loadLocale(currentLocale, data, flavor: currentFlavor);
          updated = true;
        }
      }
    }
    return updated;
  }

  /// Init Intl with the [currentLocale] and [currentFlavor],
  /// it will call [dataLoader] to load the locale data needed to do the translations
  Future<void> load(String currentLocale, {String currentFlavor = defaultFlavorName}) async {
    Intl.defaultLocale = currentLocale;
    this.currentFlavor = currentFlavor;
    await initializeDateFormatting(Intl.defaultLocale);

    final data = await dataLoader(defaultLocale, defaultFlavor);
    _parseMetaData(data);
    if (currentLocale != defaultLocale) {
      final data = await dataLoader(currentLocale, defaultFlavor);
      loadLocale(currentLocale, data);
    }
    if (currentFlavor != defaultFlavor) {
      final data = await dataLoader(currentLocale, currentFlavor);
      loadLocale(currentLocale, data, flavor: currentFlavor);
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
          metaData[id.substring(1).toLowerCase()] = messageData['placeholders_order']!.cast<String>();
        } else if (messageData.containsKey('placeholders')) {
          metaData[id.substring(1).toLowerCase()] = Map.from(messageData['placeholders']!).keys.cast<String>().toList();
        } else {
          throw StateError('No metadata in ARB for $id, metadata are used to know arguments order, it\'s mandatory');
        }
      }
    });
    loadLocale(defaultLocale, arbContent);
  }

  /// Load the content of the ARB for the given [locale] and [flavor]
  /// You don't need to call this method yourself except if you need to load translations of locale
  /// that are not part of your [load] call
  void loadLocale(String locale, String arbContent, {String? flavor}) {
    flavor ??= defaultFlavor;
    final arbData = jsonDecode(arbContent);

    Map<String, Message> messages = {};

    arbData.forEach((id, messageData) {
      TranslatedMessage? message = recreateIntlObjects(id, messageData, arbData['@$id'] ?? {});
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
BasicTranslatedMessage? recreateIntlObjects(String id, data, Map metaData) {
  if (id.startsWith("@")) return null;
  if (data == null) return null;
  var parsed = pluralAndGenderParser.parse(data).value;
  if (parsed is LiteralString && parsed.string.isEmpty) {
    parsed = plainParser.parse(data).value;
  }
  return BasicTranslatedMessage(id, parsed, metaData);
}

/// A TranslatedMessage that just uses the name as the id and knows how to look
/// up its original messages in our [messages].
class BasicTranslatedMessage extends TranslatedMessage {
  Map metaData;

  BasicTranslatedMessage(String name, translated, this.metaData) : super(name, translated);

  List<MainMessage> get originalMessages => (super.originalMessages.isEmpty) ? _findOriginals() : super.originalMessages;

  // We know that our [id] is the name of the message, which is used as the
  //key in [messages].
  List<MainMessage> _findOriginals() => originalMessages = [];
}

final pluralAndGenderParser = IcuParser().message;
final plainParser = IcuParser().nonIcuMessage;
