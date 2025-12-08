import 'package:flutter/material.dart';

class AppColors {
  static Color appColor = HexColor('#F8658C');
  static Color appColorDark = HexColor('#0A0A0A');
  static Color appColorDark2 = HexColor('#121212');
  static Color appColorLight = HexColor('#1A182A');
  static Color whiteColor = Colors.white;
  static Color blackColor = Colors.black;
  static Color appBarColor = HexColor('#F6F6F6');
  static Color promptColor = HexColor('#1B1D24');
  static Color appBlackColor = HexColor('#15171D');
  static Color textColorGrey = HexColor('#BFBFBF');
  static Color lightGrey = HexColor('#c6c6c6');
  static Color lightGreyBG = HexColor('#E9E9E9');
  static Color iconGrey = HexColor('#1c1c1c');
  static Color red = HexColor('#FF0000');
  static Color green = HexColor('#2A9D4A');
  static Color textColorDarkGrey = HexColor('#292B33');
  static Color textColorLightGrey = HexColor('##545454');
  static Color greyBG = HexColor('#1E1E1E');
  static Color appColorTheme = HexColor('#4744FF');
  static Color textColorWhite = HexColor('#FFFFFF');
  static Color addBgColor = HexColor('#F9F9FA');
  static Color addBtnColor = HexColor('#0D4A8B');
  static Color lightBlueLine = HexColor('#83C0EF');
  static Color stopBtnColor = HexColor('#E03C17');

  //#44B0D3, #5957DE, #C050D2, #EA9C4F
  static Color grad1 = HexColor('#F126A6');
  static Color grad2 = HexColor('#F8658C');
  static Color grad3 = HexColor('#FE9F76');
  // static Color grad4 = HexColor('#EA9C4F');
}

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}