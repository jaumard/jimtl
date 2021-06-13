// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that looks up messages for specific locales by
// delegating to the appropriate library.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:implementation_imports, file_names
// ignore_for_file:unnecessary_brace_in_string_interps, directives_ordering
// ignore_for_file:argument_type_not_assignable, invalid_assignment
// ignore_for_file:prefer_single_quotes, prefer_generic_function_type_aliases
// ignore_for_file:comment_references
// ignore_for_file:avoid_catches_without_on_clauses

import 'dart:async';

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';
import 'package:intl/src/intl_helpers.dart';

import 'main_gen_default_messages_en.dart' deferred as messages_default_en;
import 'main_gen_default_messages_fr.dart' deferred as messages_default_fr;

typedef Future<dynamic> LibraryLoader();

final _defaultFlavor = 'default';
final _defaultLocale = 'en';
final _flavors = const [
  'default',
];
final _locales = const [
  'fr',
  'en',
];

Map<String, LibraryLoader> _deferredLibraries = {
  'default_fr': () async {
    await messages_default_fr.loadLibrary();

          
         }, 
  'default_en': () async {
          await messages_default_en.loadLibrary();

          
         }, 
};

MessageLookupByLibrary? _findExact(String localeName, String flavor) {
  switch ('${flavor}_$localeName') {
    case 'default_fr':
    case 'default_en':
    return MessageLookup(localeName, flavor);
    default:
      return null;
  }
}

Map _getFlavorMessages(String localeName, String flavor) {
    switch ('${flavor}_$localeName') {
        case 'default_fr':
            return messages_default_fr.messages.messages;
        case 'default_en':
            return messages_default_en.messages.messages;
        default:
          return {};
  }
}

/// User programs should call this before using [localeName] for messages.
Future<bool> initializeMessages(String localeName, String flavor) async {
  if (!_flavors.contains(flavor)) {
    flavor = _defaultFlavor;
  }
  if (!_locales.contains(localeName)) {
    localeName = _defaultLocale;
  }
  final availableLocale = Intl.verifiedLocale(
    localeName,
    (locale) => _deferredLibraries['${flavor}_$localeName'] != null,
    onFailure: (_) => null);
  if (availableLocale == null) {
    return Future.value(false);
  }
  final lib = _deferredLibraries['${flavor}_$availableLocale'];
  await (lib == null ? Future.value(false) : lib());
  initializeInternalMessageLookup(() => CompositeMessageLookup());
  messageLookup.addLocale(availableLocale, (locale) => _findGeneratedMessagesFor(locale, flavor));
  return Future.value(true);
}

bool _messagesExistFor(String locale, String flavor) {
  try {
    return _findExact(locale, flavor) != null;
  } catch (e) {
    return false;
  }
}

MessageLookupByLibrary? _findGeneratedMessagesFor(String locale, String flavor) {
  final actualLocale = Intl.verifiedLocale(locale, (locale) => _messagesExistFor(locale, flavor),
      onFailure: (_) => null);
  if (actualLocale == null) return null;
  return _findExact(locale, flavor);
}

class MessageLookup extends MessageLookupByLibrary {
  final String flavor;

  @override
  final String localeName;
  @override
  Map<String, Function> messages;

  MessageLookup(this.localeName, this.flavor)
      : messages = Map.from(_getFlavorMessages(localeName, flavor));
}

