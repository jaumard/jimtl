import 'package:intl/intl.dart';
import 'package:intl_flavors/intl_flavors.dart';
import 'package:intl_flavors_codegen_example/gen/main_messages_all.dart';

main() async {
  Intl.defaultLocale = 'en';
  await initializeMessages(Intl.defaultLocale!, 'default');
  final translations = Translations();
  print(translations.test);
  print(translations.testAndAge(5));
  print(translations.testAndGender('male'));
  print(translations.testAndPlural(5));
}

@GenerateIntl(
  locales: const {'fr'},
  generateFlutterDelegate: false,
  arbSuppressLastModified: true,
  arbDir: 'arb',
  genDir: 'gen',
)
class Translations {
  String get test => Intl.message('test', name: 'test');

  String testAndAge(int age) => Intl.message('Test have $age years old', args: [age], name: 'testAndAge');

  String testAndGender(String gender) => Intl.gender(gender, name: 'testAndGender', args: [gender], male: 'Test is male', other: 'Test is unknown', female: 'Test is female');

  String testAndPlural(int number) => Intl.plural(
        number,
        args: [number],
        name: 'testAndPlural',
        one: 'Test is alone',
        many: 'Test is a lot',
        few: 'Test is few',
        other: 'Test is other',
      );
}
