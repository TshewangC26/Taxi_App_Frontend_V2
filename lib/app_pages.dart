import 'package:get/get.dart';

import 'modules/pages/home.dart' show Home;
import 'routes.dart';

abstract class AppPages {
  static final pages = [
    GetPage(
      name:Routes.home,
      page:() => const Home()
    )
  ];
}