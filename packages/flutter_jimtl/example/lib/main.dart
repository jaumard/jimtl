import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_jimtl/flutter_jimtl.dart';
import 'package:jimtl_codegen_example/translations.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    //print(TranslationsDelegate.supportedLocales);
    final locales = const [Locale('en'), Locale('fr')];
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      supportedLocales: locales,
      localizationsDelegates: [
        DefaultMaterialLocalizations.delegate,
        TranslationsDelegate<Translations>(
          defaultLocale: locales.first,
          currentFlavor: 'flavor1',
          onTranslationsUpdated: () {
            print('TX updated, need rebuild');
            setState(() {});
          },
          supportedLocales: locales,
          dataLoader: (locale, flavor) async {
            print('local load $locale and $flavor');
            if (flavor == IntlDelegate.defaultFlavorName) {
              return await rootBundle.loadString('assets/arb/translations_$locale.arb');
            }
            return await rootBundle.loadString('assets/arb/translations_${flavor}_$locale.arb');
          },
          updateDataLoader: (locale, flavor) async {
            print('Remote load $locale and $flavor');
            if (locale == 'en' && flavor == 'flavor1') {
              await Future.delayed(Duration(seconds: 10)); //simulate some slow network response
              return await rootBundle.loadString('assets/arb/translations_remote_$locale.arb');
            }
            return null; // no update
          },
          defaultFlavor: IntlDelegate.defaultFlavorName,
          translationsBuilder: () => Translations(),
        ),
      ],
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Translations getTranslations(BuildContext context) {
    return Translations(); //Translations.of(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getTranslations(context).counter),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              getTranslations(context).counterPushed(_counter),
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: getTranslations(context).increment,
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
