class GenerateIntl {
  final String? baseFileName;
  final String defaultLocale;
  final String defaultFlavor;
  final Set<String> locales;
  final Set<String> flavors;
  final bool generateFlutterDelegate;
  final String codegenMode;
  final bool useDeferredLoading;
  final bool arbSuppressMetaData;
  final bool arbIncludeSourceText;
  final bool arbSuppressLastModified;
  final String arbDir;
  final String genDir;

  const GenerateIntl({
    this.arbDir = '.',
    this.genDir = '.',
    this.useDeferredLoading = true,
    this.baseFileName,
    this.codegenMode = 'release',
    this.defaultLocale = 'en',
    this.defaultFlavor = 'default',
    this.locales = const {},
    this.flavors = const {},
    this.generateFlutterDelegate = true,
    this.arbSuppressMetaData = false,
    this.arbSuppressLastModified = false,
    this.arbIncludeSourceText = false,
  });
}
