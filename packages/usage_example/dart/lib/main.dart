import 'dart:io';

import 'package:intl/intl.dart';
import 'package:jimtl/jimtl.dart';

/// This example show you how to generate ARB file and use it on your dart code
main() async {
  final delegate = IntlDelegate(
    defaultLocale: 'en',
    dataLoader: (String locale, String flavor) async {
      if (flavor == IntlDelegate.defaultFlavorName) {
        return await File('./lib/arb/main_$locale.arb').readAsString();
      }
      return await File('./lib/arb/main_${flavor}_$locale.arb').readAsString();
    },
  );
  await delegate.load('fr');

  final translations = Translations();
  print(translations.test);
  print(translations.complex('test', 'test2'));
  print(translations.nameDouble('test'));
  print(translations.testAndAge(5));
  print(translations.testAndGender('male'));
  print(translations.genderComplex('male', 'data'));
  print(translations.testAndPlural(1));
  print(translations.pluralComplex('test', 2));
  print('');
  print(delegate.get('test'));
}

@GenerateArb(
  dir: 'lib/arb',
  suppressLastModified: true,
)
class Translations {
  String get test => Intl.message('test message', name: 'test');

  String testAndAge(int age) => Intl.message('Test have $age years old', args: [age], name: 'testAndAge');

  String complex(String name, String name2) => Intl.message('$name2 love $name', args: [name, name2], name: 'complex');

  String nameAndAge(String name, int age) => Intl.message('$name have $age years old', args: [name, age], name: 'nameAndAge');

  String nameDouble(String name) => Intl.message('My name is $name and $name is nice', args: [name], name: 'nameDouble');

  String testAndGender(String gender) =>
      Intl.gender(gender, name: 'testAndGender', args: [gender], male: 'Test is male', other: 'Test is unknown', female: 'Test is female');

  String genderComplex(String gender, String data) => Intl.gender(gender,
      name: 'genderComplex', args: [gender, data], male: 'Test is male ($data)', other: 'Test is unknown ($data)', female: 'Test is female ($data)');

  String testAndPlural(int number) => Intl.plural(
        number,
        args: [number],
        name: 'testAndPlural',
        one: 'Test is alone',
        two: 'Test is two',
        many: 'Test is a lot',
        few: 'Test is few',
        other: 'Test is other',
      );

  String pluralComplex(String name, int number) => Intl.plural(
        number,
        args: [name, number],
        name: 'pluralComplex',
        one: '$name is alone',
        two: '$name is two',
        many: '$name is a lot ($number)',
        few: '$name is few',
        other: '$name is other',
      );
}
