import 'package:jimtl_localazy/src/cdn.dart';

main() async {
  final manager = LocalazyCdnManager('_a860213072293210453319c546c5', 'errors.arb');

  print(await manager.download('en', 'flavor1'));

  //print(await manager.download('es_MX', IntlDelegate.defaultFlavorName));
}
