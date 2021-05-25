import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:intl_flavor/intl_flavor.dart';
import 'package:intl_flavor_codegen/src/generate_localized.dart';
import 'package:intl_translation/extract_messages.dart';
import 'package:intl_translation/generate_localized.dart';
import 'package:path/path.dart' as path;
import 'package:source_gen/source_gen.dart';

class IntBuilder extends GeneratorForAnnotation<GenerateIntl> {
  final BuilderOptions _options;
  final _jsonDecoder = const JsonCodec();

  IntBuilder(this._options);

  @override
  FutureOr<String?> generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) async {
    // Retrieve the currently matched asset
    AssetId inputId = buildStep.inputId;

    final file = File(inputId.path);
    final targetDir = file.parent.path;
    final generateFlutterDelegate = annotation.read('generateFlutterDelegate').boolValue;
    final codegenMode = annotation.read('codegenMode').stringValue;
    final defaultLocale = annotation.read('defaultLocale').stringValue;
    final defaultFlavor = annotation.read('defaultFlavor').stringValue;

    final extraction = MessageExtraction();
    extraction.suppressMetaData = annotation.read('arbSuppressMetaData').boolValue;
    extraction.includeSourceText = annotation.read('arbIncludeSourceText').boolValue;

    final locales = Set<String>.from(annotation.read('locales').setValue.map((e) => e.toStringValue()))..add(defaultLocale);
    final flavors = Set<String>.from(annotation.read('flavors').setValue.map((e) => e.toStringValue()))..add(defaultFlavor);
    final name = path.basenameWithoutExtension(inputId.path);

    final generation = CustomMessageGeneration(
      element.displayName,
      inputId.uri,
      defaultFlavor,
      defaultLocale,
      flavors,
      locales,
      generateFlutterDelegate: generateFlutterDelegate,
    );

    extraction.suppressWarnings = true;
    final allMessages = extraction.parseFile(file, false);
    final copyAssetId = inputId.changeExtension('.arb');
    await buildStep.writeAsString(copyAssetId, _generateARB(allMessages, extraction, defaultLocale));

    messages = new Map();
    allMessages.forEach((key, value) => messages.putIfAbsent(key, () => []).add(value));
    generation.codegenMode = codegenMode;
    generation.useDeferredLoading = annotation.read('useDeferredLoading').boolValue;

    flavors.forEach((flavorItem) {
      final messagesByLocale = <String, List<Map>>{};

      locales.forEach((localeItem) {
        generation.allLocales.add(localeItem);
        var arbFile = File(path.join(file.parent.path, '${name}_${flavorItem}_$localeItem.arb'));
        if (flavorItem == defaultFlavor) {
          if (!arbFile.existsSync()) {
            arbFile = File(path.join(file.parent.path, '${name}_$localeItem.arb'));
          }
          if (localeItem == defaultLocale) {
            if (!arbFile.existsSync()) {
              arbFile = File(path.join(file.parent.path, '$name.arb'));
            }
          }
        }
        if (localeItem == defaultLocale) {
          if (!arbFile.existsSync()) {
            arbFile = File(path.join(file.parent.path, '${name}_${flavorItem}.arb'));
          }
        }

        if (!arbFile.existsSync()) {
          print('${arbFile.path} doesn\'t exist');
          exit(10);
        }
        final src = arbFile.readAsStringSync();
        final data = _jsonDecoder.decode(src);
        final localeData = data["@@locale"] ?? data["_locale"] ?? localeItem;
        messagesByLocale.putIfAbsent(localeData, () => []).add(data);
      });

      generation.generatedFilePrefix = '${name}_${flavorItem}_';
      messagesByLocale.forEach((key, value) {
        _generateLocaleFile(key, value, targetDir, generation);
      });
    });

    generation.generatedFilePrefix = '${name}_';
    final mainImportFile = new File(path.join(targetDir, '${generation.generatedFilePrefix}messages_all.dart'));
    mainImportFile.writeAsStringSync(generation.generateMainImportFile());
  }

  /// Generate ARB from localization dart Class
  String _generateARB(Map messages, MessageExtraction extraction, String locale) {
    final allMessages = {};
    allMessages["@@locale"] = locale;
    allMessages["@@last_modified"] = new DateTime.now().toIso8601String();

    messages.forEach(
          (k, v) => allMessages.addAll(
        toARB(v, includeSourceText: extraction.includeSourceText, supressMetadata: extraction.suppressMetaData),
      ),
    );

    final encoder = JsonEncoder.withIndent("  ");
    return encoder.convert(allMessages);
  }

  /// Create the file of generated code for a particular locale.
  ///
  /// We read the ARB
  /// data and create [BasicTranslatedMessage] instances from everything,
  /// excluding only the special _locale attribute that we use to indicate the
  /// locale. If that attribute is missing, we try to get the locale from the
  /// last section of the file name. Each ARB file produces a Map of message
  /// translations, and there can be multiple such maps in [localeData].
  void _generateLocaleFile(String locale, List<Map> localeData, String targetDir, MessageGeneration generation) {
    List<TranslatedMessage> translations = [];
    for (var jsonTranslations in localeData) {
      jsonTranslations.forEach((id, messageData) {
        TranslatedMessage? message = _recreateIntlObjects(id, messageData);
        if (message != null) {
          translations.add(message);
        }
      });
    }
    generation.generateIndividualMessageFile(locale, translations, targetDir);
  }

  /// Regenerate the original IntlMessage objects from the given [data]. For
  /// things that are messages, we expect [id] not to start with "@" and
  /// [data] to be a String. For metadata we expect [id] to start with "@"
  /// and [data] to be a Map or null. For metadata we return null.
  TranslatedMessage? _recreateIntlObjects(String id, data) {
    if (id.startsWith("@")) return null;
    if (data == null) return null;
    var parsed = pluralAndGenderParser.parse(data).value;
    if (parsed is LiteralString && parsed.string.isEmpty) {
      parsed = plainParser.parse(data).value;
    }
    MainMessage();
    return BasicTranslatedMessage(id, parsed);
  }

  @override
  Map<String, List<String>> get buildExtensions {
    return {
      '.arb': ['messages.*.dart'],
    };
  }
}

final pluralAndGenderParser = IcuParser().message;
final plainParser = IcuParser().nonIcuMessage;
Map<String, List<MainMessage>> messages = <String, List<MainMessage>>{};

/// A TranslatedMessage that just uses the name as the id and knows how to look
/// up its original messages in our [messages].
class BasicTranslatedMessage extends TranslatedMessage {
  BasicTranslatedMessage(String name, translated) : super(name, translated);

  @override
  List<MainMessage> get originalMessages => (super.originalMessages.isEmpty) ? _findOriginals() : super.originalMessages;

  // We know that our [id] is the name of the message, which is used as the
  //key in [messages].
  List<MainMessage> _findOriginals() => originalMessages = messages[id] ?? [];
}
