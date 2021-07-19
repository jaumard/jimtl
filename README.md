# jimtl

If you are tired of manually writing ARB files or the limited Flutter localization support you are in the right place.

With this package you'll be able to:

- Generate an ARB file from Dart code (done by build_runner)
- Update your translations remotely (from external server or translation service)
- Have flavors for your translations

## Setup

Install last version of jimtl for Dart or flutter_jimtl for Flutter and jimtl_codegen.

```yaml
dependencies:
  intl:
  flutter_jimtl:

dev_dependencies:
  build_runner: ^2.0.3
  jimtl_codegen:
```

## Your translation with the power of intl package

Intl is a great package to deal with translation, it allow you to write messages, plurals and genders in an easy and safe way.

Let's take some basic examples:
```dart
@GenerateArb()
class Translations {
  // accessor for flutter project only
  static Translations of(BuildContext context) => Localizations.of<Translations>(context, Translations)!;

  String get counter => Intl.message('Counter', name: 'counter');

  String get increment => Intl.message('Increment', name: 'increment');

  String counterPushed(int number) => Intl.message('You have pushed the button $number times: ', args: [number], name: 'counterPushed');
}
```

Did you notice the @GenerateArb() annotation? That where the magic come from. 🪄

Once you run your favourite build_runner command it will generate the ARB corresponding to this class.

This annotation can be customize with the following fields:

- defaultLocale: locale your working with, default to 'en'
- defaultFlavor: default flavor of your project, default to 'default'
- suppressMetaData: suppress meta data when generating the ARB file, default to false
- suppressLastModified: suppress last modified when generating the ARB file, default to false
- includeSourceText: whether to include source_text in messages, default to false
- dir: directory where the ARB should be generated

## Flutter project

If you have an existing Flutter project with localization support, then you'll need to declare a `LocalizationDelegate` in your app.

Here is what it should look like:

```dart
localizationsDelegates: [
    DefaultMaterialLocalizations.delegate,
    TranslationsDelegate<Translations>(
      defaultLocale: 'en',
      supportedLocales: ['en', 'fr'],
      // if you are using flavors, you'll need to specify the default and current one
      defaultFlavor: 'default',
      currentFlavor: 'flavor1',
      // This method is called to load the default ARB files, easiest way is to load them from assets
      dataLoader: (locale, flavor) async {
        print('local load $locale and $flavor');
        if (flavor == 'default') {
          return await rootBundle.loadString('assets/arb/translations_$locale.arb');
        }
        return await rootBundle.loadString('assets/arb/translations_${flavor}_$locale.arb');
      },
      // If you want to download your ARB files from a remote server
      // You need to specfiy a custom data loader like this
      updateDataLoader: (locale, flavor) async {
        print('Remote load $locale and $flavor');
        if (locale == 'en' && flavor == 'flavor1') {
            await Future.delayed(Duration(seconds: 10));//simulate some slow network response
            return await rootBundle.loadString('assets/arb/translations_remote_$locale.arb');
        }
        return null;  // no update
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

Here is a little more detail of the `TranslationsDelegate` parameters:

- `defaultLocale`: default locale to use for your app.
- `defaultFlavor`: optional default flavor to use for your app, default to 'default'.
- `currentFlavor`: optional current flavor to use for your app, default to 'default'.
- `overrideCurrentLocale`: optional locale to use for your app, it will override the system locale.
- `dataLoader`: callback to get the ARB files for a given locale and flavor, this is call by jimtl to let you provide the ARB files when needed.
- `updateDataLoader`: optional, to keep your translations up to date from a remote server, this is the callback you need. It should returned the ARB content for a given locale and flavor or null if no update is needed.
- `onTranslationsUpdated`: optional, once your translations have been updated remotely by `updateDataLoader` this callback is called for your to rebuild your widget and see the changes.
- `supportedLocales`: supported locales for your app.
- `translationsBuilder`: builder to provide your custom class containing your sentences.

### Flavors specificities

Flavor support is optional in this package, but it's here in case you ever need it :)

Flavor ARB files doesn't have to contain all the sentences of your app,
if a sentence is not present in the flavor ARB, the default sentence from the locale will be used.

Let say we have this:

default => helloWorld => Hello World
flavor1 => helloWorld => World Hello
flavor2 =>

If you call `myClass.helloWorld` with flavor1 you'll get World Hello
If you call `myClass.helloWorld` with flavor2 you'll get Hello World (the default one)

Same goes for locale, if a sentence is not present in the current locale, the default locale sentence is used.

## Dart only project

If you are using Dart without flutter, you can still use this package and get all the feature he bring!

First import the dependencies:
```yaml
dependencies:
  intl:
  jimtl:

