// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
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
  String get localeName => 'en';

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

  static m0(name, name2) => "${name2} love ${name}";

  static m1(gender, data) => "${Intl.gender(gender, female: 'Test is female (${data})', male: 'Test is male (${data})', other: 'Test is unknown (${data})')}";

  static m2(name, age) => "${name} have ${age} years old";

  static m3(name) => "My name is ${name} and ${name} is nice";

  static m4(name, number) =>
      "${Intl.plural(number, one: '${name} is alone', two: '${name} is two', few: '${name} is few', many: '${name} is a lot (${number})', other: '${name} is other')}";

  static m5(age) => "Test have ${age} years old";

  static m6(gender) => "${Intl.gender(gender, female: 'Test is female', male: 'Test is male', other: 'Test is unknown')}";

  static m7(number) => "${Intl.plural(number, one: 'Test is alone', two: 'Test is two', few: 'Test is few', many: 'Test is a lot', other: 'Test is other')}";

  final messages = _notInlinedMessages(_notInlinedMessages);

  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "complex": m0,
        "genderComplex": m1,
        "nameAndAge": m2,
        "nameDouble": m3,
        "pluralComplex": m4,
        "test": MessageLookupByLibrary.simpleMessage("test message"),
        "testAndAge": m5,
        "testAndGender": m6,
        "testAndPlural": m7
      };
}
