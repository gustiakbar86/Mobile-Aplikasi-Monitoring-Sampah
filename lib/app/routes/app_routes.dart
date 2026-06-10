part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const HOME = _Paths.HOME;
  static const ADMIN = _Paths.ADMIN;
  static const LOGIN = _Paths.LOGIN;
}

abstract class _Paths {
  _Paths._();
  static const HOME = '/home';
  static const ADMIN = '/admin';
  static const LOGIN = '/login';
}