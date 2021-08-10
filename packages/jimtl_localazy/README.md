# jimtl_localazy

This is an helper package for [flutter_jimtl](https://pub.dev/packages/flutter_jimtl). It will handle cache and OTA updates for your ARB files from [Localazy](https://localazy.com/register?ref=aAB0bhwi0G4y)

## Setup

Install last version of jimtl_localazy and flutter_jimtl (jimtl for Dart only)

```yaml
dependencies:
  jimtl_localazy:
  flutter_jimtl:
```

On Dart side you'll need to create an instance of `LocalazyCdnManager`:

```dart
final manager = LocalazyCdnManager(
                    cdnId: '_a860213072234234453319c546',
                    getFileName: (String locale, String flavor) {
                      return 'myFile_$flavor.arb';
                    },
                    cacheFolder: path.join((await getTemporaryDirectory()).path, 'translations'),
                    //configCacheDuration: Duration(days: 1),
                  );
```

To find your `cdnId` please run `localazy cdn` on your project, you'll get something like:

```
Metadata:
 - JSON: https://delivery.localazy.com/_a860213072234234453319c546/_e0.json
 - Javascript: https://delivery.localazy.com/_a860213072234234453319c546/_e0.js
 - Typescript: https://delivery.localazy.com/_a860213072234234453319c546/_e0.ts
```

So in this example the `cdnId` will be `_a860213072234234453319c546`.

## Usage

If you have an existing Flutter project with localization support, then you'll need to declare a `LocalizationDelegate` in your app.

Here is what it should look like:

```dart
localizationsDelegates: [
    DefaultMaterialLocalizations.delegate,
    TranslationsDelegate<Translations>.withRemoteManager(
      defaultLocale: 'en',
      supportedLocales: ['en', 'fr'],
      // if you are using flavors, you'll need to specify the default and current one
      defaultFlavor: 'default',
      currentFlavor: 'flavor1',
      localizationManager: manager, // here you can pass the previously created LocalazyCdnManager
      // This method is called to load the default ARB files, easiest way is to load them from assets
      dataLoader: (locale, flavor) async {
        print('local load $locale and $flavor');
        if (flavor == 'default') {
          return await rootBundle.loadString('assets/arb/translations_$locale.arb');
        }
        return await rootBundle.loadString('assets/arb/translations_${flavor}_$locale.arb');
      },
      // Once your translations are updated from your remote files this callback will be triggered, you'll need to rebuild in order to see the changes
      onTranslationsUpdated: () {
        print('TX updated, need rebuild');
        setState(() {});
      },
      // Builder to build your custom class containing your translations
      translationsBuilder: () => Translations(),
    ),
]
```

To have more detail on the `TranslationsDelegate` please check [flutter_jimtl](https://github.com/jaumard/jimtl/tree/master/packages/flutter_jimtl).


## Limitations

Currently localazy doesn't give you back the meta data of the ARB file, this mean that it will only load existing translations where metadata have been found during the first load  (with `dataLoader`).

## Examples

Take a look at the basic [example here](https://github.com/jaumard/jimtl/tree/master/packages/usage_example/multi_arb).

## Contribution

Contributions are welcome! Before doing it please create an issue describing the bug or the feature you want to work on.