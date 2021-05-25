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


## Localization from ARB