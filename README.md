# intl_flavors
Intl utilities to easily manage localization in Dart and Flutter

## Setup

Install last version of intl_flavor and intl_flavor_codegen.

```yaml
dependencies:
  intl:
  intl_flavor:

dev_dependencies:
  build_runner: ^2.0.3
  intl_flavor_codegen:
```

You then have two options, use Dart code to generate your ARB file, or manage your ARB file manually.

We recommand you to manage your localization from Dart code, but choose the method you want and follow his setup.

## Localization from Code

With that method we use full power of intl package, you create your localization class and use intl to define your translations.

For example:
```
@GenerateIntl(locales: const {'fr'})
class Translations {

  static Translations of(BuildContext context) => Localizations.of<Translations>(context, Translations)!;

  String get counter => Intl.message('Counter', name: 'counter');

  String get increment => Intl.message('Increment', name: 'increment');

  String counterPushed(int number) => Intl.message('You have pushed the button $number times: ', args: [number], name: 'counterPushed');
}
```

### Flavors

This package can help you deal with flavor, list the flavors on `GenerateIntl` annotation and provide an ARB file for each locales you support

Flavor ARB doesn't have to contain all the sentences, if a sentence is not present in the flavor ARB, the default sentence from the locale will be used.

### Configuration

You have the possibility to customize `GenerateIntl` annotation with the following fields:

- defaultLocale: locale your working with, default to 'en'
- defaultFlavor: default flavor of your project, default to 'default'
- locales: List of supported locales of your project
- flavors: List of flavors of your project
- generateFlutterDelegate: If your using pure dart project, you'll need to disable flutter related code, default to true
- codegenMode: mode to pass to underlaying intl_generator, default to 'release'
- useDeferredLoading: either to use deferred loading for localization files, default to true
- arbSuppressMetaData: suppress meta data when generating the ARB file, default to false
- arbIncludeSourceText: whether to include source_text in messages, default to false

## Localization from ARB

No dart on your side, everything is generated from your ARB files.

Comming soon it's on my todo list

## Examples:

Take a look at the basic pure [Dart example](https://github.com/jaumard/intl_flavors/tree/master/packages/usage_example/dart) or our [Flutter example](https://github.com/jaumard/intl_flavors/tree/master/packages/usage_example/flutter).