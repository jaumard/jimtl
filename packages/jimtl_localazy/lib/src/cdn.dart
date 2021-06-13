import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:jimtl/jimtl.dart';

class _LocalazyLocale {
  final String language;
  final String region;
  final String name;
  final String localizedName;
  final String uri;

  _LocalazyLocale(this.language, this.region, this.name, this.localizedName, this.uri);

  factory _LocalazyLocale.fromJSON(Map<String, dynamic> data) {
    return _LocalazyLocale(
      data['language'],
      data['region'],
      data['name'],
      data['localizedName'],
      data['uri'],
    );
  }
}

class _LocalazyFile {
  final String id;
  final String file;
  final String library;
  final String module;
  final String buildType;
  final List<String> productFlavors;
  final List<_LocalazyLocale> locales;

  _LocalazyFile({
    required this.id,
    required this.file,
    required this.locales,
    required this.library,
    required this.module,
    required this.buildType,
    required this.productFlavors,
  });

  factory _LocalazyFile.fromJSON(String id, Map<String, dynamic> data) {
    return _LocalazyFile(
      id: id,
      file: data['file'],
      locales: data['locales'].map((data) => _LocalazyLocale.fromJSON(data)).cast<_LocalazyLocale>().toList(growable: false),
      buildType: data['buildType'],
      module: data['module'],
      library: data['library'],
      productFlavors: data['productFlavors'],
    );
  }
}

class _LocalazyConfig {
  final List<_LocalazyFile> files;

  _LocalazyConfig(this.files);

  factory _LocalazyConfig.fromJSON(Map<String, dynamic> json) {
    return _LocalazyConfig(json.entries.map((entry) => _LocalazyFile.fromJSON(entry.key, entry.value)).toList(growable: false));
  }
}

class LocalazyCdnManager extends RemoteTranslationsManager {
  final String cdnId;
  final String file;
  final Function(dynamic error, dynamic stack)? onError;
  static final String _host = 'https://delivery.localazy.com';
  static final _configUrl = (String id) => '$_host/${id}/_e0.json';

  LocalazyCdnManager(this.cdnId, this.file, {this.onError});

  @override
  Future<String?> download(String locale, String flavor) async {
    try {
      final response = await http.get(Uri.parse(_configUrl(cdnId)));

      if (response.statusCode == 200) {
        // If the server did return a 200 OK response,
        // then parse the JSON.
        final configData = _LocalazyConfig.fromJSON(jsonDecode(response.body));
        final wantedFile = configData.files.firstWhereOrNull((element) => element.file.toLowerCase() == file.toLowerCase());
        if (wantedFile == null) {
          throw StateError('"$file" is not found on Localazy');
        }
        final wantedLocale = wantedFile.locales.firstWhereOrNull((element) {
          final fileLocale = element.region.isEmpty ? element.language : '${element.language}_${element.region}';
          return fileLocale.toLowerCase() == locale.toLowerCase();
        });
        if (wantedLocale == null) {
          throw StateError('"$locale" is not found on Localazy');
        } else {
          final localeResponse = await http.get(Uri.parse('$_host${wantedLocale.uri}'));
          if (response.statusCode == 200) {
            return localeResponse.body;
          }
        }
      }
    } catch (err, stack) {
      onError?.call(err, stack);
    }
    return null;
  }
}
