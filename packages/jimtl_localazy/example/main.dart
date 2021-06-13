import 'package:jimtl/jimtl.dart';
import 'package:jimtl_localazy/src/cdn.dart';

main() async {
  final manager = LocalazyCdnManager('_a860213072293210453319c546c5', 'errors.arb');

  await manager.download('es_MX', IntlDelegate.defaultFlavorName);

  await manager.download('en', 'flavor1');
}
