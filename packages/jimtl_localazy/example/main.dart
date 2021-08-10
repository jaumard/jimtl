import 'package:jimtl/jimtl.dart';
import 'package:jimtl_localazy/jimtl_localazy.dart';

main() async {
  final manager = LocalazyCdnManager(
    cdnId: 'CDI_ID_HERE',
    cacheFolder: '.',
    getFileName: (String locale, String flavor) {
      return 'error.arb';
    },
  );

  print(await manager.download('en', 'flavor1'));

  print(await manager.download('es_MX', IntlDelegate.defaultFlavorName));
}
