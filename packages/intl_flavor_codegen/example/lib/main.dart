import 'package:intl/intl.dart';
import 'package:intl_flavor/intl_flavor.dart';

main() {
  final translations = Translations();
  print(translations.test);
  print(translations.testAndAge(5));
  print(translations.testAndGender('gender'));
  print(translations.testAndPlural(5));
}

@GenerateArb()
@GenerateIntl(locales: const {'fr'})
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
