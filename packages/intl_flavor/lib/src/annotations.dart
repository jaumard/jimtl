class GenerateIntl {
  final String defaultLocale;
  final String defaultFlavor;
  final Set<String> locales;
  final Set<String> flavors;
  final bool generateFlutterDelegate;
  final String codegenMode;
  final bool useDeferredLoading;

  const GenerateIntl({
    this.useDeferredLoading = true,
    this.codegenMode = 'release',
    this.defaultLocale = 'en',
    this.defaultFlavor = 'default',
    this.locales = const {},
    this.flavors = const {},
    this.generateFlutterDelegate = true,
  });
}

class GenerateArb {
  final String locale;
  final bool suppressMetaData;
  final bool includeSourceText;

  const GenerateArb({
    this.locale = 'en',
    this.suppressMetaData = false,
    this.includeSourceText = false,
  });
}
