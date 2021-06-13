import 'package:flutter/widgets.dart';
import 'package:flutter_jimtl/flutter_jimtl.dart';
import 'package:intl/intl.dart';

@GenerateArb(suppressLastModified: true, dir: 'assets/arb')
class TranslationsErrors {
  static TranslationsErrors of(BuildContext context) => Localizations.of<TranslationsErrors>(context, TranslationsErrors)!;

  String get error1 => Intl.message('Error 1', name: 'error1');

  String get error2 => Intl.message('Error 2', name: 'error2');
}
