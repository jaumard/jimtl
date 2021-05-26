class GenerateIntl {
  final String defaultLocale;
  final String defaultFlavor;
  final Set<String> locales;
  final Set<String> flavors;
  final bool generateFlutterDelegate;
  final String codegenMode;
  final bool useDeferredLoading;
  final bool arbSuppressMetaData;
  final bool arbIncludeSourceText;

  const GenerateIntl({
    this.useDeferredLoading = true,
    this.codegenMode = 'release',
    this.defaultLocale = 'en',
    this.defaultFlavor = 'default',
    this.locales = const {},
    this.flavors = const {},
    this.generateFlutterDelegate = true,
    this.arbSuppressMetaData = false,
    this.arbIncludeSourceText = false,
  });
}
