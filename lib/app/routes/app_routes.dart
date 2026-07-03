part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const LANDING = _Paths.LANDING;
  static const HOME = _Paths.HOME;
  static const ADMIN = _Paths.ADMIN;
  static const LOGIN = _Paths.LOGIN;
  static const WEBVIEW = _Paths.WEBVIEW;
}

abstract class _Paths {
  _Paths._();
  static const LANDING = '/landing';
  static const HOME = '/home';
  static const ADMIN = '/admin';
  static const LOGIN = '/login';
  static const WEBVIEW = '/webview';
}
