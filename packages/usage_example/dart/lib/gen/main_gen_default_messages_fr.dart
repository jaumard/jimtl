// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a fr locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, always_declare_return_types

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = MessageLookup();

typedef String MessageIfAbsent(String? messageStr, List<Object>? args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'fr';

  @override
  String? lookupMessage(
      String? messageText, 
      String? locale, 
      String? name,
      List<Object>? args, 
      String? meaning,
      {MessageIfAbsent? ifAbsent}) {
    MessageIfAbsent failedLookup = (String? message_str, List<Object>? args) {
      // If there's no message_str, then we are an internal lookup, e.g. an
      // embedded plural, and shouldn't fail.
      if (message_str == null) return '';
      throw UnsupportedError("No translation found for message '$name',\n"
          "  original text '$message_str'");
    };
    return super.lookupMessage(messageText, locale, name, args, meaning, ifAbsent: ifAbsent ?? failedLookup);
  }

  static m0(name, name2) => "${name2} aime ${name}";

  static m1(gender, data) =>
      "${Intl.gender(gender, female: 'Test est féminin (${data})', male: 'Test est masculin (${data})', other: 'Test est inconnue (${data})')}";

  static m2(name, age) => "${name} a ${age} ans";

  static m3(name) => "Mon nom est ${name} et ${name} est gentil";

  static m4(name, number) =>
      "${Intl.plural(number, one: '${name} est seul', two: '${name} est 2', few: '${name} est peu', many: '${name} est beaucoup (${number})', other: '${name} est autre')}";

  static m5(age) => "Teste a ${age} ans";

  static m6(gender) => "${Intl.gender(gender, female: 'Teste est une femme', male: 'Teste est un homme', other: 'Teste est inconnue')}";

  static m7(number) =>
      "${Intl.plural(number, one: 'Teste est seul', two: 'Test est 2', few: 'Test est peu', many: 'Test est beaucoup', other: 'Test est autre')}";

  final messages = _notInlinedMessages(_notInlinedMessages);

  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "complex": m0,
        "genderComplex": m1,
        "nameAndAge": m2,
        "nameDouble": m3,
        "pluralComplex": m4,
        "test": MessageLookupByLibrary.simpleMessage("teste"),
        "testAndAge": m5,
        "testAndGender": m6,
        "testAndPlural": m7
      };
}
