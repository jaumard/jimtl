import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:jimtl/jimtl.dart';
import 'package:path/path.dart' as path;

class LocalazyLocale {
  final String language;
  final String region;
  final String name;
  final String localizedName;
  final String uri;
  final int timestamp;

  LocalazyLocale(
    this.language,
    this.region,
    this.name,
    this.localizedName,
    this.uri,
    this.timestamp,
  );

  factory LocalazyLocale.fromJSON(Map<String, dynamic> data) {
    return LocalazyLocale(
      data['language'],
      data['region'],
      data['name'],
      data['localizedName'],
      data['uri'],
      data['timestamp'] ?? 0,
    );
  }
}

class LocalazyFile {
  final String id;
  final String file;
  final String library;
  final String module;
  final String buildType;
  final int timestamp;
  final List<String> productFlavors;
  final List<LocalazyLocale> locales;

  LocalazyFile({
    required this.id,
    required this.file,
    required this.locales,
    required this.library,
    required this.module,
    required this.buildType,
    required this.productFlavors,
    required this.timestamp,
  });

  factory LocalazyFile.fromJSON(String id, Map<String, dynamic> data) {
    return LocalazyFile(
      id: id,
      file: data['file'],
      locales: data['locales'].map((data) => LocalazyLocale.fromJSON(data)).cast<LocalazyLocale>().toList(growable: false),
      buildType: data['buildType'],
      module: data['module'],
      library: data['library'],
      productFlavors: data['productFlavors'].cast<String>(),
      timestamp: data['timestamp'] ?? 0,
    );
  }
}

class LocalazyConfig {
  final List<LocalazyFile> files;

  LocalazyConfig(this.files);

  factory LocalazyConfig.fromJSON(Map<String, dynamic> json) {
    return LocalazyConfig(json.entries.map((entry) => LocalazyFile.fromJSON(entry.key, entry.value)).toList(growable: false));
  }
}

class LocalazyCdnManager extends RemoteTranslationsManager {
  final String cdnId;
  final String cacheFolder;
  final String Function(String locale, String flavor) getFileName;
  final LocalazyLocale Function(LocalazyConfig config)? customFileSearch;
  static final String _host = 'https://delivery.localazy.com';
  static final _configUrl = (String id) => '$_host/${id}/_e0.json';
  static final Map<String, int> _cacheConfig = {};

  LocalazyCdnManager({
    required this.cacheFolder,
    required this.cdnId,
    required this.getFileName,
    this.customFileSearch,
  });

  @override
  Future<String?> download(String locale, String flavor) async {
    final response = await http.get(Uri.parse(_configUrl(cdnId)));

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      final file = getFileName(locale, flavor);
      final configData = LocalazyConfig.fromJSON(jsonDecode(response.body));
      LocalazyLocale? wantedLocale;
      if (customFileSearch == null) {
        final wantedFile = configData.files.firstWhereOrNull((element) {
          final nameOk = element.file.toLowerCase() == file.toLowerCase();
          if (flavor.isEmpty || flavor == IntlDelegate.defaultFlavorName) {
            return nameOk;
          } else {
            final flavorOk = element.productFlavors.firstWhereOrNull((element) => element.contains(':${flavor}')) != null;
            final libOk = element.library == flavor;
            final moduleOk = element.module == flavor;
            final buildOk = element.buildType == flavor;
            return nameOk && (flavorOk || libOk || moduleOk || buildOk);
          }
        });
        if (wantedFile == null) {
          throw StateError('"$file" is not found on Localazy for flavor "$flavor"');
        }
        wantedLocale = wantedFile.locales.firstWhereOrNull((element) {
          final fileLocale = element.region.isEmpty ? element.language : '${element.language}_${element.region}';
          return fileLocale.toLowerCase() == locale.toLowerCase();
        });
      } else {
        wantedLocale = customFileSearch!(configData);
      }
      if (wantedLocale == null) {
        throw StateError('"$locale" is not found on Localazy for file $file and flavor $flavor');
      } else {
        final timestamp = await _getTimestamp(wantedLocale, file);

        if (timestamp < wantedLocale.timestamp || timestamp == 0) {
          final localeResponse = await http.get(Uri.parse('$_host${wantedLocale.uri}'));
          if (response.statusCode == 200) {
            await _saveInCache(localeResponse.body, wantedLocale, file);
            await _setTimestamp(wantedLocale.timestamp, wantedLocale, file);
            return utf8.decode(localeResponse.bodyBytes);
          }
        } else {
          return _readFromCache(wantedLocale, file);
        }
      }
    }
    return null;
  }

  Future<void> _saveInCache(String content, LocalazyLocale file, String name) async {
    final arbFile = await File(path.join(cacheFolder, '${cdnId}_${file.language}${file.region}_${name}'));
    await arbFile.writeAsString(content);
  }

  Future<String> _readFromCache(LocalazyLocale file, String name) async {
    final arbFile = await File(path.join(cacheFolder, '${cdnId}_${file.language}${file.region}_${name}'));
    return await arbFile.readAsString();
  }

  Future<int> _getTimestamp(LocalazyLocale file, String name) async {
    if (_cacheConfig.isEmpty) {
      _loadCacheConfig();
    }
    return _cacheConfig['${cdnId}_${name}_${file.language}${file.region}'] ?? 0;
  }

  Future<void> _setTimestamp(int timestamp, LocalazyLocale file, String name) async {
    _cacheConfig['${cdnId}_${name}_${file.language}${file.region}'] = timestamp;
    await _saveCacheConfig();
  }

  Future<void> _saveCacheConfig() async {
    final file = await File(path.join(cacheFolder, '${cdnId}_config.json')).create(recursive: true);
    await file.writeAsString(jsonEncode(_cacheConfig));
  }

  Future<void> _loadCacheConfig() async {
    final file = await File(path.join(cacheFolder, '${cdnId}_config.json')).create(recursive: true);
    final content = await file.readAsString();
    if (content.isNotEmpty) {
      _cacheConfig.addAll(jsonDecode(content).cast<String, int>());
    }
  }
}
