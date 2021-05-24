
import 'package:example/translations_messages_all.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:intl_flavor/intl_flavor.dart';

@GenerateArb()
@GenerateIntl(locales: const {'fr'}, flavors: {'flavor1'})
class Translations {

  static Translations of(BuildContext context) => Localizations.of<Translations>(context, Translations)!;

  static Future<Translations> load(Locale locale, String flavor) {
    print('load $locale for $flavor');
    final name = (locale.countryCode == null || locale.countryCode!.isEmpty) ? locale.languageCode : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName, flavor).then((_) async {
      Intl.defaultLocale = localeName;
      await initializeDateFormatting(Intl.defaultLocale);
      return Translations();
    });
  }

  String get counter => Intl.message('Counter', name: 'counter');

  String get increment => Intl.message('Increment', name: 'increment');

  String counterPushed(int number) => Intl.message('You have pushed the button $number times: ', args: [number], name: 'counterPushed');

}