import 'package:flutter/widgets.dart';

class AppRadius {
  AppRadius._();

  static const double xsValue = 8;
  static const double smValue = 12;
  static const double mdValue = 16;
  static const double lgValue = 20;
  static const double xlValue = 24;
  static const double pillValue = 999;

  static const Radius xsUnit = Radius.circular(xsValue);
  static const Radius smUnit = Radius.circular(smValue);
  static const Radius mdUnit = Radius.circular(mdValue);
  static const Radius lgUnit = Radius.circular(lgValue);
  static const Radius xlUnit = Radius.circular(xlValue);
  static const Radius pillUnit = Radius.circular(pillValue);

  static const BorderRadius xs = BorderRadius.all(xsUnit);
  static const BorderRadius sm = BorderRadius.all(smUnit);
  static const BorderRadius md = BorderRadius.all(mdUnit);
  static const BorderRadius lg = BorderRadius.all(lgUnit);
  static const BorderRadius xl = BorderRadius.all(xlUnit);
  static const BorderRadius pill = BorderRadius.all(pillUnit);
}
