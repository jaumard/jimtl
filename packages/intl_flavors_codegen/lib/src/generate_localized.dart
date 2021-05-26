import 'package:intl/intl.dart';
import 'package:intl_generator/generate_localized.dart';

class CustomMessageGeneration extends MessageGeneration {
  final String className;
  final Uri classImport;
  final Set<String> flavors;
  final Set<String> locales;
  final String defaultFlavor;
  final String defaultLocale;
  final bool generateFlutterDelegate;

  CustomMessageGeneration(
    this.className,
    this.classImport,
    this.defaultFlavor,
    this.defaultLocale,
    this.flavors,
    this.locales, {
    this.generateFlutterDelegate = true,
  });

  @override
  String generateMainImportFile() {
    clearOutput();
    output.write(mainPrologue);
    if (generateFlutterDelegate) {
      output.write("import '$classImport';\n");
      output.write("import 'package:flutter/widgets.dart';\n");
      output.write("import 'package:intl/date_symbol_data_local.dart';\n");
      output.write("import 'package:intl/src/locale/locale_parser.dart';\n");
    }
    for (var locale in allLocales) {
      for (var flavor in flavors) {
        var baseFile = '${generatedFilePrefix}${flavor}_messages_$locale.dart';
        var file = importForGeneratedFile(baseFile);
        output.write("import '$file' ");
        if (useDeferredLoading) output.write("deferred ");
        output.write("as ${libraryName('${flavor}_$locale')};\n");
      }
    }
    output.write("\n");
    output.write("typedef Future<dynamic> LibraryLoader();\n\n");

    output.write("final _defaultFlavor = '$defaultFlavor';\n");
    output.write("final _defaultLocale = '$defaultLocale';\n");
    output.write("final _flavors = const [");
    for (var flavor in flavors) {
      output.write("'$flavor',");
    }
    output.write("];\n");
    output.write("final _locales = const [");
    for (var locale in locales) {
      output.write("'$locale',");
    }
    output.write("];\n\n");

    output.write("Map<String, LibraryLoader> _deferredLibraries = {\n");
    for (var rawLocale in allLocales) {
      var locale = Intl.canonicalizedLocale(rawLocale);
      for (var flavor in flavors) {
        var loadOperation = (useDeferredLoading)
            ? """  '${flavor}_$locale': () async {
          await ${libraryName('${defaultFlavor}_$locale')}.loadLibrary();\n
          ${flavor == defaultFlavor ? '' : 'await ${libraryName('${flavor}_$locale')}.loadLibrary();\n'}
         }, 
"""
            : "  '${flavor}_$locale': () => Future.value(null),\n";
        output.write(loadOperation);
      }
    }
    output.write("};\n");
    output.write("\nMessageLookupByLibrary? _findExact(String localeName, String flavor) {\n"
        "  switch ('\${flavor}_\$localeName') {\n");
    for (var rawLocale in allLocales) {
      for (var flavor in flavors) {
        var locale = Intl.canonicalizedLocale(rawLocale);
        output.write("    case '${flavor}_$locale':\n");
      }
    }
    output.write("    return MessageLookup(localeName, flavor);\n");
    output.write("""
    default:\n      return null;
  }
}\n\n""");

    output.write("""
Map _getFlavorMessages(String localeName, String flavor) {
    switch ('\${flavor}_\$localeName') {
""");
    for (var rawLocale in allLocales) {
      for (var flavor in flavors) {
        var locale = Intl.canonicalizedLocale(rawLocale);
        output.write("        case '${flavor}_$locale':\n");
        if (flavor == defaultFlavor) {
          output.write("            return ${libraryName('${flavor}_$locale')}.messages.messages;\n");
        } else {
          output.write(
              "            return ${libraryName('${defaultFlavor}_$locale')}.messages.messages..addAll(${libraryName('${flavor}_$locale')}.messages.messages);\n");
        }
      }
    }
    output.write("""
        default:\n          return {};
  }
}""");
    output.write(closing);

    if (generateFlutterDelegate) {
      output.write("""
class ${className}Delegate extends LocalizationsDelegate<$className> {

  static final List<Locale> supportedLocales = [""");

      for (var locale in allLocales) {
        output.write("_parseLocale('$locale'), ");
      }

      output.write("""];
  final String currentFlavor;
  final Locale? overridenLocale;
  
""");
      output.write("""
  TranslationsDelegate(this.currentFlavor, {this.overridenLocale});

  @override
  Future<$className> load(Locale locale) => _load(overridenLocale ?? locale, currentFlavor);

  @override
  bool shouldReload(TranslationsDelegate old) => old.currentFlavor != currentFlavor;
  
  static Future<$className> _load(Locale locale, String flavor) {
    var name = (locale.countryCode == null || locale.countryCode!.isEmpty) ? locale.languageCode : locale.toString();
    if (!_flavors.contains(flavor)) {
      flavor = _defaultFlavor;
    }
    if (!_locales.contains(name)) {
      name = _defaultLocale;
    }
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName, flavor).then((_) async {
      Intl.defaultLocale = localeName;
      await initializeDateFormatting(Intl.defaultLocale);
      return $className();
    });
  }
  
  @override
  bool isSupported(Locale locale) => supportedLocales.contains(locale);\n}""");
    }

    if (generateFlutterDelegate) {
      output.write("""
 
      
Locale _parseLocale(String locale) {
  final parser = LocaleParser(locale);
  final newLocale = parser.toLocale()!;
  return Locale.fromSubtags(languageCode: newLocale.languageCode, countryCode: newLocale.countryCode);
}
""");
    }

    return output.toString();
  }

  /// Constant string used in [generateMainImportFile] as the end of the file.
  @override
  get closing => """


/// User programs should call this before using [localeName] for messages.
Future<bool> initializeMessages(String localeName, String flavor) async {
  if (!_flavors.contains(flavor)) {
    flavor = _defaultFlavor;
  }
  if (!_locales.contains(localeName)) {
    localeName = _defaultLocale;
  }
  final availableLocale = Intl.verifiedLocale(
    localeName,
    (locale) => _deferredLibraries['\${flavor}_\$localeName'] != null,
    onFailure: (_) => null);
  if (availableLocale == null) {
    return Future.value(false);
  }
  final lib = _deferredLibraries['\${flavor}_\$availableLocale'];
  await (lib == null ? Future.value(false) : lib());
  initializeInternalMessageLookup(() => CompositeMessageLookup());
  messageLookup.addLocale(availableLocale, (locale) => _findGeneratedMessagesFor(locale, flavor));
  return Future.value(true);
}

bool _messagesExistFor(String locale, String flavor) {
  try {
    return _findExact(locale, flavor) != null;
  } catch (e) {
    return false;
  }
}

MessageLookupByLibrary? _findGeneratedMessagesFor(String locale, String flavor) {
  final actualLocale = Intl.verifiedLocale(locale, (locale) => _messagesExistFor(locale, flavor),
      onFailure: (_) => null);
  if (actualLocale == null) return null;
  return _findExact(locale, flavor);
}

class MessageLookup extends MessageLookupByLibrary {
  final String flavor;

  @override
  final String localeName;
  @override
  Map<String, Function> messages;

  MessageLookup(this.localeName, this.flavor)
      : messages = Map.from(_getFlavorMessages(localeName, flavor));
}

""";
}
