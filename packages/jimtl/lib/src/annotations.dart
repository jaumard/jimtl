import 'package:jimtl/jimtl.dart';

class GenerateArb {
  final String dir;
  final String? baseFileName;
  final bool includeSourceText;
  final bool suppressMetaData;
  final bool suppressLastModified;
  final String defaultLocale;
  final String defaultFlavor;

  const GenerateArb({
    required this.dir,
    this.suppressMetaData = false,
    this.suppressLastModified = false,
    this.includeSourceText = false,
    this.defaultLocale = 'en',
    this.baseFileName,
    this.defaultFlavor = IntlDelegate.defaultFlavorName,
  });
}

class GenerateIntl {
  final String? baseFileName;
  final String defaultLocale;
  final String defaultFlavor;
  final Set<String> locales;
  final Set<String> flavors;
  final String codegenMode;
  final bool useDeferredLoading;
  final bool arbSuppressMetaData;
  final bool arbIncludeSourceText;
  final bool arbSuppressLastModified;
  final bool generateFlutterDelegate;
  final String arbDir;
  final String genDir;

  const GenerateIntl({
    this.arbDir = '.',
    this.genDir = '.',
    this.useDeferredLoading = true,
    this.baseFileName,
    this.codegenMode = 'release',
    this.defaultLocale = 'en',
    this.defaultFlavor = IntlDelegate.defaultFlavorName,
    this.locales = const {},
    this.flavors = const {},
    this.generateFlutterDelegate = false,
    this.arbSuppressMetaData = false,
    this.arbSuppressLastModified = false,
    this.arbIncludeSourceText = false,
  });
}
