import 'package:flutter/widgets.dart';
import 'package:flutter_jimtl/flutter_jimtl.dart';
import 'package:intl/intl.dart';

@GenerateArb(suppressLastModified: true, dir: 'assets/arb')
class Translations {
  static Translations of(BuildContext context) => Localizations.of<Translations>(context, Translations)!;

  String get counter => Intl.message('Counter', name: 'counter');

  String get increment => Intl.message('Increment', name: 'increment');

  String counterPushed(int number) => Intl.message('You have pushed the button $number times: ', args: [number], name: 'counterPushed');
}
