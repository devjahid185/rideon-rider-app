// ignore_for_file: deprecated_member_use

import 'package:ride_on/core/services/data_store.dart';
import 'package:flutter/material.dart';

Color themeColor = const Color(0xff1D56A5);
Color themeColor2 = const Color(0xff0F2F63);
Color whiteColor = const Color(0xffFFFFFF);
Color blackColor = const Color.fromARGB(255, 6, 6, 6);
Color ginColor = const Color(0xFFE4EFE5);
Color bgcolor = whiteColor;
Color darkblue = const Color(0xff3D5BF6);
Color yelloColor = const Color(0xffFFBB0D);
Color redColor = const Color(0xffFF4747);
Color lightgrey = const Color(0xffDDDDDD);
Color darkmode = const Color(0xff111315);
Color boxcolor = const Color(0xff202427);
Color greycolor2 = const Color(0xff9e9e9e);
Color greycolor22 = const Color(0xffA7AEC1);
Color perpulshadow = const Color(0xffede3ed);
Color buttonColor = const Color(0xff6F42E5);
Color blueColor = const Color(0xff2196f3);
Color greenColor = const Color(0xff0d7e0d);
Color gradientColor = const Color(0xff00D261);
Color brownColor = const Color(0xff481f01);
Color orangeColor = const Color(0xffff9933);
Color lightyellow = const Color(0xfff3e0bc);
Color redgradient = const Color(0xffFF6B6B);
Color yellowShadow = const Color(0xFFFFF1D3);
Color greentext = const Color(0xff20BC3B);
Color bordercolor = const Color(0xffF5F2FB);
Color blackColor2 = const Color.fromARGB(255, 49, 15, 15);
Color greyColor2 = const Color.fromARGB(255, 198, 202, 215);
Color greyColor22 = const Color(0xffA7AEC1);
Color darkblue2 = const Color(0xff3D5BF6);
Color yelloColor2 = const Color(0xffFFBB0D);
Color redColor2 = const Color(0xffFF4747);
Color lightgrey2 = const Color(0xffDDDDDD);
Color lightBlack = const Color(0x73000000);
Color lightBlack2 = const Color(0XFF636777);
Color onoffColor = const Color(0xffE7E7E7);
Color onoffColor2 = const Color(0xffE7E7E7);
Color fevAndSearchColor = const Color(0xFFf7f7f7);
Color lightblue = const Color(0xFFccdbfd);
Color greenColor2 = const Color(0xFF2a9d8f);
Color lightGrey = const Color(0xFFbbbbbb);
Color pinnetsColor = const Color.fromARGB(255, 248, 236, 217);
Color darkgrey = const Color(0xFFF6F4F4);
Color darkbox = const Color(0xff2ec4b6);
Color vehiclethemeColor = const Color(0xff78290f);
Color bookablethemeColor = greenColor2;
Color boatthemeColor = const Color(0xff48cae4);
Color spacethemeColor = const Color(0xfff7a072);
Color parkingthemeColor = const Color(0xff9d4edd);
Color doctorthemeColor = const Color(0xff3461ec);
Color lightBackColor = const Color(0xffe2eafc);
Color baseColor = Colors.grey.shade300;
Color highlight = Colors.grey.shade100;
Color grey2 = const Color(0xFF616161);
Color grey1 = const Color(0xFF212121);
Color grey3 = const Color(0xFF9E9E9E);
Color grey4 = const Color(0xFFBDBDBD);
Color grey6 = const Color(0xFFF7F7F7);
Color grey5 = const Color(0xFFEEEEEE);
Color bgBlue = const Color(0xFFF6FAFD);
Color fillColor = const Color(0xFF292B49);
Color boatThemColor = const Color(0xFF41ADE9);
Color parkingThemColor = const Color(0xFF8863D8);
Color bookableThemColor = const Color(0xFFEDB037);
Color spaceThemColor = const Color(0xFF005DB2);
Color bgRed = const Color(0xFFFFF5F5);
Color bgYellow = const Color(0xFFFFFEE0);
Color bgPurple = const Color(0xFFFCF4FF);
Color acentColor = const Color(0xff7ADC7f);
Color appyellow = const Color(0xFFFFD33C);
Color appgreen = const Color.fromARGB(255, 10, 78, 19);
Color pC1 = const Color(0xFFE94165);
Color greenback = const Color(0xFF85D487);
Color pC2 = const Color(0xFFE94165).withOpacity(.8);
Color sliderbg = const Color(0xFF636402);
Color sliderbg2 = const Color(0xFF3C3C3C);
Color lightYellow = const Color(0xFFFCE5BC);
Color lightBlue = const Color(0xFFCAE3F1);
Color circleBg = const Color(0xFFD9D0B2);
Color footerBorderColor = const Color(0xFFDAE1E7);
Color footergreycolor2 = const Color(0xFF7D879C);
// ignore: use_full_hex_values_for_flutter_colors
Color justmixedwhiteColor = const Color(0xff7f7f7f7);
Color greywhite = const Color(0xFF141414);
Color blackshade = const Color(0xFF1A1A1A);

