library intl_flavors_codegen;

import 'package:build/build.dart';
import 'package:intl_flavors_codegen/src/intl_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder intlBuilder(BuilderOptions options) => LibraryBuilder(
      IntBuilder(options),
      generatedExtension: '.lang.en.dart',
      additionalOutputExtensions: ['.arb'],
    );