dev_dependencies:
  build_runner: ^2.0.3
  jimtl_codegen:
```

Then you'll do the same custom class and generate the ARB in the same way. But Dart doesn't have and need LocalizationDelegate.
But don't worry here is how to setup your translations.

```dart
final delegate = IntlDelegate(
    // default locale to use
    defaultLocale: 'en',
    // default flavor to use
    defaultFlavor: 'flavor1',
    // callback to load ARB content for given locale and flavor
    dataLoader: (String locale, String flavor) async {
      if (flavor == 'default') {
        return await File('./lib/arb/main_$locale.arb').readAsString();
      }
      return await File('./lib/arb/main_${flavor}_$locale.arb').readAsString();
    },
);
// load the current locale and optional flavor
await delegate.load('fr', currentFlavor: 'flavor1');
```

Once `load` is finished you can use your custom class as you want.

`IntlDelegate` can be customized with the following parameters:

- `defaultLocale`: default locale to use for your app.
- `defaultFlavor`: optional default flavor to use for your app, default to 'default'.
- `currentFlavor`: optional current flavor to use for your app, default to 'default'.
- `dataLoader`: callback to get the ARB files for a given locale and flavor, this is call by jimtl to let you provide the ARB files when needed.
- `updateDataLoader`: optional, to keep your translations up to date from a remote server, this is the callback you need. It should returned the ARB content for a given locale and flavor or null if no update is needed.
- `supportedLocales`: supported locales for your app.

### Generate Dart code from ARB instead of using IntlDelegate

You might want to have the same as `intl_translation` provide, meaning having the ARB files generated as dart code.

This is possible with this package, but for that, instead of using the `@GenerateArb` annotation you'll have to use `GenerateIntl`

`GenerateIntl` will first generate the ARB file from the dart code, then it will generate for each locale and flavor some dart files.

Once everything is generated you can setup those generated translations like this:

```dart
Intl.defaultLocale = 'en';
await initializeMessages(Intl.defaultLocale!, 'flavor');
```

After that use your custom class as you wish.

You have the possibility to customize `GenerateIntl` annotation with the following fields:

- baseFileName: specify base file name for generated files, default to the name of the annotated class
- arbDir: dir to generate the ARB file, relative to the current file, default to '.'
- genDir: dir to generate the dart files, relative to the current file, default to '.'
- defaultLocale: locale your working with, default to 'en'
- defaultFlavor: default flavor of your project, default to 'default'
- locales: List of supported locales of your project
- flavors: List of flavors of your project
- codegenMode: mode to pass to underlaying intl_generator, default to 'release'
- useDeferredLoading: either to use deferred loading for localization files, default to true
- arbSuppressMetaData: suppress meta data when generating the ARB file, default to false
- arbSuppressLastModified: suppress last modified when generating the ARB file, default to false
- arbIncludeSourceText: whether to include source_text in messages, default to false

## Limitations

As this package is based on intl, it inherits some of his limitations, the main one is that intl's use a global internal map to find translations in the correct locale.

This means that if you have multiple ARB and custom dart classes you have to be careful that keys are unique across all your apps or one will be overridden by the other.

Another limitation is that Intl has no way to tell us which keys are corresponding to which arguments, to fix this we're using the meta data on the source (generally en) ARB file, so be sure meta data are there or you'll have a StateError.

## Examples

Take a look at the basic pure [Dart example](https://github.com/jaumard/intl_flavors/tree/master/packages/usage_example/dart) or our [Flutter example](https://github.com/jaumard/intl_flavors/tree/master/packages/usage_example/flutter).

## Contribution

Contributions are welcome! Before doing it please create an issue describing the bug or the feature you want to work on.