class ColorNotifires with ChangeNotifier {
  bool isDark = box.get("getDarkValue") ?? false;

  set setIsDark(value) {
    isDark = value;
    notifyListeners();
  }

  get getIsDark => isDark;
  get getbgcolor => isDark ? darkmode : bgcolor;
  get getbgnextcolor => isDark
      ? const Color.fromARGB(255, 33, 26, 26)
      : const Color.fromARGB(255, 239, 237, 237);
  get getboxcolor => isDark ? boxcolor : whiteColor;
  get getlightblackColor => isDark ? boxcolor : lightBlack;
  get getInVisibleBoxColor => isDark ? grey2 : Colors.grey.shade200;
  get getwhiteblackColor => isDark ? whiteColor : blackColor;
  get getwhitegreycolor2 => isDark ? whiteColor : greycolor2;
  get getgreycolor2 => isDark ? greycolor2 : greycolor2;
  get getwhitebluecolor => isDark ? whiteColor : darkblue;
  get getblackgreycolor2 => isDark ? lightBlack2 : greycolor2;
  get getcardcolor => isDark ? darkmode : whiteColor;
  get getgreywhite => isDark ? whiteColor : greycolor2;
  get getredcolor => isDark ? redColor : redColor2;
  get getprocolor => isDark ? yelloColor : yelloColor2;
  get getblackwhiteColor => isDark ? blackColor : whiteColor;
  get getlightblack => isDark ? lightBlack2 : lightBlack2;
  get getbuttonscolor => isDark ? lightgrey : lightgrey2;
  get getbuttoncolor => isDark ? greycolor2 : onoffColor;
  get getdarkbluecolor => isDark ? darkblue : darkblue;
  get getdarkscolor => isDark ? blackColor : bgcolor;
  get getdarkwhiteColor => isDark ? whiteColor : whiteColor;
  get getblackblue => isDark ? blueColor : blackColor;
  get getfevAndSearch => isDark ? darkmode : fevAndSearchColor;
  get getlightblackwhite => isDark ? blackColor : fevAndSearchColor;
  get getswitchcolor => isDark ? blueColor : lightgrey;

  get getthemeColor => isDark ? themeColor2 : themeColor;
  get getCategoryBox => isDark ? ginColor : themeColor.withOpacity(.3);
  get getThemeWhiteColor => isDark ? whiteColor : themeColor;
  get getWhitePinnetsColor => isDark ? whiteColor : pinnetsColor;
  get getWhiteToDarkGeryColor => isDark ? darkmode : darkgrey;
  get getDoctorModuleColor => isDark ? darkmode : doctorthemeColor;
  get getBaseColor => isDark ? Colors.grey.shade700 : Colors.grey.shade300;
  get getHighlightColor => isDark ? Colors.grey.shade600 : Colors.grey.shade100;
  get getAppBarColor => isDark ? darkmode : lightBackColor.withOpacity(0.7);
  get getGrey1whiteColor => isDark ? whiteColor : grey1;
  get getGrey2whiteColor => isDark ? whiteColor : grey2;
  get getGrey3whiteColor => isDark ? whiteColor : grey3;
  get getGrey4whiteColor => isDark ? whiteColor : grey4;
  get getGrey5whiteColor => isDark ? whiteColor : grey5;
  get getGrey6whiteColor => isDark ? whiteColor : grey6;
  get getShadowColor => isDark ? grey2.withOpacity(.1) : grey4.withOpacity(.4);
  get getBoxColor => isDark ? grey2 : grey5;
  get getThemeColor => isDark ? themeColor : themeColor;
}

late ColorNotifires notifires;
