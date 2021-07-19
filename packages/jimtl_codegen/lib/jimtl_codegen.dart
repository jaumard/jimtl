library jimtl_codegen;

import 'package:build/build.dart';
import 'package:jimtl_codegen/src/intl_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder intlBuilder(BuilderOptions options) => LibraryBuilder(
      IntBuilder(),
      generatedExtension: '.messages.all.dart',
    );

Builder arbBuilder(BuilderOptions options) => LibraryBuilder(
      ArbBuilder(),
      generatedExtension: '.arb',
    );
