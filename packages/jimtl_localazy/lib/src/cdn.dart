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
      locales: data['locales']
          .map((data) => LocalazyLocale.fromJSON(data))
          .cast<LocalazyLocale>()
          .toList(growable: false),
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
    return LocalazyConfig(json['files']
        .entries
        .map((entry) => LocalazyFile.fromJSON(entry.key, entry.value))
        .toList(growable: false)
        .cast<LocalazyFile>());
  }
}

class LocalazyCdnManager extends RemoteTranslationsManager {
  /// CDN ID of your localazy project, you can find it by running localazy cdn and get it from the URI
  final String cdnId;

  /// Cache duration for localazy config file
  /// Default to one day
  final Duration configCacheDuration;

  /// Folder where to save cache and config files
  final String cacheFolder;

  /// Callback to get the name of the file based on the locale and flavor
  final String Function(String locale, String flavor) getFileName;

  /// Callback if you want to search the correct file manually
  final LocalazyLocale Function(LocalazyConfig config)? customFileSearch;
  static final String _host = 'https://delivery.localazy.com';
  static final _configUrl = (String id) => '$_host/${id}/_e0.v2.json';
  static final Map<String, int> _cacheConfig = {};

  /// Construct a localazy CDN manage for the localization files
  LocalazyCdnManager({
    required this.cacheFolder,
    required this.cdnId,
    required this.getFileName,
    this.customFileSearch,
    this.configCacheDuration = const Duration(days: 1),
  });

  String get _configFileName => '${cdnId}_config.json';

  String get _remoteConfigFileName => '${cdnId}_remote_config.json';

  Future<void> clearCache() async {
    final folder = Directory(cacheFolder);
    final exist = await folder.exists();
    if (exist) {
      final files = folder.listSync();
      for (var file in files) {
        await file.delete(recursive: true);
      }
    }
  }

  /// Download the correct file based on locale and flavor
  /// It will get the localazy CDN config file and then search the right file based on [getFileName]
  /// or [customFileSearch].
  /// Returns null if nothing have been found on localazy
  /// Returns ARB content from cache or from localazy CDN depending if file have changed since last download
  /// Can throw [StateError] if no file match the given name of [getFileName] and [locale]/[flavor]
  /// [overrideFileName] can be used if you need multiple localization delegate on your flutter app that use one localazy manager but for multiple filek
  @override
  Future<String?> download(String locale, String flavor,
      {String? overrideFileName}) async {
    if (_cacheConfig.isEmpty) {
      await _loadCacheConfig();
    }
    final remoteConfigFile =
        File(path.join(cacheFolder, _remoteConfigFileName));
    final now =
        DateTime.now().subtract(configCacheDuration).millisecondsSinceEpoch;
    String? content;
    if (now > (_cacheConfig[_remoteConfigFileName] ?? 0)) {
      final response = await http.get(Uri.parse(_configUrl(cdnId)));
      if (response.statusCode == 200) {
        content = utf8.decode(response.bodyBytes);
        await remoteConfigFile.writeAsString(content);
        _cacheConfig[_remoteConfigFileName] =
            DateTime.now().millisecondsSinceEpoch;
        await _saveCacheConfig();
      }
    } else {
      content = await remoteConfigFile.readAsString();
    }

    if (content == null) {
      return null;
    }
    // then parse the JSON.
    final fileToSearch = overrideFileName ?? getFileName(locale, flavor);
    //print('$fileToSearch for $locale and $flavor');
    final configData = LocalazyConfig.fromJSON(jsonDecode(content));
    LocalazyLocale? wantedLocale;
    if (customFileSearch == null) {
      final wantedFile = configData.files.firstWhereOrNull((element) {
        final nameOk = element.file.toLowerCase() == fileToSearch.toLowerCase();
        if (flavor.isEmpty || flavor == IntlDelegate.defaultFlavorName) {
          return nameOk;
        } else {
          final flavorOk = element.productFlavors.firstWhereOrNull(
                  (element) => element.contains(':${flavor}')) !=
              null;
          final libOk = element.library == flavor;
          final moduleOk = element.module == flavor;
          final buildOk = element.buildType == flavor;
          return nameOk && (flavorOk || libOk || moduleOk || buildOk);
        }
      });
      if (wantedFile == null) {
        throw StateError(
            '"$fileToSearch" is not found on Localazy for flavor "$flavor"');
      }
      wantedLocale = wantedFile.locales.firstWhereOrNull((element) {
        final fileLocale = element.region.isEmpty
            ? element.language
            : '${element.language}_${element.region}';
        return fileLocale.toLowerCase() == locale.toLowerCase();
      });
    } else {
      wantedLocale = customFileSearch!(configData);
    }
    if (wantedLocale == null) {
      throw StateError(
          '"$locale" is not found on Localazy for file $fileToSearch and flavor $flavor');
    } else {
      final timestamp = await _getTimestamp(wantedLocale, fileToSearch);

      if (timestamp < wantedLocale.timestamp || timestamp == 0) {
        final localeResponse =
            await http.get(Uri.parse('$_host${wantedLocale.uri}'));
        if (localeResponse.statusCode == 200) {
          final content = utf8.decode(localeResponse.bodyBytes);
          await _saveInCache(content, wantedLocale, fileToSearch);
          await _setTimestamp(
              wantedLocale.timestamp, wantedLocale, fileToSearch);
          return content;
        }
      } else {
        return _readFromCache(wantedLocale, fileToSearch);
      }
    }
  }

  Future<void> _saveInCache(
      String content, LocalazyLocale file, String name) async {
    final arbFile = File(path.join(
        cacheFolder, '${cdnId}_${file.language}${file.region}_${name}'));
    await arbFile.writeAsString(content);
  }

  Future<String> _readFromCache(LocalazyLocale file, String name) async {
    final arbFile = File(path.join(
        cacheFolder, '${cdnId}_${file.language}${file.region}_${name}'));
    return await arbFile.readAsString();
  }

  Future<int> _getTimestamp(LocalazyLocale file, String name) async {
    return _cacheConfig['${cdnId}_${name}_${file.language}${file.region}'] ?? 0;
  }

  Future<void> _setTimestamp(
      int timestamp, LocalazyLocale file, String name) async {
    _cacheConfig['${cdnId}_${name}_${file.language}${file.region}'] = timestamp;
    await _saveCacheConfig();
  }

  Future<void> _saveCacheConfig() async {
    final file = await File(path.join(cacheFolder, _configFileName))
        .create(recursive: true);
    await file.writeAsString(jsonEncode(_cacheConfig));
  }

  Future<void> _loadCacheConfig() async {
    final file = await File(path.join(cacheFolder, _configFileName))
        .create(recursive: true);
    final content = await file.readAsString();
    if (content.isNotEmpty) {
      _cacheConfig.addAll(jsonDecode(content).cast<String, int>());
    }
  }
}
