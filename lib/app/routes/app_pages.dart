import 'package:get/get.dart';
import 'package:getxcli/app/modules/planifier/bindings/planifier_binding.dart';
import 'package:getxcli/app/modules/planifier/views/planifier_view.dart';

import '../modules/annuler/bindings/annuler_binding.dart';
import '../modules/annuler/views/annuler_view.dart';

import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/register/bindings/register_binding.dart';
import '../modules/register/views/register_view.dart';
import '../modules/transfert/bindings/transfert_binding.dart';
import '../modules/transfert/views/transfert_view.dart';

import '../modules/login/views/login_page.dart'; // Corrigé pour utiliser la bonne vue

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.LOGIN;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => LoginPage(), // Utilisation correcte de LoginPage
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.REGISTER,
      page: () => RegisterView(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: _Paths.TRANSFERT,
      page: () => TransfertView(),
      binding: TransfertBinding(),
      children: [
        GetPage(
          name: _Paths.TRANSFERT,
          page: () => TransfertView(),
          binding: TransfertBinding(),
        ),
      ],
    ),
    GetPage(
      name: _Paths.ANNULER,
      page: () => AnnulerView(),
      binding: AnnulerBinding(),
    ),
  GetPage(
      name: _Paths.PLANIFIER,
      page: () => PlanifierView(),
      binding: PlanifierBinding(),
    ),
  ];
}
