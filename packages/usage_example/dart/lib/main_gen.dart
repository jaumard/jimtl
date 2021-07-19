import 'package:intl/intl.dart';
import 'package:jimtl/jimtl.dart';
import 'package:jimtl_codegen_example/gen/main_gen_messages_all.dart';

/// This example show you how to generate dart code from ARB if you prefer
main() async {
  await initializeMessages(Intl.defaultLocale!, IntlDelegate.defaultFlavorName);
  final translations = Translations();
  print(translations.test);
  print(translations.complex('test', 'test2'));
  print(translations.nameDouble('test'));
  print(translations.testAndAge(5));
  print(translations.testAndGender('male'));
  print(translations.genderComplex('male', 'data'));
  print(translations.testAndPlural(1));
  print(translations.pluralComplex('test', 2));
}

@GenerateIntl(
  locales: const {'fr'},
  arbSuppressLastModified: true,
  arbDir: 'arb',
  genDir: 'gen',
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
