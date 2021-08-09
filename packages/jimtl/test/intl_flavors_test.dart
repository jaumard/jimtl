import 'package:intl/intl.dart';
import 'package:jimtl/jimtl.dart';
import 'package:test/test.dart';

void main() {
  test('Load default locale', () async {
    Intl.defaultLocale = 'en';
    var callbackCalled = 0;
    final delegate = IntlDelegate(
        cacheLocale: false,
        dataLoader: (locale, flavor) async {
          callbackCalled++;
          expect(locale, 'en');
          expect(IntlDelegate.defaultFlavorName, flavor);
          return '''{
  "@@locale": "en",
  "counter": "Counter loaded",
  "@counter": {
    "type": "text",
    "placeholders_order": [],
    "placeholders": {}
  }
}
''';
        },
        defaultLocale: 'en');

    await delegate.load('en');
    expect(callbackCalled, 1);
    final message = Intl.message('Test', name: 'counter');
    expect(message, 'Counter loaded');
  });

  test('Load other locale', () async {
    Intl.defaultLocale = 'fr';
    var callbackCalled = 0;
    final delegate = IntlDelegate(
        cacheLocale: false,
        dataLoader: (locale, flavor) async {
          callbackCalled++;
          if (callbackCalled == 1) {
            expect(locale, 'en');
            expect(IntlDelegate.defaultFlavorName, flavor);
            return '''{
  "@@locale": "$locale",
  "counter": "Counter loaded $locale",
  "@counter": {
    "type": "text",
    "placeholders_order": [],
    "placeholders": {}
  },
  "counterUnknown": "Counter unknown loaded $locale",
  "@counterUnknown": {
    "type": "text",
    "placeholders_order": [],
    "placeholders": {}
  }
}
''';
          } else {
            expect(locale, 'fr');
            expect(IntlDelegate.defaultFlavorName, flavor);
            return '''{
  "@@locale": "$locale",
  "counter": "Counter loaded $locale",
  "@counter": {
    "type": "text",
    "placeholders_order": [],
    "placeholders": {}
  }
}
''';
          }
        },
        defaultLocale: 'en');

    await delegate.load('fr');
    expect(callbackCalled, 2);
    final message = Intl.message('Test', name: 'counter');
    expect(message, 'Counter loaded fr');

    final messageUnknown = Intl.message('Test', name: 'counterUnknown');
    expect(messageUnknown, 'Counter unknown loaded en');
  });

  test('Load default locale for custom flavor', () async {
    Intl.defaultLocale = 'en';
    var callbackCalled = 0;
    final delegate = IntlDelegate(
        cacheLocale: false,
        dataLoader: (locale, flavor) async {
          callbackCalled++;
          if (callbackCalled == 1) {
            expect(locale, 'en');
            expect(IntlDelegate.defaultFlavorName, flavor);
            return '''{
  "@@locale": "$locale",
  "counter": "Counter loaded $locale",
  "@counter": {
    "type": "text",
    "placeholders_order": [],
    "placeholders": {}
  },
  "counterUnknown": "Counter unknown loaded $locale",
  "@counterUnknown": {
    "type": "text",
    "placeholders_order": [],
    "placeholders": {}
  }
}
''';
          } else {
            expect(locale, 'en');
            expect('newFlavor', flavor);
            return '''{
  "@@locale": "$locale",
  "counter": "Counter loaded flavored $locale",
  "@counter": {
    "type": "text",
    "placeholders_order": [],
    "placeholders": {}
  }
}
''';
          }
        },
        defaultLocale: 'en');

    await delegate.load('en', currentFlavor: 'newFlavor');
    expect(callbackCalled, 2);
    final message = Intl.message('Test', name: 'counter');
    expect(message, 'Counter loaded flavored en');

    final messageUnknown = Intl.message('Test', name: 'counterUnknown');
    expect(messageUnknown, 'Counter unknown loaded en');
  });

  test('Load other locale for custom flavor', () async {
    Intl.defaultLocale = 'fr';
    var callbackCalled = 0;
    final delegate = IntlDelegate(
        cacheLocale: false,
        dataLoader: (locale, flavor) async {
          callbackCalled++;
          if (callbackCalled == 1) {
            expect(locale, 'en');
            expect(IntlDelegate.defaultFlavorName, flavor);
          } else if (callbackCalled == 2) {
            expect(locale, 'en');
            expect('newFlavor', flavor);
          } else if (callbackCalled == 3) {
            expect(locale, 'fr');
            expect(IntlDelegate.defaultFlavorName, flavor);
          } else {
            expect(locale, 'fr');
            expect('newFlavor', flavor);
          }
          return '''{
  "@@locale": "$locale",
  "counter": "Counter loaded",
  "@counter": {
    "type": "text",
    "placeholders_order": [],
    "placeholders": {}
  }
}
''';
        },
        defaultLocale: 'en');

    await delegate.load('fr', currentFlavor: 'newFlavor');
    expect(callbackCalled, 4);
  });
}
