part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const HOME = _Paths.HOME;
  static const LOGIN = _Paths.LOGIN;
  static const REGISTER = _Paths.REGISTER;
  static const TRANSFERT = _Paths.TRANSFERT;
  static const ANNULER = _Paths.ANNULER;
  static const DEPOSIT = _Paths.DEPOSIT;
  static const PLANIFIER = _Paths.PLANIFIER;
}

abstract class _Paths {
  _Paths._();
  static const HOME = '/home';
  static const LOGIN = '/login';
  static const REGISTER = '/register';
  static const TRANSFERT = '/transfert';
  static const ANNULER = '/annuler';
  static const DEPOSIT = '/deposit';
  static const PLANIFIER = '/planifier';
}
