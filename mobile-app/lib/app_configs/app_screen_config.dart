import 'package:flutter/material.dart'show BoxConstraints,Orientation;

class SizeConfig {
  static double width = 0;
  static double height = 0;
  static bool isMobile = false;
  static bool isPortrait = false;
  static bool isLandscape = false;

  void get(BoxConstraints constraints, Orientation orientation) {
    if (orientation == Orientation.portrait) {
      width = constraints.maxWidth;
      height = constraints.maxHeight;
      if (width < 450) {
        isMobile = true;
        isLandscape = false;
        isPortrait = false;
      } else {
        isMobile = false;
        isPortrait = true;
        isLandscape = false;
      }
    } else {
      width = constraints.maxHeight;
      height = constraints.maxWidth;
      isPortrait = false;
      isLandscape = true;
      isMobile = false;
    }
  }
}
