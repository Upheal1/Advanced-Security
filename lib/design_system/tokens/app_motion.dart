import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';

class AppMotion {
  AppMotion._();

  static const Duration instant = Duration(milliseconds: 120);
  static const Duration fast = Duration(milliseconds: 220);
  static const Duration medium = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 480);
  static const Duration deliberate = Duration(milliseconds: 700);
  static const Duration celebratory = Duration(milliseconds: 1000);
  static const Duration ambientCycle = Duration(seconds: 2);
  static const Duration messageVisible = Duration(seconds: 5);

  static const Curve emphasize = Curves.easeOutCubic;
  static const Curve standard = Curves.easeInOutCubic;
  static const Curve entrance = Curves.easeOutQuart;
  static const Curve exit = Curves.easeInCubic;
  static const Curve playful = Curves.elasticOut;
}
